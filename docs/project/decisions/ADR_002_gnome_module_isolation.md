# ADR-002: GNOME Module Isolation

**Date:** 2026-04-15
**Status:** Accepted
**Deciders:** CypherWhisperer
**Related:** [ADR-005 — Module Architecture](https://claude.ai/chat/ADR-005-module-architecture.md) _(The three-file split pattern applied here was formalized into a system-wide convention in ADR-005. This ADR documents the specific case of GNOME; ADR-005 documents the general rule.)_

---

## Context

`gnome.nix` was the first NixOS/Home Manager module written for CypherOS. It started as a practical file — _"put all the GNOME stuff here"_ — and it worked. But it accumulated responsibilities well beyond GNOME:

```
gnome.nix (original)
├── imports ../apps        ← importing unrelated modules
├── imports ../gaming      ← importing unrelated modules
├── imports ../common      ← importing unrelated modules
├── GNOME extensions
├── dconf settings
├── GTK theme
├── XDG launcher script
└── home.stateVersion      ← HM root concern, not GNOME's business
```

This created a coupling problem: `gnome.nix` was simultaneously the **Home Manager entry point** (the file imported by `flake.nix` to bootstrap the HM configuration), the **apps/gaming/common importer**, and the **GNOME configuration module**. One file change in GNOME config could necessitate touching imports for unrelated modules, and vice versa.

Beyond the coupling, there was a layering conflict. NixOS modules and Home Manager modules run in separate evaluation contexts. A module that declares options AND sets system-level config (_`environment.systemPackages`, `services.*`_) in the same file causes HM to choke when it encounters NixOS-only attributes. As the configuration grew, this was becoming a real problem.

The path to adding Plasma and Hyprland as sibling DE modules was also blocked until GNOME's role as the de-facto HM entry point was untangled.

---

## Decision

Refactor `gnome.nix` into a dedicated `modules/de/gnome/` directory following a three-file split: `options.nix` (_option declarations_), `hm.nix` (_Home Manager config_), `system.nix` (_NixOS system config_). Extract the HM entry point responsibility into a dedicated `modules/home/default.nix`. Wire the `cypher-os.de.gnome.enable` option into the namespace.

---

## Reasoning

The core insight is that **one file should own one concern**. The original `gnome.nix` owned three distinct concerns simultaneously: GNOME configuration, HM bootstrapping, and module aggregation. Untangling these is what makes the architecture scalable.

**The new responsibility map:**

| File                            | Owns                                                                                       |
| ------------------------------- | ------------------------------------------------------------------------------------------ |
| `modules/home/default.nix`      | HM entry point. Imports all modules. Holds `home.stateVersion`.                            |
| `modules/de/gnome/default.nix`  | GNOME entry point — _a shim importing `options.nix` + `hm.nix`._                           |
| `modules/de/gnome/options.nix`  | Declares `cypher-os.de.gnome.enable`.                                                      |
| `modules/de/gnome/hm.nix`       | All GNOME Home Manager content: extensions, `dconf.settings`, GTK theme, XDG launcher.     |
| `modules/de/gnome/system.nix`   | All GNOME NixOS system content: `services.desktopManager.gnome.enable`, excluded packages. |
| `modules/apps/options.nix`      | Declares `cypher-os.apps.enable` master switch.                                            |
| `hosts/nixos/configuration.nix` | Imports `modules/profile`. Sets `cypher-os.profile.desktop.enable = true`.                 |
| `flake.nix`                     | HM users block now imports `modules/home/default.nix` instead of `modules/de/gnome.nix`.   |

**The `flake.nix` changes are minimal and surgical:**

Before:
```nix
# standalone homeConfigurations entry:
modules = [ ./modules/de/gnome.nix { ... } ];

# HM users block:
imports = [ ./modules/de/gnome.nix ];
```

After:
```nix
# standalone homeConfigurations entry:
modules = [ ./modules/home/default.nix { ... } ];

# HM users block:
imports = [ ./modules/home/default.nix ];
```

Two lines changed. The content of what gets evaluated is the same — `modules/home/default.nix` imports everything `gnome.nix` used to import, but now through the proper hierarchy.

**`modules/de/gnome/` restructuring — three changes only:**

1. Remove the `imports` block from the old `gnome.nix` (_these move to `home/default.nix`_).
2. Remove `home.stateVersion` (_moves to `home/default.nix`_).
3. Wrap everything remaining in a `config = lib.mkIf config.cypher-os.de.gnome.enable { ... }` block.

The GNOME-specific content itself — _extensions, dconf settings, GTK theme, XDG launcher_ — is not rewritten, only restructured into a proper container.

---

## Alternatives Considered

### Keep `gnome.nix` as-is, add Plasma and Hyprland as siblings with their own import chains

This doesn't solve the core problem. As soon as `plasma.nix` needs to import apps and gaming modules too, you end up with the same tangle in three places. The coupling is the problem, not the GNOME-specific content.

### Single combined file with conditional blocks

One large `de.nix` file with `lib.mkIf config.cypher-os.de.gnome.enable { ... }` and `lib.mkIf config.cypher-os.de.plasma.enable { ... }` blocks. This keeps the coupling in one place but creates a file that grows linearly with every new DE. It also mixes HM and NixOS concerns in the same file, which is the evaluation-context problem that causes HM to choke.

---

## Consequences

**Positive:**

- `gnome.nix` is now purely GNOME-concerned. Adding a Plasma or Hyprland module is now a parallel operation — _create `modules/de/plasma/` following the same pattern, add it to `modules/home/default.nix` imports and `hosts/nixos/configuration.nix`_. No touching the GNOME module.
- The HM entry point is explicit and owned — `modules/home/default.nix` is clearly the root, not whichever DE module happened to import everything else.
- `home.stateVersion` lives in one place, clearly, and is not entangled with any DE-specific file.
- NixOS evaluation context and HM evaluation context are cleanly separated. HM sees `hm.nix` and `options.nix`. NixOS sees `system.nix` and `options.nix`.

**Negative / Trade-offs:**

- A single DE is now four files instead of one. For a beginner, this can feel like over-engineering. The pattern pays for itself when the second and third DE are added without touching the first.
- The `flake.nix` import path changes — _if anything cached or scripted pointed at the old `gnome.nix` path, it needs updating._

**Neutral / Operational:**

- The hostname change from `nixos-gnome` to `nixos` (and corresponding rebuild target from `#nixos-gnome` to `#cypher-nixos`) happened in this same session. It's not strictly part of this ADR, but worth noting as a co-change.
- `hosts/nixos-gnome/` directory is retired. All future rebuilds target `hosts/nixos/`.
