# Changelog

All notable changes to CypherOS are documented here. This file follows a loose [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) structure, adapted to fit the session-based development rhythm of this project.

Each entry links to the relevant journal entry, ADRs, and incidents that explain the _why_ behind what changed. The changelog is the surface — those documents are the depth.

---

## [Unreleased]

_Pending: documentation pass (this very effort), Plasma module, Hyprland module, SDDM wiring, server profile guards, assertion layer._

---

## [0.2.0] — 2026-04-15 to 2026-04-16

**Module Architecture Refactor + System Stability**

The session that brought the NixOS configuration from a functional-but-monolithic state to a properly modular, namespace-driven architecture. Also addressed an OOM build crash that was making development painful.

→ Journal: [2026-04-15 — NixOS Migration Session](docs/development/journal/2026_04_15_nixos_migration.md)

### Added

- `cypher-os` namespace — a Nix options tree covering `profile`, `shell`, `de`, `dm`, `apps`, `gaming`, `devops`, `virtualisation`. Every module group now declares typed options under this namespace. ([ADR-001](https://claude.ai/chat/docs/project/decisions/ADR-001-cypher-os-namespace-design.md))
- `modules/home/default.nix` — dedicated Home Manager root module. Owns all HM imports and `home.stateVersion`. Extracted from the inline `flake.nix` HM config.
- `modules/profile/` — meta-switches (`desktop.enable`, `server.enable`). One line in `configuration.nix` now activates the entire desktop stack via `lib.mkDefault` cascade. ([ADR-001](https://claude.ai/chat/docs/project/decisions/ADR-001-cypher-os-namespace-design.md))
- Three-file split convention across all module groups: `options.nix` (declarations), `hm.nix` (Home Manager config), `system.nix` (NixOS system config). ([ADR-005](https://claude.ai/chat/docs/project/decisions/ADR-005-module-architecture.md))
- ZRAM swap — `zramSwap` with `zstd` algorithm at 50% RAM. Compressed in-memory swap device sitting in front of the disk swapfile in the kernel's priority hierarchy. ([ADR-004](https://claude.ai/chat/docs/project/decisions/ADR-004-zram-setup.md))
- Nix build resource ceiling — `max-jobs = 2`, `cores = 2`, `daemonCPUSchedPolicy = "idle"`, `daemonIOSchedClass = "idle"`. Prevents OOM kills during heavy builds while the DE is active. ([INC-2026-04-15-001](https://claude.ai/chat/docs/incidents/INC-2026-04-15-001.md))
- `fallback = false` in `nix.settings` — Nix now errors on cache miss instead of silently falling into a RAM-crushing source build. ([INC-2026-04-15-001](https://claude.ai/chat/docs/incidents/INC-2026-04-15-001.md))

### Changed

- `modules/de/gnome.nix` refactored and split into `modules/de/gnome/{default,options,hm,system}.nix`. GNOME module is now purely GNOME-concerned — it no longer doubles as the HM entry point or imports unrelated modules. ([ADR-002](https://claude.ai/chat/docs/project/decisions/ADR-002-gnome-module-isolation.md))
- `flake.nix` HM entry point updated from `./modules/de/gnome.nix` to `./modules/home/default.nix`.
- `hosts/nixos-gnome/` directory retired. Host is now `hosts/nixos/`. Rebuild target: `--flake .#cypher-nixos`.
- Swap activated — `swapDevices` declared in `configuration.nix` pointing to `/swap/swapfile`. The `@swap` subvolume existed on disk but NixOS was never told about it. ([ADR-003](https://claude.ai/chat/docs/project/decisions/ADR-003-swap-activation.md))

### Conventions Established

- `default.nix` files are Home Manager concerns — imported directly or indirectly by `modules/home/default.nix`. They expose their declarations to HM at evaluation time.
- `system.nix` files are NixOS system concerns — imported directly or indirectly by `hosts/nixos/configuration.nix`. They expose their declarations to NixOS at evaluation time.
- `options.nix` files are the single source of truth for option declarations within a module group. Options are declared once, imported by both HM and NixOS evaluation contexts.
- `lib.mkDefault` in profile modules; explicit assignment in host configs. The profile sets sensible defaults; the host overrides precisely where needed.
- `hardware-configuration.nix` is machine-generated and never manually edited.
- `home.stateVersion` lives in `modules/home/default.nix`, set once, never changed.
- Inline comments are first-class — modules are self-documenting.

---

## [0.1.0] — Pre-2026-04-15

**Initial NixOS Configuration — GNOME Replica**

The parallel GNOME sub-task that preceded the architecture refactor. Starting from the original Debian GNOME setup, a `modules/de/gnome.nix` was produced and applied to a minimal NixOS install to produce a pixel-accurate GNOME replica. This was the proof-of-concept for the Nix layer and established `cypher-whisperer` in NixOS territory before main architecture work began.

_Detailed journal not yet written for this phase. The result feeds into [0.2.0]._

---

## Reference — `lib.mk*` Cheat Sheet

Kept here as a quick reference for maintaining and extending modules.

|Function|Use|
|---|---|
|`lib.mkEnableOption`|Declare a boolean option, default `false`. One-liner toggle pattern.|
|`lib.mkOption`|Declare a typed option with full control: type, default, description.|
|`lib.mkIf <cond> { }`|Apply a config block only when the condition is true.|
|`lib.mkMerge [ ]`|Combine multiple independent config blocks in one `config` section.|
|`lib.mkDefault <val>`|Set a value at low priority — explicit host assignments always override it.|
|`lib.mkForce <val>`|Set a value at high priority — overrides everything else. Use sparingly.|
