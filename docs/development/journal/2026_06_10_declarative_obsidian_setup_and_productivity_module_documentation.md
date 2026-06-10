# [2026_06_10] Declarative Obsidian Setup + Modules Documentation

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-06-10
**Duration:** ~3–4 hours
**Repos touched:** `CypherOS`, `MY_OBSIDIAN_NOTES` (_private_)
**Modules touched:** `modules/apps/productivity/obsidian.nix`, `modules/apps/productivity/options.nix`, `modules/apps/productivity/hm.nix`, `modules/apps/productivity/claude.nix`, `modules/apps/productivity/penpot-hm.nix`, `modules/apps/productivity/penpot-system.nix`
**Phase:**

---

## What I Worked On

Stood up the declarative Obsidian module from scratch — _`programs.obsidian` via Home Manager._ The goal was a fully managed vault: core plugins, community plugins with declarative settings, Catppuccin theming, app/editor preferences, keybindings, and CSS snippets, all written to `.obsidian/` as Nix store symlinks.

Documented all source files within the module group `modules/apps/productivity/`

---

## What Got Done

- Authored `modules/apps/productivity/obsidian.nix` from the ground up; module is now stable
- Implemented `mkPlugin` helper — _inline `stdenv.mkDerivation` factory for GitHub-sourced community plugins, avoiding the non-existent `pkgs.obsidianPlugins.*` assumption_
- Packaged and pinned six community plugins: Style Settings, Obsidian Git, Dataview, Templater, Recent Files, Calendar — _all with resolved SRI hashes_
- Configured `defaultSettings.appearance`: three font slots, base font size
- Configured `defaultSettings.app`: readable line length, source mode default, live preview, fold indent, frontmatter hidden in reading view
- Declared full `corePlugins` list explicitly; `daily-notes` expanded to submodule form to carry settings (_folder, format, autorun_)
- Declared `communityPlugins` with `settings` blocks for Style Settings (_Catppuccin Mocha + Mauve_), Obsidian Git, Dataview, and Templater
- Declared `cssSnippets` with inline stop-blinking-cursor override
- Declared 25-entry `hotkeys` block covering navigation, sidebar toggles, editor primitives, tab management, graph, folding, daily note, and mode toggle
- Configured `vaults` with single vault at `DATA/FILES/PROJECTS/PRIVATE/PERSONAL/MY_OBSIDIAN_NOTES`
- Daily Notes pointed to `THE_CHAMBER_OF_SECRETS/00_MASTER_JOURNAL/DAILY_NOTES`; Calendar plugin added as its visual navigator

- Documented all six non-router modules in `modules/apps/productivity/` following the CypherOS source file documentation convention; files placed in `modules/apps/productivity/docs/`
- Corrected stale source comment in `claude.nix` — XDG isolation is a feature of the per-DE launcher architecture, not a leftover bug
- Confirmed `penpot-hm.nix` import moved from `hm.nix` to `default.nix` (routing correction)

---

## Key Decisions Made

1. **catppuccin/nix owns theme management.**
	- Initial approach manually fetched the Catppuccin theme via a `mkTheme` helper and declared it in `defaultSettings.themes`.
	- This caused `findSingle` in the HM obsidian module to throw `"Only one theme can be enabled at a time."` — because `catppuccin/nix` was already injecting its own theme derivation (`catppuccin-obsidian-0-unstable-2026-03-11`) automatically via the global `catppuccin.enable`.
	- The fix: remove `mkTheme`, `themeCatppuccin`, and `defaultSettings.themes` entirely. `catppuccin/nix` handles theme installation; Style Settings handles flavor/accent selection via `data.json`.

2. **`workspace.json` left unmanaged.**
	- HM symlinks all managed config files from the Nix store, which means Obsidian cannot write back to them at runtime.
	- Managing `workspace.json` would reset session state (_last open note, panel positions, scroll offsets_) on every `nixos-rebuild switch`.
	- The correct tradeoff is non-reproducible workspace state in exchange for usable daily sessions. _This is a permanent decision, not a deferred one._

3. **`communityPlugins` requires derivations, not strings.**
	- The HM module type is `listOf (coercedTo package ...)` — _each entry must be a Nix derivation or a submodule with a `pkg` derivation field._
	- Plain string plugin IDs (_the initial assumption_) are a type error.
	- There is no upstream `pkgs.obsidianPlugins.*` attribute set; plugins are built locally via `mkPlugin`.

4. **`corePlugins` settings go inline on the entry, not as a top-level key.**
	- `defaultSettings` does not accept arbitrary sub-keys.
	- Core plugin settings are attached to the plugin's own entry in the `corePlugins` list via the `settings` field of the `corePluginsOptions` submodule.
	- Trying to set `defaultSettings."daily-notes" = { ... }` throws an "option does not exist" eval error.

5. **`catppuccin/nix` does support Obsidian — contrary to initial research.**
	- Early research concluded `catppuccin/nix` had no Obsidian module. This turned out to be incorrect.
	- The support exists and activates implicitly when both `catppuccin.enable = true` (global) and `programs.obsidian.enable = true` are set.
	- This was only discovered by running `nix eval` on the live vault's `settings.themes` and seeing two derivations in the list.
	- Lesson: when a build error points at a specific option, eval that option directly before guessing at the cause.

6. **`default.nix` is the correct import point for `penpot-hm.nix`.**
	- The import was previously in `hm.nix` directly.
	- This was incorrect — _`default.nix` is the router for the group and is the right place for all sibling module imports._
	- Corrected during this session.
---

## Where I Got Stuck

1. **Theme conflict — `"Only one theme can be enabled at a time."`**
	- Took several iterations to diagnose.
	- The error message was clear but the source wasn't obvious — _nothing in the module visibly declared two themes. The breakthrough was running:_
```bash
nix eval '.#nixosConfigurations."cypher-nixos".config.home-manager.users.cypher-whisperer.programs.obsidian.vaults.my-obsidian-notes.settings.themes' --impure
```
- which revealed two enabled entries. From there the fix was immediate.

2. **`catppuccin/obsidian` version 404.**
	- The initial `themeCatppuccin` derivation used `version = "2.1.3"` — _a version that does not exist._
	- The latest actual tag at the time was `v2.0.4`. This was a hallucinated version number introduced during module authoring.
	- The fix required both correcting the tag and fixing the install phase filename (_`obsidian.css` → copy as `theme.css`_) — _two separate bugs surfaced by the same build failure._

3. **`defaultSettings."daily-notes"` is not a valid key.**
	- Spent a short time on an eval error before checking the HM module source directly and finding that `defaultSettings` only exposes typed sub-options (_`appearance`, `app`, `corePlugins`, etc._) — _there is no free-form `daily-notes` top-level slot._
	- Core plugin settings belong inline on the plugin entry within `corePlugins`.

---

## What I Learned

- `nix eval` on a specific config path is the fastest diagnostic tool when a build error implicates a specific option's evaluated value — _faster than reading source or guessing._
- HM's `coercedTo` type is powerful but invisible in error messages. When a type error says "package expected", the actual entry is probably a string, and the fix is wrapping it in `{ pkg = ...; }` or passing a proper derivation.
- `catppuccin/nix` implicit activation is broader than documented. Any program with `enable = true` that catppuccin/nix has a module for will receive theming automatically once `catppuccin.enable = true` is set globally. This is elegant but surprising when you're also trying to manage that program's config manually.
- Obsidian's three font slots (_`interfaceFontFamily`, `textFontFamily`, `monospaceFontFamily`_) are independent and all three must be declared together — _leaving any one unset causes it to reset to system default on rebuild._
- The Daily Notes + Calendar combination is the right architecture for a capture-first vault: Daily Notes eliminates the placement decision at write time; Calendar provides the temporal navigation layer; Note Composer handles extraction when a draft is ready to be promoted to its permanent home.

- The `lib.mkDefault` pattern for setting child enables inside a parent `mkIf` guard is functional but not expressive. It doesn't prevent silent no-ops when a child option is set `true` while the parent is `false`. A future session will address this with assertions.

- Documenting while the session is fresh is substantially faster than reconstructing from git history. The forcing function (_"if you can't write a sentence explaining this block, you've found a gap"_) surfaced two design decisions that weren't previously written down anywhere: the `workspace.json` intentional omission and the `options.nix` direct-import requirement for NixOS-context modules.

---

## Open Questions

- Are the Style Settings key names (`catppuccin@@flavor`, `catppuccin@@accent`) exactly correct? They've not been verified against a live `data.json` post-activation. If Catppuccin flavor controls don't appear in Preferences after rebuild, inspect the live file and update.
- `daily-notes` `template` is empty. A Templater-based daily note template (date heading, sections for tasks/captures/links) would close the loop on the capture workflow. Design the template in a future session.
- `workspace.json` is unmanaged — _is there value in managing the initial workspace layout (which panels are open, which sidebars are visible) as a one-time seed that Obsidian then takes over? Probably not worth the complexity, but worth considering._

- The `security.pki.certificateFiles` path in `penpot-system.nix` is hardcoded to `/home/cypher-whisperer/...`. Worth parametrising when the planned CypherOS local networking module is built.

---

## Next Session

- Verify Style Settings `data.json` key names against a live activation
- Design and add a Templater daily note template
- Explore `workspace.json` initial seeding decision
- Begin using Daily Notes in practice; assess Calendar plugin utility after a week

- Verify Style Settings `data.json` key names (`catppuccin@@flavor`, `catppuccin@@accent`) against a live activation
- Design and add a Templater daily note template
- Begin using Daily Notes in practice; assess Calendar plugin utility after a week
- Plan assertions + centralised profile management session for `cypher-os.apps.*` namespace

---

<!-- Commit range (fill in after session):
CypherOS: [short hash] → [short hash]
MY_OBSIDIAN_NOTES: [short hash] → [short hash]
-->
