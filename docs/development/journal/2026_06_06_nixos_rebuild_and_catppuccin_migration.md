# 2026-06-06 NixOS Rebuild, pipx Breakage, and Catppuccin Migration

**Date:** 2026-06-06
**Duration:** ~3–4 hours
**Repos touched:** CypherOS
**Modules touched:**
- `modules/apps/dev/hm.nix`
- `modules/apps/terminal/ghostty.nix`
- `modules/apps/dev/git.nix`
- `modules/de/gnome/hm.nix`
- `modules/apps/editor/vscode.nix`
- `flake.nix`

**Phase:** Phase 1 — System Stabilisation

---

## What I Worked On

Routine `nix flake update` followed by a system rebuild. What started as a standard maintenance rebuild cascaded into resolving a broken upstream package (`pipx-1.8.0`), then diagnosing a VSCode theme regression, then migrating the entire theming stack from a hand-rolled GTK approach to `catppuccin/nix`'s managed module system.

---

## What Got Done

- Identified `python3.13-pipx-1.8.0` as the root cause of a full system build failure — upstream test suite regression in `test_package_specifier.py`
- Resolved the pipx failure by commenting it out temporarily pending an upstream fix (already merged in nixpkgs `master`, will resurface cleanly on next `nix flake update`)
- Diagnosed VSCode catppuccin theme regression as a missing global `catppuccin.enable = true` switch — the `catppuccin/nix` module requires this to activate autoEnable cascade across apps
- Added global catppuccin config (`catppuccin.enable`, `catppuccin.flavor`, `catppuccin.accent`) to the desktop profile
- Resolved three module conflicts surfaced by the global enable:
  - **Ghostty:** removed hand-rolled `themes.catppuccin-mocha` block; catppuccin/nix now owns it
  - **Delta:** resolved `features` string conflict with `lib.mkForce "catppuccin-mocha decorations"`; removed redundant `syntax-theme`
  - **GTK icons:** removed manual `gtk.iconTheme` block from `gnome/hm.nix`; catppuccin/nix gtk module owns icon theming exclusively (GTK theme itself is no longer managed by the module — `catppuccin-gtk` upstream was archived)
- Confirmed catppuccin/nix gtk module scope: **only** manages `catppuccin.gtk.icon` (Papirus folders). GTK theme, cursors, and libadwaita CSS remain hand-rolled in `gnome/hm.nix` — this is correct and intentional.
- Produced INC and ADR documentation for the session

---

## Key Decisions Made

- **pipx: comment out, don't patch.** Overhead of an overlay for a tool not currently in active use isn't worth it. Re-enable after next flake update. See INC_2026_06_06_001.
- **Migrate to global catppuccin/nix theming.** Eliminates fragmented per-app manual theme declarations and conflicts. See ADR_006.
- **GTK theme stays hand-rolled.** The catppuccin/nix gtk module dropped GTK theme management entirely (upstream archived). The `catppuccin-gtk` + libadwaita CSS approach in `gnome/hm.nix` is the correct path forward.

---

## Where I Got Stuck

- **Overlay placement.** First attempt placed the `doCheck = false` overlay in the top-level `let pkgs = ...` binding, which doesn't reach `nixosSystem`'s internal `pkgs` instantiation. The overlay would have needed to go into `nixpkgs.overlays` inside the NixOS module system to work. Moot point since we went with the comment-out approach instead.
- **catppuccin/nix module scope.** Had to look up the current source to confirm what the gtk module actually still manages — the upstream catppuccin-gtk port was archived between versions, stripping the module down to icon theming only. This wasn't obvious from the error message alone.

---

## What I Learned

- `nixosSystem` instantiates its own `pkgs` internally. Overlays defined in the top-level `let pkgs = ...` binding in `flake.nix` do **not** propagate to `nixosConfigurations` — they only affect standalone `homeConfigurations`. Overlays for the NixOS-integrated path must go into `nixpkgs.overlays` within the NixOS module system (e.g. in `configuration.nix`).
- `catppuccin.enable = true` is the global master switch for the catppuccin/nix module. Without it, per-app options like `catppuccin.vscode.profiles.default.enable = true` evaluate but `autoEnable` is never satisfied, so nothing activates. This is the correct behaviour — opt-in at the system level, not per-app.
- The catppuccin/nix gtk module no longer manages GTK theme or cursors — only the Papirus icon set. The `catppuccin-gtk` upstream repo was archived. Any config referencing the old `gtk.catppuccin.enable` pattern is now broken.
- When `catppuccin.enable = true` is set globally, every app catppuccin/nix knows about will attempt to inject its theme. Any hand-rolled catppuccin config for those apps will conflict. The migration pattern is: remove manual theme blocks, let the module own it.

---

## Open Questions

- LibreOffice UI breakage (white background, low-contrast icons) under `catppuccin-gtk` is unresolved. This predates today's session and is a known limitation of the hand-rolled GTK theme approach. Needs a dedicated investigation — likely requires either a GTK2 theme fallback or switching to `adw-gtk3` for GTK3/GTK2 apps and reserving the catppuccin theme for libadwaita only.
- Should `catppuccin.gtk.icon` be explicitly disabled and the icon theme kept hand-rolled for consistency with the rest of the GTK theming approach? Currently both paths produce the same result (same package, same flavor/accent) so the conflict is avoided by deletion. Worth confirming the catppuccin/nix icon output matches what was previously configured.

---

## Next Session

- Re-enable `pipx` after next `nix flake update` and confirm it builds cleanly
- Investigate LibreOffice GTK breakage — consider `adw-gtk3` for GTK2/3 and restricting catppuccin-gtk to libadwaita only
- Audit remaining apps in `grep -r "catppuccin" ~/CypherOS/modules/ --include="*.nix" -l` for any remaining hand-rolled theme blocks that now conflict with catppuccin/nix autoEnable

---

<!--
Commit range (fill in after session):
CypherOS: [short hash] → [short hash]
-->
