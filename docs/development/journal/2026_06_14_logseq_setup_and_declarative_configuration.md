# [2026_06_14] Logseq Setup and Declarative Configuration

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-06-14 
**Duration:** ~2–3 hours
**Repos touched:** `cypher-os`
**Modules touched:** 
    `modules/apps/productivity/logseq.nix`
    `modules/apps/productivity/options.nix`
    `hosts/nixos/configuration.nix`
**Phase:** 

---

## What I Worked On

Researched, deployed, and declaratively configured Logseq as the knowledge base tool on CypherOS.

This was not just an install — _it required working through a non-trivial set of questions about what "self-hosting" even means for a local-first tool, how Logseq's architecture actually works, and then fighting through a chain of packaging failures before arriving at a working, themed setup._

---

## What Got Done

- Clarified the architecture: Logseq is local-first; "self-hosting" for the file-based version means choosing a sync layer (Syncthing), not deploying a server. There is no Logseq application server to run — the data is a directory of Markdown files.
  
- Clarified the DB version vs file-based version distinction. DB version is still beta with data loss risk and no nixpkgs package. Stayed on file-based.
  
- Registered `cypher-os.apps.productivity.logseq.enable` in `options.nix`.
  
- Wrote `logseq.nix` _(Home Manager module)_ covering: package install, graph directory sentinel, declarative `config.edn`, and Catppuccin Mocha theming via `home.activation`.
  
- Enabled the module in `modules/profile/default.nix`.
- Resolved the `permittedInsecurePackages` issue _(see below)._
- Resolved the Catppuccin CSS not loading _(see below)._
- Confirmed the app launches cleanly with dark mode and Catppuccin Mocha applied.

---

## Key Decisions Made

1. **No system module.**
    - Unlike Penpot, Logseq has no local service, no `/etc/hosts` entry, and no CA cert to trust.
    - `logseq.nix` is a Home Manager-only module. `logseq-system.nix` does not exist and is not needed.
      
2. **`config.edn` as `home.file`, `custom.css` via `home.activation`.**
    - These two files look like the same problem but are not.
    - `config.edn` is read-only from Logseq's perspective — _it reads on startup and never writes back._ A Nix store symlink is safe. 
      
    - `custom.css` is watched by Logseq's CSS engine at runtime, which cannot follow Nix store symlinks correctly.
    - The fix was to copy it as a real mutable file via home.activation with `cp --remove-destination and chmod 644`. 
    - The `--remove-destination` flag is load-bearing — _without it, cp fails to overwrite the previously-placed read-only store copy._
      
3. **`permittedInsecurePackages` over Electron override.**
    - The obvious approach — _override the Electron version in the derivation_ — was tried exhaustively.
    - The attribute name had changed from `electron_27` _(as documented on the NixOS Wiki)_ to `electron_39` in the current nixpkgs revision.
    - After correcting that, `electron_34` and `electron_36` had been removed from nixpkgs; `electron_37` and `electron_38` were also marked insecure.
    - The only viable path is allowing `"electron-39.8.10"` explicitly in `nixpkgs.config.permittedInsecurePackages`. This is a known compromise tracked at nixpkgs#528213.
      
4. **Catppuccin Mocha via local CSS, not `:custom-css-url`.**
    - The Catppuccin theme can be loaded via a CDN URL in `config.edn`, but that introduces an outbound network dependency at every Logseq launch.
    - The CSS file is downloaded once, committed to the repo at `modules/apps/productivity/config/catppuccin-mocha.css`, and copied into place by the activation script.
    - Theming works fully offline.
      
---

## Where I Got Stuck

1. **The Electron version chase.**
    - This consumed a disproportionate amount of the session. 
    - The NixOS Wiki documentation was stale — _it still referenced `electron_27` as the override attribute._ The actual attribute in the current nixpkgs is electron_39. 
    - After correcting that, the lower Electron versions that should have been available as substitutes had either been removed or were themselves flagged insecure. 
    - The error messages across the sequence were: "unexpected argument electron_27" → "unexpected argument electron_34" (removed) → "unexpected argument electron_36" (removed) → electron_37 insecure → electron_38 insecure. 
    - Abandoning the override path entirely and going with `permittedInsecurePackages` was the correct call, but it took working through all the dead ends to confirm it.
      
2. **The `permittedInsecurePackages` typo.**
    - After deciding on the `permittedInsecurePackages` path, the first attempt used `"electron_39.8.10"` _(underscore after `electron`)_ instead of `"electron-39.8.10"` (hyphen). 
    - nixpkgs keys on the exact package name string including the hyphen separator. 
    - The error was identical to the original insecure-package error, so there was no indication a typo was the cause — _it just looked like the allow-list wasn't working at all._
      
3. **Catppuccin not loading.**
    - The module built and Logseq launched, but the theme was the default dark — _no Catppuccin colours._
    - Investigation via `ls -la` revealed both `config.edn` and `custom.css` were Nix store symlinks. 
    - Logseq was silently failing to load the CSS through the symlink. 
    - The distinction between "Logseq reads this once at startup" (config.edn → symlink fine) and "Logseq watches this file at runtime" (custom.css → symlink not fine) was the key insight.
      
---

## What I Learned

1. **Logseq's architecture is genuinely different from every other tool in the sovereign stack.** 
    - Penpot, n8n, Excalidraw — _all of these are server-client architectures where self-hosting means running a server._
    - Logseq's self-hosting story is the filesystem. The "server" is whatever syncs your files.
    - This makes it simpler in some ways _(no Docker Compose, no Caddy entry, no CA trust)_ and requires a different mental model.
    
2. **`home.file` and `home.activation` are not interchangeable.** 
    - Both write files into the home directory, but `home.file` produces a Nix store symlink and `home.activation` produces whatever the shell command produces.
    - For files that applications only read, symlinks are fine. 
    - For files that applications watch, write to, or resolve via filesystem watchers, a real file is required. 
    - The failure mode is silent — the application just ignores the file or loads a fallback, and there's no error to point at.
      
3. **NixOS Wiki documentation lags reality for fast-moving packages.** 
    - The Logseq wiki page still documents `electron_27` as the override attribute. 
    - The actual package has been through at least two Electron major version bumps since that was written.
    - For packaging workarounds, check the actual `package.nix` in nixpkgs (or trust the error message's "did you mean" suggestion) rather than the wiki.

---

## Open Questions

- Syncthing setup for Android sync is not done. When multi-device access becomes a priority, this needs its own module — _likely under a dedicated networking or sync module group rather than inside `modules/apps/productivity/`._
- The NixOS Wiki mentions the DB version's RTC sync server can be self-hosted, but requires compiling a patched Logseq from source and depends on AWS Cognito for auth. Not pursued — _the file-based version covers the use case._ Worth revisiting if the DB version stabilises and nixpkgs packages it.
- `electron-39.8.10` is EOL. nixpkgs#528213 tracks the upstream fix. When Logseq ships a release with a supported Electron version, the `permittedInsecurePackages` entry and its comment in `configuration.nix` should be removed.

---

## Next Session

Logseq is functional. The immediate follow-on is actually using it — _establishing the graph structure, journal conventions, and page templates that will make it useful as a knowledge base rather than an empty canvas._

That's a usage question, not an infrastructure question.

Infrastructure-wise: the three queued items from the Penpot session _(Caddyfile syntax highlighting, git-versioned component library, `systemd-resolved` stub zone migration for ADR-004)_ remain open.

---

<!-- Commit range (fill in after session): 
cypher-os: [short hash] → [short hash]
-->