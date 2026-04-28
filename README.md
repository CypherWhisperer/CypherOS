# CypherOS

A unified multi-OS system on a single machine — multiple operating systems
sharing one identity, one home directory, one software layer, and one
declarative configuration. Booting a different OS is not starting over; it is
changing perspective.

This repository is the single source of truth for the entire system. It is a Nix
Flake managed via [Home Manager](https://github.com/nix-community/home-manager),
targeting NixOS as the canonical reference OS and extending to Arch, Debian,
Fedora, and FreeBSD via the same user-space configuration.

---

## Repository Structure

````

CypherOS/
├── flake.nix                          # Entry point
│                                      # defines all hosts an home configs
├── flake.lock                         # Pinned input revisions
├── hosts/
│   ├── nixos/
│   │   ├── configuration.nix           # Full CypherOS NixOS host
│   │   └── hardware-configuration.nix  # Machine-generated
│   ├── arch/
│   │   └── home.nix                    # Future: Arch Linux Home Manager config
│   ├── debian/
│   │   └── home.nix                    # Future: Debian Home Manager config
│   └── fedora/
│       └── home.nix                    # Future: Fedora Home Manager config
│
├── modules/
│   ├── default.nix
│   ├── options.nix
│   ├── fonts-hm.nix
│   ├── fonts-system.nix
│   ├── xdg-config.nix
│   ├── profile/
│   │   ├── default.nix           # Entry Point for profile/
│   │   │                         # Also exposes options to HM at evaluation
│   │   ├── system.nix            # System-concerned options.
│   │   │                         # Exposes options to NixOS at evaluation
│   │   └── options.nix           # Profile-Related options
│   │
│   ├── users/
│   │   ├── default.nix           # Entry Point for user/
│   │   └── cypher-whisperer.nix  # Canonical user declaration
│   │
│   ├── home/
│   │   └── default.nix           # Entry point for home/
│   │
│   ├── shell/
│   │    ├── default.nix
│   │    ├── options.nix
│   │    ├── system.nix
│   │    └── {zsh,fish,nushell}.nix
│   │
│   ├── de/
│   │   ├── default.nix        # Entry point for de/
│   │   ├── assets             # DE-related assets (wallpaper, avatar img, ...)
│   │   └── {gnome, hyprland,plasma}/
│   │       ├── default.nix    # DE Entry point
│   │       ├── options.nix    # DE-related options declaration.
│   │       ├── system.nix     # System concerns (install, sys-level configs)
│   │       ├── hm.nix         # Home Manager Concerns
│   │       └── {...}.nix      # Other DE related modules
│   │                          # Such as diff configuration variants
│   │
│   ├── apps/
│   │   ├── default.nix        # Entry point for apps/
│   │   ├── options.nix        # cypher-os.apps.enable option declaration
│   │   └── {browser,cli,common,dev,editor,productivity,terminal}/
│   │       ├── default.nix    # Entry point for browser/
│   │       ├── options.nix    # Browsers-related options declaration.
│   │       ├── hm.nix         # Home Manager Concerns
│   │       └── {...}.nix      # app modules in each category.
│   │
│   ├── dm/
│   │   ├── default.nix        # Entry point for de/
│   │   ├── assets             # DM-related assets
│   │   └── {gdm, sddm}/
│   │       ├── default.nix    # dm Entry point
│   │       ├── options.nix    # dm-related options declaration.
│   │       ├── system.nix     # System concerns
│   │       └── {...}.nix
│   │
│   ├── {devops,virtualisation}/
│   │   ├── default.nix        # Entry point
│   │   ├── options.nix        # Related options declaration
│   │   ├── system.nix         # System Level Concerns
│   │   └── {...}.nix
│   │
│   └── gaming/
│       ├── default.nix        # Entry point for gaming/
│       ├── options.nix        # Gaming-Related options declaration
│       ├── minecraft.nix      # Minecraft Launcher and configuration
│       ├── steam-system.nix   # Steam System Level Concerns
│       └── steam-hm.nix       # Steam Home Manager Level Concerns
│
├── configs/                   # Configurations
├── scripts/                   # Scripts
└── identity/
    ├── passwd                 # Canonical extrausers passwd
    ├── group                  # Canonical extrausers group
    └── shadow                 # Gitignored — contains password hashes
```

---

## The `flake.lock` File

The `flake.lock` file pins the exact commit revision of every flake input — `nixpkgs`, `home-manager`, and any future inputs. It is the mechanism that makes the configuration reproducible: two machines applying the same flake with the same `flake.lock` get identical results.

### Generating `flake.lock` for the first time

This must be done on a machine with a working Nix installation and reliable network access — not inside the NixOS installer environment.

```bash
cd /path/to/CypherOS
nix flake update --extra-experimental-features "nix-command flakes"
git add flake.lock
git commit -m "chore (flake.lock): pin flake inputs"
git push
````

### Updating inputs

To pull in newer versions of `nixpkgs` or `home-manager`:

```bash
nix flake update --extra-experimental-features "nix-command flakes"
git add flake.lock
git commit -m "chore(flake): update flake inputs $(date +%Y-%m-%d)"
```

---

## Installing NixOS — Step by Step

Installation Procedure

### Prerequisites

- NixOS minimal ISO written to a USB drive
- Network credentials available

---

### Step 1 — Boot the Minimal ISO

Boot from the USB drive. You will land at a root shell. No graphical installer
is required or expected.

---

### Step 2 — Network Setup

Connect to WiFi using NetworkManager's CLI:

```bash
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
```

**Immediately after connecting, lock DNS to public resolvers:**

```bash
sudo nmcli con mod "YOUR_SSID" ipv4.dns "1.1.1.1,8.8.8.8"
sudo nmcli con mod "YOUR_SSID" ipv4.ignore-auto-dns yes
sudo systemctl restart NetworkManager
```

**Why this matters:** Consumer routers often serve their own IP as the DNS
forwarder (e.g. `192.168.1.1`). This works for most applications but can fail
intermittently for the Nix daemon, which makes many concurrent DNS requests.
Additionally, router DNS configs sometimes include IPv6 link-local addresses
(e.g. `fe80::1%wlp2s0`) that are scoped to a specific network interface — inside
the installer's chroot environment, that interface name does not exist, causing
all DNS resolution to hang and time out. Setting `1.1.1.1` and `8.8.8.8`
directly eliminates both failure modes before they have a chance to appear.

Verify connectivity:

```bash
ping -c 2 github.com
ping -c 2 api.github.com
```

Both must resolve before proceeding.

---

### Step 3 — Disk Partitioning

Identify your target disk:

```bash
lsblk
```

Partition the disk. This setup uses GPT with two partitions: a small EFI System
Partition and a large BTRFS partition for all subvolumes.

```bash
gdisk /dev/sda    # replace sda with your actual disk name
```

Inside `gdisk`:

```
o          → create new GPT table, confirm with y
n          → new partition (EFI)
enter      → partition number 1
enter      → default first sector
+512M      → 512MB size
ef00       → EFI System Partition type

n          → new partition (BTRFS root)
enter      → partition number 2
enter      → default first sector
enter      → use all remaining space
8300       → Linux filesystem type

w          → write changes, confirm with y
```

Format the partitions:

```bash
mkfs.fat -F32 /dev/sda1     # EFI partition
mkfs.btrfs -f /dev/sda2     # BTRFS partition
```

> **Note:** Adjust partition numbers to match your disk. On NVMe drives the
> naming is typically `/dev/nvme0n1p1` and `/dev/nvme0n1p2`.

---

### Step 4 — BTRFS Subvolumes

#### **Subvolume rationale:**

| Subvolume     | Mount Point | Purpose                                             |
| ------------- | ----------- | --------------------------------------------------- |
| `@nixos-root` | `/`         | NixOS system root                                   |
| `@home`       | `/home`     | Shared home directory — all OSs mount this          |
| `@nix-store`  | `/nix`      | Shared Nix store — all OSs share installed packages |
| `@swap`       | `/swap`     | Swap Partition                                      |

The shared `@nix-store` is the key to the CypherOS architecture: packages built
once are available to every OS that mounts `/nix`. Adding a second OS does not
re-download or re-build anything already present.

#### Install required Tools

```bash
nix-shell -p git neovim
```

This drops you into a temporary shell with `git` and `neovim` available via the
live Nix daemon. Use `neovim` to edit configuration files if needed during the
install.

#### Clone the Repository

```bash
git clone --recursive-submodules https://github.com/CypherWhisperer/CypherOS CypherOS
```

> **On the git working tree:** `nixos-install` and `nixos-rebuild` require the
> flake path to be either a clean git tree or a path without git tracking. If
> you encounter a `git tree is dirty` warning that becomes an error, the options
> are:
>
> **Option A — Stage all changes before installing:**
>
> ```bash
> cd /mnt/etc/nixos/CypherOS
> git add -A
> ```
>
> This is the cleanest approach during active development. Changes are staged
> (visible to Nix) without requiring a commit.
>
> **Option B — Use the `--impure` flag:**
>
> ```bash
> nixos-install --flake /mnt/etc/nixos/CypherOS#nixos-gnome --impure
> ```
>
> This tells Nix to allow dirty trees. Convenient but bypasses the
> reproducibility guarantee.
>
> **Option C — Separate tracked and working directories:** Keep the canonical
> repo in a development directory (e.g. `~/CypherOS`) and sync to
> `/etc/nixos/CypherOS` via `rsync` before rebuilding:
>
> ```bash
> rsync -av --delete ~/CypherOS/ /etc/nixos/CypherOS/
> ```
>
> This works but adds a manual sync step. Not recommended as the primary
> workflow — stage changes (Option A) instead.

#### Run the script to setup the disk accordingly

```bash
bash scripts/setup-disk.sh
```

### Step 5 — Generate Hardware Configuration

```bash
sudo nixos-generate-config --root /mnt
```

This produces two files in `/mnt/etc/nixos/`:

- `hardware-configuration.nix` — machine-specific: disk UUIDs, CPU, detected
  hardware. This is what you need.
- `configuration.nix` — a generic template. Ignore it; this repository provides
  the real one.

### Step 6 — Move CypherOS into the repo

```bash
mv CypherOS /mnt/ect/nixos/CypherOS
```

### Step 7 — Move Your Hardware Configuration

```bash
mv /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/etc/nixos/CypherOS/hosts/nixos/
```

Stage it immediately:

```bash
cd /mnt/etc/nixos/CypherOS
git add -A
```

---

### Step 8 — Install

```bash
nixos-install --flake /mnt/etc/nixos/CypherOS#cypher-nixos
```

Nix will download and build the entire system closure. The install is dependent
on connection quality and cache availability.

> **On nixpkgs unstable:** Some packages on the unstable channel do not yet have
> pre-built binaries in the Nix binary cache (`cache.nixos.org`). For these, Nix
> falls back to building from source — this is why builds on unstable can
> occasionally take significantly longer than expected. If a build is taking
> hours, check whether a source compilation is in progress and consider the
> package's necessity.

When the install completes, you will be prompted to set a **root password**. Set
one — it is required for emergency recovery.

---

### Step 9 — Set User Password

Before rebooting, set the password for `cypher-whisperer`:

```bash
nixos-enter --root /mnt
passwd cypher-whisperer
exit
```

> **NOTE:** NixOS does not set a default password for declared users. Skipping
> this step means the account will be locked and you will not be able to log in
> at GDM. Though there is a work around. on GDM (or andy Display Manager), hit
> (CTLR+ALT+[Any function Key (F1, F2, ....)]). This drops you in a TTY
> environment where you can log in as root and set the user password there.

---

### Step 10 — Reboot

```bash
reboot
```

Remove the USB drive when the screen goes black during shutdown. The system will
boot into GDM.

---

### Step 11 — Post-Boot

If any configuration changes are needed, edit the relevant module and rebuild
without rebooting:

```bash
sudo nixos-rebuild switch --flake /etc/nixos/CypherOS#cypher-nixos
```

---

## Applying Changes After Install

| Scenario                         | Command                                                              |
| -------------------------------- | -------------------------------------------------------------------- |
| Changed anything in the flake    | `sudo nixos-rebuild switch --flake /etc/nixos/CypherOS#cypher-nixos` |
| Updated `flake.lock` inputs      | `sudo nixos-rebuild switch --flake /etc/nixos/CypherOS#cypher-nixos` |
| Roll back to previous generation | `sudo nixos-rebuild switch --rollback`                               |
| Clean up old generations         | `sudo nix-collect-garbage -d && sudo nix store gc`                   |

---

## Generations and Storage

NixOS builds are additive and use hard links extensively. When you rebuild after
changing one package, only that package's new derivation is added to the store —
unchanged packages are shared between generations via hard links and consume no
additional space. A 20GB system does not become 40GB after one rebuild.

Old generations hold references to packages that were removed in newer builds.
Running `nix-collect-garbage -d` removes all old generation links and then frees
any store paths no longer referenced by any generation. This is safe to run at
any time.

---

## Secrets and SSH Keys

SSH private keys (`~/.ssh/id_ed25519` etc.) are **never tracked in this
repository**. The repository manages the SSH _configuration_ (`~/.ssh/config`)
declaratively via `programs.ssh` in Home Manager. The keys themselves live in
`~/.ssh/` on the `@home` BTRFS subvolume.

In the full CypherOS architecture, `@home` is shared across all OSs. This means
SSH keys generated once are automatically available on every OS that mounts
`@home` — no copying or re-generation required.

The `identity/shadow` file is gitignored for the same reason — it contains
password hashes.
