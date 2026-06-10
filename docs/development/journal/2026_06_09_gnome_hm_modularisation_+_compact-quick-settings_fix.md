# [2026_06_09] GNOME Module Modularisation + compact-quick-settings Fix

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-06-09
**Duration:** ~3–4 hours
**Repos touched:** [ `cypher-os` ]
**Modules touched:**
`modules/de/gnome/hm.nix`,
`modules/de/gnome/extensions.nix`,
`modules/de/gnome/theming.nix`,
`modules/de/gnome/dconf.nix`,
`modules/de/gnome/assets.nix`,
`modules/de/gnome/options.nix`,
`modules/de/gnome/system.nix`

**Phase:** GNOME Lens Stabilisation

---

## What I Worked On

Two things, in the order they happened: first, diagnosing and fixing a broken GNOME extension after a `nix flake update`; then using the excuse of having the full file open to do the modularisation of `hm.nix` that had been sitting on the to-do list.

---

## What Got Done

- Diagnosed `compact-quick-settings` extension silently not loading after flake update bumped GNOME Shell to **50.1** (was 47). Root cause: upstream `metadata.json` only declared `shell-version` up to `"47"` — GNOME 50 skipped it without any error.
- Fixed by overriding the nixpkgs derivation with an `overrideAttrs` `postInstall` hook that patches `metadata.json` via `jq`, appending `["48", "49", "50"]` to `shell-version`. Extension loads and applies correctly.
- Broke the monolithic `hm.nix` (350+ lines) into five focused sub-modules:
    - `assets.nix` — wallpaper and avatar `home.file` declarations
    - `theming.nix` — Catppuccin GTK/shell theme, `gtk` HM module, libadwaita assets
    - `extensions.nix` — extension packages, UUID activation, per-extension dconf, `compactQsExt` override
    - `dconf.nix` — all non-extension dconf settings
    - `hm.nix` (now thin) — composition root + XDG profile launcher script
- Documented all six non-default modules (_`assets.md`, `options.md`, `theming.md`, `extensions.md`, `dconf.md`, `hm.md`, `system.md`_) using the source file documentation template.
- Filed `IR-GNOME-003` for the extension incident.

---

## Key Decisions Made

1. **`launcher.nix` dropped — launcher stays in `hm.nix`.**
	- The XDG profile launcher script is genuinely singular — no siblings to group with, doesn't fit theming, extensions, dconf, or assets.
	- Extracting it to its own file would be modularisation for its own sake. `hm.nix` as the composition root is the natural home for session infrastructure that doesn't belong anywhere else.

2. **`options.nix` not imported in `hm.nix` — each sub-module imports it independently.**
	- Sub-modules are self-contained. Each imports `options.nix` itself rather than relying on a parent to have done it.
	- The cost is a repeated import declaration in five files; the benefit is that each sub-module is evaluable and debuggable in isolation.

4. **Extension dconf keys live in `extensions.nix`, not `dconf.nix`.**
	- Rule: if a dconf path is under `org/gnome/shell/extensions/`, it belongs in `extensions.nix` alongside the package and UUID that own it.
	- Everything else goes to `dconf.nix`. Clean boundary, easy to remember.

---

## Where I Got Stuck

Not stuck exactly, but the `ctpThemeName` cross-module question required a deliberate pause. It's the kind of thing that feels like it should have an obvious answer but doesn't.

I decided to have all logic that concerns the let-binding live in the `theming.nix` file.

---

## What I Learned

1. **GNOME silently skips incompatible extensions.**
	- No log entry at default verbosity, no error in the Extensions app — it just doesn't load.
	- The diagnostic path is `journalctl --user -b -g "compact-quick-settings"`, which shows the incompatibility message.
	- Good to know for future extension debugging.

2. **GNOME 50 ships in nixpkgs unstable.**
	- Was on 47, jumped to 50.1 in a single flake update.
	- The jump was larger than expected.
	- Worth checking GNOME Shell version before and after any flake update that might pull in a DE change.

3. **`overrideAttrs` + `postInstall` + `jq` is the standard pattern for metadata patching.**
	- Multiple nixpkgs extensions use this approach while waiting for upstream to cut a compatibility release.
	- Pattern is worth keeping in the toolkit.

---

## Open Questions

- How long until the upstream `compact-quick-settings` repo ships a GNOME 50–native release? The repo hasn't been updated in a while. Monitor: `https://github.com/mariospr/compact-quick-settings-gnome-shell-extension`. If it stays stale, evaluate migrating to `gnomeExtensions.quick-settings-tweaker` which actively maintains GNOME 48+ support.

---

## Next Session

- Confirm the entire setup is reproducible and works as should aftter the modularization.
- GNOME lens stabilisation continues — _check remaining items on the stabilisation target list before the Plasma port._

---

<!--
Commit range (fill in after session):
cypher-os: [short hash] → [short hash]
-->
