# 2026_06_13 Obsidian Canvas Configuration & Knowledge Tools Research

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-06-13
**Duration:** ~2–3 hours
**Repos touched:** [ `cypher-os` ] 
**Modules touched:** [ `modules/apps/productivity/obsidian.nix` ] 
**Phase:** 

---

## What I Worked On

Started with a curiosity about "murder board" style spatial knowledge tools — _infinite canvas apps where you can drop PDFs, images, sticky notes, and build visual knowledge graphs._

That research led back to a realisation: Obsidian Canvas, which was already declared in the module's `programs.obsidian.defaultSettings.corePlugins` list and working, is a legitimate answer to the same problem.

The session pivoted to properly configuring Canvas declaratively and evaluating the broader plugin ecosystem around it.

Also produced self-hosting prompt templates for AFFiNE and Logseq to handle in dedicated a different conversations.

---

## What Got Done

- Identified the visual PKM / infinite canvas tool space: Milanote (what DamiLee uses in the YouTube footage), Heptabase, AFFiNE, Logseq, and Obsidian Canvas as the relevant players. Filtered to privacy-first, self-hostable options: AFFiNE and Logseq shortlisted for future sessions.

- Confirmed Obsidian Canvas _(already active via `corePlugins`)_ natively renders: markdown note content inline, images, PDFs page-by-page, video, audio, and fully interactive webpage iframes. Text cards serve as sticky note equivalents. The tool was already capable — _it just hadn't been explored._

- Identified and added the `webviewer` core plugin as a required dependency for webpage cards (iframe nodes) to render correctly on canvas.

- Identified and added the `bases` core plugin _(Obsidian v1.8+ structured data/database feature)_ and noted that a community plugin exists to render Bases views as canvas nodes.

- Researched and added three canvas-specific community plugins to the module:
    
    - **Advanced Canvas** (`Developer-Mike/obsidian-advanced-canvas`):
        - graph view integration, presentation mode, flowchart node shapes, better edge routing.
        - Core plugin for serious canvas use.
          
    - **Optimize Canvas Connections** (`felixchenier/obsidian-optimize-canvas-connections` v1.0.0):
        - reroutes connection edges to nearest node sides after spatial rearrangement.
        - Two modes: shortest path (aggressive) and preserve axes (respects horizontal/vertical directionality — use this when axes carry semantic meaning).
          
    - **Canvas Filter** (`IKoshelev/Obsidian-Canvas-Filter` v0.9.4):
        - show/hide nodes by tag, color, or connection on large research boards. 
        - Non-destructive; `canvas-filter:restore-all` unhides everything.

- Added `canvasSnap = true` to `defaultSettings.app` for cleaner default spatial layout on canvas boards.

- Investigated declarative default folder configuration for new Canvas and Bases files. Findings:
    
    - `home-manager.users.cypher-whisperer.programs.obsidian.vaults.my-obsidian-notes.settings.corePluginSettings` does not exist in the HM module — the build error confirmed this. Valid `settings` keys are: `app`, `appearance`, `corePlugins`, `communityPlugins`, `cssSnippets`, `themes`, `hotkeys`, `extraFiles`.
    - Canvas has no `newFileFolderPath` or equivalent in either `app.json` or a `canvas.json` config. Obsidian does not expose a configurable default folder for new canvas files.
    - Bases has the same gap — _no default folder setting as of mid-2025; open feature request, unresolved._
    - **Workaround for both:** always create via right-click on target folder in File Explorer. With `newFileLocation = "current"` already set, files spawn in the active folder — right-clicking the correct folder is the canonical workflow until Obsidian ships the setting.

- Produced prompt templates for two dedicated future conversations: `[AFFiNE — Self-Hosting on CypherOS]` and `[Logseq — Self-Hosting on CypherOS]`. Both include context on the CypherOS stack, Docker Compose + Caddy infrastructure, the Penpot-style self-hosted instance question, dark mode / Catppuccin theming question, and the `~/DATA/` data path convention.


---

## Key Decisions Made

1. **Canvas as primary spatial knowledge tool (for now):** 
    - Rather than immediately standing up AFFiNE or Logseq, the decision is to explore Obsidian Canvas first since it's already installed, already working, and shares the same vault as all existing notes. 
    - AFFiNE and Logseq are queued for their own sessions.
    
2. **Plugin trio for Canvas:** 
    - Advanced Canvas + Optimize Canvas Connections + Canvas Filter declared as the canonical canvas plugin set. 
    - These cover edge management, spatial cleanup, and selective visibility — _the three biggest UX gaps in raw Canvas._
    
3. **No `corePluginSettings` block:** 
    - Removed after confirming the key does not exist in the upstream HM module schema. 
    - Canvas folder configuration is a workflow discipline _(right-click to create)_, not a declarative setting.
    

---

## Where I Got Stuck

1. **Ghost plugin:** 
    - _"Canvas Connections Popover"_ was named in an earlier response as a standalone plugin. 
    - It does not exist as a distinct plugin — the functionality is part of Advanced Canvas.
    - Cost a round-trip to clarify. 
    - Lesson: verify plugin names against the actual Obsidian community plugin registry before declaring them.
    
2. **`corePluginSettings` error:** 
    - The build failed with a clear schema error after adding a `corePluginSettings` block under vault settings. The key was fabricated — the upstream module never had it. The error message from Nix was actually helpful here, listing the valid sibling keys directly. Removed the block entirely since no replacement exists.
    
3. **Canvas folder setting doesn't exist in Obsidian:** 
    - Spent time researching whether `newFileFolderPath` was a valid key in `canvas.json` or `app.json`. Neither. It simply doesn't exist in Obsidian's configuration surface. Not a Nix problem — an Obsidian gap.


---

## What I Learned

1. **Obsidian Canvas is more capable than it looks at a glance.**
    - Video, audio, PDFs, webpages, nested canvases — all native. 
    - The mental model of "it's just a whiteboard" undersells it. 
    - It's closer to a spatial document with full vault integration.
    
2. **The HM obsidian module's valid `settings` keys are fixed and narrow:**
    - `app`, `appearance`, `corePlugins`, `communityPlugins`, `cssSnippets`, `themes`, `hotkeys`, `extraFiles`.
    - Anything outside this list will fail the build immediately. When in doubt, read the upstream source before declaring.
    
3. **`corePlugins` in HM takes a list of submodules**
    - (`{ name, enable, settings }`), not a flat list of strings — though the module coerces plain strings via `coercedTo` for convenience. 
    - Settings declared under a core plugin entry write to `.obsidian/<plugin-name>.json` at vault build time.
    
4. **Obsidian Bases**
    - (v1.8+) is a native structured data layer — frontmatter- backed tables queryable like Dataview but without a community plugin. 
    - Worth integrating into the knowledge workflow once canvas use matures.
    
5. **`webviewer` is a non-obvious required dependency**
    - for Canvas webpage nodes.
    - It's disabled by default and not documented prominently. Without it, URL-type canvas cards render broken.
    
6. **Optimize Canvas Connections — prefer "preserve axes" mode**
    - for research boards where layout carries meaning. "Shortest path" is for cleanup only.
    
7. **The spatial IDE space exists independently**
    - of the knowledge canvas space. Cate (`cero-ai.com`) is an infinite canvas IDE — editor panels, terminals, browser previews as spatial nodes. MIT licensed, Electron + Monaco + xterm.js.
    - Worth revisiting for the dev environment context. Zellij is the terminal-multiplexer equivalent worth exploring separately.


---

## Open Questions

- Does Advanced Canvas register commands that should be mapped in the hotkeys block? A dedicated keybindings session is planned — flag this for inclusion.

- Will Obsidian ship a default folder setting for Canvas and Bases? Track the open feature requests. When landed, the pattern will mirror the existing `app.newFileLocation` declaration.

- AFFiNE self-hosting: does the desktop app support pointing to a self-hosted instance the way Penpot does? Deferred to the dedicated AFFiNE session.

- Logseq self-hosting: is "self-hosting" a sync server or a full server deployment? Deferred to the dedicated Logseq session.


---

## Next Session

Two parallel tracks queued:

1. **Keybindings session**
    - full `hotkeys` block for Obsidian: core plugin commands, canvas commands, Advanced Canvas commands, and community plugin commands. 
    - Goal is a complete, deliberate keyboard map across the entire vault workflow.
    
3. **AFFiNE self-hosting**
    - use the prepared prompt template. 
    - Cover Docker Compose deployment, Caddy reverse proxy at `affine.local`, desktop app instance configuration, theming, and the `modules/apps/productivity/affine.nix` HM declaration.
    
5. **Logseq self-hosting**
    - same treatment via prepared prompt template.
    

---

<!-- 
Commit range (fill in after session): 
cypher-os: [short hash] → [short hash] 
-->