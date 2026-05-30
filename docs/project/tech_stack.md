# Technology Stack

This document is the single reference for every technology used in CypherOS — _what it is, why it was chosen, what it gives us, and where applicable, what was rejected and why_. It is deliberately comprehensive. Understanding the _why_ behind each choice is what makes the system maintainable over time.

---

## Filesystem — BTRFS

**Role:** The structural skeleton of the entire system. Everything else mounts from it.

BTRFS (_B-Tree Filesystem_) is a Linux filesystem with first-class support for subvolumes, snapshots, transparent compression, and checksumming on a single pool of space. It is the enabling technology for CypherOS's multi-OS architecture.

**Why BTRFS, specifically:**
- The key property is that subvolumes are not partitions.
- They share a single pool of space on the BTRFS filesystem and grow and shrink freely against that shared pool.
- No pre-allocated sizes, no repartitioning. Adding a new OS to the fleet is `btrfs subvolume create @new-os-root`, not a trip into `gdisk`.

- This is what makes the architecture extensible by design rather than by workaround.

**What BTRFS gives CypherOS:**

- **Subvolumes as the OS skeleton** — each OS gets its own root subvolume; shared data (_home, nix store, identity_) lives in dedicated subvolumes mounted by every OS
- **No pre-defined sizes** — subvolumes share the pool; there is no _"I need to resize my partition"_ problem
- **Snapshots** — `@snapshots` subvolume as the target for `btrbk` or `snapper`; rollback is a first-class operation
- **CoW semantics where wanted, disabled where not** — `chattr +C` on `@nix-store` (_hardlinks + CoW interact poorly_) and `@swap` (_kernel hard requirement for swapfiles_)
- **Adding an OS = creating a subvolume** — no repartitioning, no resizing, no disruption to existing OSs

**BTRFS and swapfiles:**

- BTRFS can run Linux swap with one critical requirement: the swapfile must live on a subvolume with Copy-on-Write disabled (`chattr +C`).
- This is a kernel-level hard requirement — _without it, the kernel refuses to activate the swap_.
- The `@swap` subvolume in CypherOS has `chattr +C` applied during the initial disk setup script before any swapfile is created there.

**BTRFS and the Nix store:**

- Nix uses hardlinks extensively within the store. BTRFS CoW and Nix hardlinks interact poorly — CoW can break hardlinks under certain conditions and cause unexpected space amplification.
- The fix is `chattr +C` on `@nix-store` before the first Nix write.
- This is a one-time setup step that must happen before Phase 4 of the implementation sequence.

---

## Partition Strategy — Shared ESP + systemd-boot

**Role:** Boot management across multiple OSs on one machine.

The partition table is two partitions:

- `p1` — FAT32 EFI System Partition (512MB–1GB), shared by all OSs
- `p2` — BTRFS, everything else

**Why a shared ESP with systemd-boot:**

Each OS gets its own subdirectory within the shared ESP (e.g. `/EFI/nixos/`, `/EFI/arch/`). `systemd-boot` manages the boot menu entries. This is the cleanest multi-OS boot story — _no fighting over MBR, no GRUB chainloading complexity, and every major Linux distribution supports `systemd-boot` well_.

> **NOTE: GRUB is the alternative and is the current interim boot manager on the machine. It will be replaced by `systemd-boot` when the multi-OS setup goes live (Phase 1+), because managing GRUB entries across multiple independently-installed OSs is significantly messier than `systemd-boot` with per-OS entries in a shared ESP.**

---

## Identity — `libnss-extrausers`

**Role:** Shared user identity across all Linux OSs on the machine.

`libnss-extrausers` is a Name Service Switch (NSS) plugin that reads user, group, and shadow records from `/var/lib/extrausers/` (_or a configurable path_). It plugs into the standard Linux authentication stack the same way `/etc/passwd` does — _applications that call `getpwnam()` or `getpwuid()` consult it transparently_.

**Why `libnss-extrausers`:**

The fundamental problem is that each Linux OS has its own `/etc/passwd`, `/etc/shadow`, and `/etc/group`. To share a user identity across OSs, you need a mechanism that decouples the canonical user record from per-OS configuration files.

`libnss-extrausers` solves this cleanly: the canonical records live on the `@identity` BTRFS subvolume, which is bind-mounted read-only into every Linux OS at boot at the path `libnss-extrausers` reads from. Each OS's `nsswitch.conf` is configured to consult `extrausers` after `files`. The user is visible on every OS without any per-OS manual entry.

**The load-bearing piece — UID consistency:**

File ownership on shared BTRFS subvolumes resolves by UID number, not by username string. If `@arch-root` knows `cypher-whisperer` as UID 1000 but `@debian-root` knows a different user as UID 1000, files created on Arch appear owned by the wrong entity on Debian. Every OS must agree: `cypher-whisperer = UID 1000, GID 1000`.

**NixOS — no `libnss-extrausers` needed:**

NixOS declares users explicitly in `configuration.nix` with `users.users.cypher-whisperer.uid = 1000`. The declarative model achieves the same UID consistency without the NSS plugin. NixOS is its own identity source.

**FreeBSD — manual `vipw`:**

FreeBSD cannot use `libnss-extrausers` (Linux NSS is Linux-specific). The `@freebsd-root` gets a manual `/etc/master.passwd` entry for `cypher-whisperer` at UID 1000 via `vipw`. This is a one-time step per FreeBSD install. Password hash format compatibility is a Phase 10 concern (_see Open Questions, OQ3_).

**LFS:**

Manual `/etc/passwd` entry. No tooling dependency whatsoever.

---

### `systemd-homed` — Explicitly Rejected

`systemd-homed` is the "right enterprise answer" for user identity management in that it provides encrypted home directories, portable user records, and integrated authentication. It is explicitly **not** part of CypherOS.

The reason is architectural: `systemd-homed` manages user identity per-OS locally. User records live in `/var/lib/systemd/home/` on each OS independently. When you boot into a second OS that doesn't have the record, the user is in an `unfixated` state — _the home directory blob exists but the OS cannot authenticate against it_. It is not a shared identity store and was never designed to be one.

`libnss-extrausers` + explicit UID anchoring is the correct primitive for what CypherOS is building.

---

### LDAP / Local Directory Service — Rejected (Overkill)

An LDAP server (_OpenLDAP, FreeIPA_) is conceptually the right answer — _a shared identity store that every OS resolves users against via `nss-pam-ldapd` or `sssd`. In an enterprise multi-machine environment, it's the standard solution._

The problem in a single-machine multi-boot context: the LDAP server must be running for authentication to work. In a multi-boot setup, only one OS is ever live at a time. You'd need a permanently-on machine just to run the LDAP server — _which defeats the point_. `libnss-extrausers` with files on a shared subvolume achieves the same result without the infrastructure overhead.

---

## Swap — ZRAM + Disk Swapfile (Hierarchy)

**Role:** Memory pressure relief without OOM kills.

CypherOS uses a two-tier swap hierarchy:
```
RAM (free)
  ↓ pressure
ZRAM /dev/zram0 — compressed RAM, fast, high priority
  ↓ ZRAM full
/swap/swapfile  — disk-backed, slow, last resort
```

### ZRAM

ZRAM creates a compressed RAM-backed block device that the kernel uses as a high-priority swap device. Under memory pressure, pages are compressed and kept in RAM rather than written to the slow disk swapfile. Reads and writes happen at RAM speed, with a small CPU decompression cost.

**What ZRAM gives:**

- Effectively extends RAM. On an 8GB machine with `zstd` at 50% RAM allocation, 4GB of uncompressed data compresses to ~1.5–2GB of actual RAM used — _giving effectively 8–12GB of swap headroom before the disk swapfile is touched._
- Zero disk writes for normal memory pressure — _no wear on the SSD._
- Kernel manages priority automatically — _ZRAM gets a higher swap priority than the swapfile, so it fills first._
- Per-OS — _each OS configures its own ZRAM independently._ RAM is not a shared resource across boots.

**NixOS configuration:**
```nix
zramSwap = {
  enable        = true;
  memoryPercent = 50;      # 50% of total RAM before compression
  algorithm     = "zstd";  # better ratio than lz4, acceptable CPU overhead
};
```

`memoryPercent` controls how much of total RAM ZRAM may use _before_ compression. With `zstd` typically achieving 2:1 to 3:1 compression ratios, `50%` of 8GB = 4GB input → ~1.5–2GB actual RAM used → effectively 8–12GB of swap headroom.

### ZSWAP — Not Used (Why)

ZSWAP is a kernel-level write-back cache that sits _in front of_ the swap partition or file — _it compresses pages in RAM before they get written to disk._ It is not the same as ZRAM.

- **ZRAM** — compressed RAM _is_ the swap device. No disk writes for anything that fits in ZRAM.
- **ZSWAP** — compressed RAM cache _in front of_ a disk swap device. Disk writes still happen, just deferred and batched.

For CypherOS, ZRAM is the better choice. The goal is to avoid disk writes under memory pressure entirely, not just defer them. ZRAM achieves this. ZSWAP and ZRAM can technically coexist (_ZSWAP in front of the disk swapfile, ZRAM as a separate high-priority device_), but the added complexity is not justified for this workload.

### Disk Swapfile (`@swap`)

The `@swap` BTRFS subvolume is mounted at `/swap`. A 10GB swapfile lives there, created with `fallocate -l 10G` + `mkswap` during the initial disk setup.

The subvolume has CoW disabled (`chattr +C`) — a hard kernel requirement for BTRFS swapfiles. Without it, the kernel refuses to activate the swap.

In NixOS, the swapfile is declared in `configuration.nix` rather than `hardware-configuration.nix` — even though it feels like hardware config — because `hardware-configuration.nix` is auto-generated by `nixos-generate-config` and gets overwritten. Anything declared manually belongs in `configuration.nix`.

```nix
swapDevices = [{
  device = "/swap/swapfile";
  # size is informational — the file is already sized on disk by the setup script
}];
```

---

## Build Safety — Nix Resource Ceiling + `fallback = false`

**Role:** Preventing OOM kills during `nixos-rebuild switch` on a memory-constrained machine.

This is documented in full as [INC-2026-04-15-001](../development/incidents/INC-2026-04-15-001.md). The short version:

Running `nixos-rebuild switch` on `nixos-unstable` triggered source builds of `terraform`, `vault`, and `n8n` — all Go/Node.js heavy packages. On an 8GB machine with GNOME consuming ~2GB baseline, parallel multi-core builds exhausted memory and triggered the kernel OOM killer, crashing the terminal mid-build.

Two solution axes were applied together:

**Axis 1 — Resource ceiling:**
```nix
nix.settings = {
  max-jobs = 2;   # max 2 derivations building in parallel (was auto = 8)
  cores    = 2;   # each job gets 2 cores max — worst case: 4 cores total
};
nix.daemonCPUSchedPolicy = "idle";  # build daemon yields CPU to active session
nix.daemonIOSchedClass   = "idle";  # build daemon yields disk I/O too
```

**Axis 2 — Substitute-or-fail:**
```nix
nix.settings = {
  substituters      = [ "https://cache.nixos.org" ];
  trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
  fallback          = false;  # error on cache miss instead of silently building from source
};
```

`fallback = false` is the key insight. Instead of silently falling into a RAM-crushing build, Nix errors out and tells you which package has no substitute. Then you make an informed decision: wait for the cache, or explicitly allow the build with `--option fallback true`.

---

## Nix + Flakes

**Role:** The entire software layer — _user-space applications, DEs, dotfiles, shell config, dev tools. On NixOS, also the system itself._

Nix is a purely functional package manager. Every package is built from a deterministic derivation — _the same inputs always produce the same output._ Packages are stored in `/nix/store` with paths that include a hash of all inputs, making it impossible for two packages to conflict at the store level.

**What Nix gives CypherOS:**

- **Reproducibility** — `flake.lock` pins every input to an exact commit. Two machines with the same lock file get identical results.
- **Rollback** — every `nixos-rebuild switch` creates a new generation. Previous generations remain in the store and are bootable. `nixos-rebuild switch --rollback` reverts without a rebuild.
- **Shared store** — `@nix-store` at `/nix` is mounted by every OS. A package built once on NixOS is available on Arch without re-downloading or re-building.
- **Declarative** — the entire user environment (_DEs, applications, dotfiles, fonts, shell config_) is declared in code. Applying the flake to a fresh install reconstructs everything.
- **Generational garbage collection** — `nix-collect-garbage -d` removes all unreferenced store paths after unlinking old generations. Storage grows only for what's actually needed.

**Flakes:**

Nix Flakes are a standardized way to declare Nix expressions with explicit, pinned inputs. `flake.nix` is the CypherOS entry point. `flake.lock` is the reproducibility pin. Flakes are opt-in (_behind `experimental-features = ["nix-command" "flakes"]`_) but are the direction Nix is heading and are effectively standard for new projects.

**nixpkgs-unstable:**

CypherOS tracks `nixpkgs-unstable` — the rolling-release branch of nixpkgs. This gives access to the latest package versions and NixOS module updates. The trade-off is that packages built very recently may not yet have a cached binary in `cache.nixos.org` (_the cache lags the channel by hours to days_), which can trigger source builds. This is why `fallback = false` is configured.

---

## Home Manager

**Role:** Manages all user-space configuration and packages declaratively, across all OSs.

Home Manager is a Nix-based tool for declaratively managing the user environment. It generates config files, installs packages into the user's profile, manages `systemd --user` services, and can configure hundreds of applications natively via its module system.

**What Home Manager gives CypherOS:**

- **Dotfile management** — `home.file`, `xdg.configFile` deploy configuration files as symlinks into `$HOME`. Configuration lives in the repo; Home Manager wires it into place.
- **Native module support** — applications like `programs.neovim`, `programs.git`, `programs.zsh`, `wayland.windowManager.hyprland` have first-class HM modules that generate correct config from Nix declarations.
- **Cross-OS consistency** — the same `home.nix` applied on Arch, Debian, Fedora, and NixOS produces the same user environment. The native package manager handles the OS-level layer; Home Manager handles everything above it.
- **`home.stateVersion`** — marks the HM version at which the configuration was first created. Never change this after the fact — it signals to HM which migration paths to apply.

**HM on NixOS specifically:**

On NixOS, Home Manager is integrated into the system configuration via the `home-manager` NixOS module. The user config is evaluated as part of `nixos-rebuild switch`. Both the system config and the user environment are applied atomically in one command.

---

## XDG Base Directory Specification

**Role:** The mechanism for DE config isolation under a shared home directory.

The XDG Base Directory Specification defines four environment variables that applications use to find their **configuration, data, cache, and state**:

| Variable          | Default Path     | Purpose                            |
| ----------------- | ---------------- | ---------------------------------- |
| `XDG_CONFIG_HOME` | `~/.config`      | Application configuration          |
| `XDG_DATA_HOME`   | `~/.local/share` | Application data                   |
| `XDG_CACHE_HOME`  | `~/.cache`       | Non-essential cached data          |
| `XDG_STATE_HOME`  | `~/.local/state` | Persistent state (_logs, history_) |

CypherOS exploits this: by overriding these variables in a DE launcher script before exec-ing the session, every application that follows the XDG spec writes its config into the profiled path rather than the default. The result is complete namespace separation between DEs under one user.

```bash
export XDG_CONFIG_HOME="$HOME/.config/profiles/gnome"
# all GNOME apps write config to ~/.config/profiles/gnome/ instead of ~/.config/
```

Not all applications follow the XDG spec. The ones that hardcode `~/.config/appname` regardless of `$XDG_CONFIG_HOME` are the exceptions that need individual handling. In practice, this is a small minority.

---

## DE Variant Architecture

**Design intent — not yet implemented. Captured here so the design survives across sessions.**

The plan is not just one DE config per DE, but multiple configuration profiles per DE — each appearing as a distinct session entry in the display manager:

```nix
options.cypher-os.de.hyprland = {
  enable  = lib.mkEnableOption "Hyprland";
  variant = lib.mkOption {
    type    = lib.types.listOf (lib.types.enum [ "vanilla" "hyprdots" "hydenix" "celestia" ]);
    default = [ "vanilla" ];
  };
};
```

Setting `variant = [ "hyprdots" "celestia" ]` installs both config profiles and registers both DM session entries. The binary is installed once regardless of list length. Each variant gets its own XDG namespace under `~/.config/profiles/<variant>/`.

Module structure:

```
modules/de/<de>/
├── options.nix     ← declares enable + variant option
├── default.nix     ← HM shim
├── system.nix      ← installs the DE binary + shared dependencies
├── vanilla.nix     ← vanilla config profile + launcher script
└── <variant>.nix   ← variant config profile + launcher script
```

---

## OS Bootstrap Tools

**Role:** Scripted, reproducible OS installation for each fleet member.

When the master install script (`scripts/cypher-os-install.sh`) is built out in Phase 11+, each OS will be installed via its native bootstrap tool. Each tool is independently scriptable and produces a configurable, reproducible result.

|OS|Bootstrap Tool|Scriptability|
|---|---|---|
|Arch|`archinstall` JSON profile, or `pacstrap` + `arch-chroot`|Excellent|
|Debian|`debootstrap` — canonical minimal Debian install tool|Excellent|
|Fedora|`anaconda` kickstart files — declarative INI-style install scripts|Very good|
|NixOS|`nixos-install --flake .#cypher-nixos` — the entire install _is_ the config|Best in class|
|FreeBSD|`bsdinstall scripted` mode with an `installerconfig` file|Good|

The conceptual shape of the master install script:

```bash
# cypher-os-install.sh
# 1. Partition disk and create BTRFS subvolumes
# 2. Install Base OS into @<respective-subvolume>
# 3. Install remaining OSs into their subvolumes
# 4. Set up shared subvols (@home, @identity, @nix-store)
# 5. Write fstab entries for each OS
# 6. Configure systemd-boot entries for each OS
# 7. Bootstrap Nix + Home Manager on each Linux OS
# 8. Apply home-manager switch for cypher-whisperer on each
```

NixOS is the easiest step — `nixos-install --flake .#cypher-nixos` handles everything from the flake. FreeBSD is a separate phase, likely triggered by a reboot into a FreeBSD install medium. The architecture is designed to make each OS step independent and re-runnable.

---

## Disk Utility — `gdisk`

**Role:** GPT partition table creation during install.

`gdisk` (_GPT fdisk_) is the standard tool for creating and managing GPT partition tables. CypherOS uses it during install to create the two-partition layout. All further disk structure — subvolumes, mount points, swap — is handled by BTRFS tooling and the setup script.

The install guide covers the exact `gdisk` interaction. See [`README.md`](../../README.md#step-3--disk-partitioning).

---

## Identity Files — `@identity` Subvolume Contents

The `@identity` subvolume stores the canonical identity records in the same format as the standard Linux files they supplement:

```
identity/
├── passwd   # same format as /etc/passwd
├── group    # same format as /etc/group
└── shadow   # same format as /etc/shadow — GITIGNORED (contains hashes)
```

`libnss-extrausers` reads these files from wherever they are bind-mounted to (_configured to be `/var/lib/extrausers/` by default_). Each Linux OS bind-mounts the subvolume read-only at that path via `fstab`.

---

## Summary — Technology Decisions Cheat Sheet

|Technology|Role|Why Chosen|Key Constraint|
|---|---|---|---|
|BTRFS|Filesystem + OS skeleton|Subvolumes = no repartitioning to add OS|`chattr +C` on `@nix-store` and `@swap`|
|systemd-boot|Bootloader|Clean shared ESP multi-OS story|Replacing GRUB in Phase 1+|
|`libnss-extrausers`|Shared Linux identity|Decouples user records from per-OS `/etc/passwd`|UID must be consistent across all OSs|
|ZRAM|Primary swap|RAM-speed swap, zero disk writes|Per-OS; not a shared resource|
|BTRFS swapfile|Fallback swap|Last resort; disk-backed|`chattr +C` required; declare in `configuration.nix` not `hardware-configuration.nix`|
|Nix + Flakes|Package management + reproducibility|Deterministic, shared store, declarative, rollback|`fallback = false` on unstable channel|
|Home Manager|User environment management|Cross-OS consistency, dotfile management, native modules|`home.stateVersion` — set once, never change|
|XDG profiles|DE config isolation|One user, multiple DE namespaces, zero conflicts|Apps that ignore XDG spec need individual handling|
|`gdisk`|GPT partition creation|Standard GPT tool|Two-partition layout only|
