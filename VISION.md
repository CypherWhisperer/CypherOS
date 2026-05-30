# Vision

> A single physical machine where multiple operating systems co-exist as bootable _lenses_ into one unified system — _sharing identity, data, software, and configuration_. Booting a different OS is not starting over; it is changing perspective.

---

## The Problem Being Solved

Distro-hopping has a tax. Every time you move from one OS to another, you pay it:

- A painstaking install process — _partitioning, base setup, driver configuration, all from scratch_.
- An environment setup process — _your shell, your editor, your DE, your tools, your dotfiles_ — rebuilt by hand or copy-pasted imprecisely.
- An identity problem — you are technically a different user on each OS. File ownership diverges. Credentials don't carry over. You re-login, re-authenticate, re-configure.

CypherOS is the answer to that tax. The goal is to eliminate — _or at minimum drastically reduce_ — every one of those friction points:

1. **Installation:**
	- With CypherOS, all supported OSs install at once.
	- Extending the fleet after the fact is a matter of editing a config file and running a script. Removal is the same.
	- No repartitioning. No starting over.

2. **Environment:**
	- Your environment is declared once and shared.
	- DEs, applications, shell configuration, dotfiles — all managed by Nix + Home Manager, applied identically whether you're booted into Arch, Debian, Fedora, or NixOS.
	- The OS is the lens. The environment is the constant.

3. **Identity:**
	- One user. One home directory. One set of credentials.
	- File ownership is anchored to a UID, not a username string, so every OS on the machine sees the same files owned by the same entity.

---

## The Five Pillars

### P1 — Filesystem & Partition Layer

**Technology:** BTRFS on a single SSD, structured with subvolumes.

The partition table is deliberately minimal — _exactly two partitions_:

- A small FAT32 EFI System Partition (_shared by all OSs, managed by systemd-boot_)
- The remainder as a single BTRFS partition, within which subvolumes do all the structural work

BTRFS subvolumes are not partitions — _they share a pool freely, grow and shrink without repartitioning, and support snapshots natively_. Adding a new OS to the fleet is `btrfs subvolume create @new-os-root`, not `gdisk`.

The subvolume layout:

```
@arch-root      → / (Arch Linux)
@debian-root    → / (Debian)
@fedora-root    → / (Fedora)
@nixos-root     → / (NixOS — canonical reference OS)
@home           → /home              [SHARED across all Linux OSs]
@nix-store      → /nix               [SHARED — CoW disabled via chattr +C]
@identity       → bind-mounted into /var/lib/extrausers  [SHARED, read-only]
@snapshots      → /.snapshots
@swap           → swapfile (CoW disabled)
```

Swap strategy: ZRAM as primary (compressed, RAM-backed, per-OS), `@swap` swapfile as the last-resort fallback only.

### P2 — Identity Layer

**Technology:** `libnss-extrausers` on Linux; explicit `uid = 1000` declaration on NixOS; `vipw` on FreeBSD.

One user: `cypher-whisperer`, UID `1000`, GID `1000`. The UID is the load-bearing piece — _file ownership on shared BTRFS subvolumes resolves by UID number, not by username string_. Every OS on the machine must agree on that number.

Canonical identity files live on the `@identity` subvolume and are bind-mounted read-only into every Linux OS at boot. `nsswitch.conf` on each OS is configured to consult `extrausers` after `files`. NixOS declares the user explicitly in `configuration.nix`. FreeBSD gets a manual `vipw` entry.

`systemd-homed` is explicitly out of scope — it manages identity per-OS locally and enters an `unfixated` state when a user record exists on one OS but not another. It is not a shared identity store and was never designed to be.

### P3 — Home & XDG Profile Layer

**Technology:** Shared `@home` BTRFS subvolume + XDG environment variable overrides per DE session.

One home directory: `/home/cypher-whisperer` on `@home`, mounted by every Linux OS. All personal data — _documents, media, projects, SSH keys, GPG keys, etc_ — lives here and is always accessible regardless of which OS is booted.

The DE conflict problem is real: running Hyprland and GNOME under the same `$HOME` causes fights over `~/.config/mimeapps.list`, `~/.config/autostart/`, `~/.local/share/` state files, and D-Bus session services. The solution is **XDG profile separation** — not multiple users, not multiple home directories. Each DE is launched by a Home Manager-managed wrapper script that overrides the XDG base directories before exec-ing the session:

```bash
export XDG_CONFIG_HOME="$HOME/.config/profiles/gnome"
export XDG_DATA_HOME="$HOME/.local/share/profiles/gnome"
export XDG_CACHE_HOME="$HOME/.cache/profiles/gnome"
export XDG_STATE_HOME="$HOME/.local/state/profiles/gnome"
exec gnome-session
```

Each DE gets its own config namespace. One identity, multiple environments, zero conflicts.

Intentionally _not_ profiled (_shared across all DE sessions_): `~/.ssh/`, `~/.gnupg/`, `~/.gitconfig`, shell rc files, fonts. Anything that doesn't cause DE conflicts stays generalized.

### P4 — Software Layer

**Technology:** Nix multi-user daemon + Home Manager on all OSs. NixOS gets full system Nix.

Nix owns everything above the OS ABI. The native package manager owns everything below it.

| Nix / Home Manager owns                 | Native package manager owns                        |
| --------------------------------------- | -------------------------------------------------- |
| All DEs (_Hyprland, GNOME, KDE Plasma_) | Kernel + kernel modules                            |
| All user-space applications             | Bootloader                                         |
| Shell + CLI tooling                     | Display drivers                                    |
| Dotfiles + DE config                    | Init system                                        |
| Fonts                                   | OS-level daemons                                   |
| XDG launcher scripts                    | `libnss-extrausers` itself                         |
| Dev tools, LSPs, runtimes               | _(NixOS exception: Nix owns all of the above too)_ |

The shared `@nix-store` at `/nix` is mounted by every OS that uses Nix. A package built once is available everywhere. Adding a second OS does not re-download or re-build anything already present in the store.

### P5 — Declarative & Dotfiles Layer

**Technology:** Nix Flakes + Home Manager modules in a git repository (`CypherOS`).

The `CypherOS` repository is the single source of truth for the entire system. A fresh OS install plus a flake apply reconstructs the full environment. The flake declares all hosts and all home configurations. `flake.lock` pins every input to an exact commit revision — _two machines applying the same flake with the same lock file get identical results_.

---

## What Success Looks Like

- Boot into Arch. Your shell is there. Your editor is configured. Your DE launches.
- Reboot into NixOS. Same shell. Same editor. Same DE. Same home directory.
- Install a new package via Nix on NixOS. It is immediately available on Arch.
- Add a new OS to the fleet. Edit a config file, run a script, reboot. Done.
- Lose the machine entirely. Apply the flake to a fresh install. The environment is back.
