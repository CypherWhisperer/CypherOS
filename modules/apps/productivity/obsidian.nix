# modules/apps/productivity/obsidian.nix
#
# Declarative Obsidian configuration via Home Manager's programs.obsidian module.
#
# ARCHITECTURE
# ─────────────
# HM writes symlinks into <vault>/.obsidian/ from the Nix store. Obsidian cannot
# write back to those files at runtime — any plugin that persists to data.json must
# have its settings declared here under `settings` (mapped to its data.json).
#
# Any plugin you want active MUST be declared here.
# Do not mix declarative and manual plugin management for the same vault.
#
# COMMUNITY PLUGINS
# ──────────────────
# communityPlugins accepts a list of Nix derivations (packages), not plain strings.
# Each plugin is a stdenv.mkDerivation that fetches the plugin source from GitHub.
# There is no pkgs.obsidianPlugins.* attribute set in nixpkgs — plugins are
# defined locally as callPackage expressions in modules/apps/productivity/obsidian-plugins/.
#
# CATPPUCCIN THEMING
# ───────────────────
# catppuccin/nix does NOT support Obsidian — there is no catppuccin.obsidian option.
# The catppuccin/obsidian port is an Obsidian community theme, distributed through
# Obsidian's own theme marketplace. Declarative setup is done via:
#   1. defaultSettings.appearance.cssTheme = "Catppuccin";   — selects the theme
#   2. defaultSettings.themes = [ (pkgs.callPackage ./obsidian-plugins/catppuccin.nix {}) ];
#   3. The Style Settings plugin declared in communityPlugins with its data.json settings.
#      Without Style Settings, the Catppuccin flavor/accent panel is empty.

{
  config,
  pkgs,
  lib,
  ...
}:

let

  # ── Plugin helper ────────────────────────────────────────────────────────────
  # Inline mkDerivation for small plugins. For larger ones, move to a
  # separate file under obsidian-plugins/ and use pkgs.callPackage.
  mkPlugin =
    {
      pname,
      version,
      owner,
      repo,
      rev ? version,
      hash,
      extraInstallPhase ? "",
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchFromGitHub {
        inherit
          owner
          repo
          rev
          hash
          ;
      };
      dontBuild = true;
      installPhase = ''
        mkdir -p $out
        cp manifest.json $out/
        [ -f main.js ]   && cp main.js   $out/
        [ -f styles.css ] && cp styles.css $out/
        ${extraInstallPhase}
      '';
    };

  # ── Theme helper ─────────────────────────────────────────────────────────────
  mkTheme =
    {
      pname,
      version,
      owner,
      repo,
      rev ? version,
      hash,
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchFromGitHub {
        inherit
          owner
          repo
          rev
          hash
          ;
      };
      dontBuild = true;
      installPhase = ''
        mkdir -p $out
        cp manifest.json $out/
        [ -f theme.css ] && cp theme.css $out/
      '';
    };

  # ── Plugin packages ──────────────────────────────────────────────────────────
  # Update rev/hash after each nix flake update by running:
  #   nix-prefetch fetchFromGitHub --owner <owner> --repo <repo> --rev <tag>
  # or use `nix-prefetch-url --unpack` on the release tarball.
  #
  # WARNING: hash values below are PLACEHOLDERS — replace them before
  # attempting a build. They are marked with TODO.

  pluginStyleSettings = mkPlugin {
    pname = "obsidian-style-settings";
    version = "1.0.9";
    owner = "mgmeyers";
    repo = "obsidian-style-settings";
    rev = "1.0.9";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: replace
  };

  pluginObsidianGit = mkPlugin {
    pname = "obsidian-git";
    version = "2.32.1";
    owner = "Vinzent03";
    repo = "obsidian-git";
    rev = "2.32.1";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: replace
  };

  pluginDataview = mkPlugin {
    pname = "dataview";
    version = "0.5.67";
    owner = "blacksmithgu";
    repo = "obsidian-dataview";
    rev = "0.5.67";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: replace
  };

  pluginTemplater = mkPlugin {
    pname = "templater-obsidian";
    version = "2.9.0";
    owner = "SilentVoid13";
    repo = "Templater";
    rev = "2.9.0";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: replace
  };

  pluginRecentFiles = mkPlugin {
    pname = "recent-files-obsidian";
    version = "1.7.4";
    owner = "tgrosinger";
    repo = "recent-files-obsidian";
    rev = "1.7.4";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: replace
  };

  # ── Theme packages ───────────────────────────────────────────────────────────
  themeCatppuccin = mkTheme {
    pname = "catppuccin";
    version = "2.1.3";
    owner = "catppuccin";
    repo = "obsidian";
    rev = "v2.1.3";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: replace
  };

in

{
  config =
    lib.mkIf
      (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.obsidian.enable)
      {

        programs.obsidian = {
          enable = true;
          package = pkgs.obsidian;

          # defaultSettings apply to all vaults. Vault-specific settings.* override these.
          defaultSettings = {
            appearance = {
              # Catppuccin community theme.
              # cssTheme must exactly match the theme's `name` field in manifest.json.
              "cssTheme" = "Catppuccin";

              # Font Management.
              # Note textFontFamily — Obsidian has three separate font slots: interface,
              # text (body), and monospace. If you only set two, the third resets
              # to system default.
              "interfaceFontFamily" = "Courier"; # UI font
              "monospaceFontFamily" = "Courier"; # code/monospace font
              "textFontFamily" = "Courier"; # reading/editor body font
              "baseFontSize" = 16; # default is 16

              # Theme mode. Obsidian respects the OS setting when set to false/unset;
              # force dark explicitly if you want to guarantee Mocha.
              # "theme" = "obsidian";  # "obsidian" = dark, "moonstone" = light
            };

            # ── App settings ───────────────────────────────────────────────────────
            app = {
              "readableLineLength" = true; # constrain line width in reading mode
              "showLineNumber" = false; # line numbers off — cleaner reading
              "defaultViewMode" = "source"; # source | preview | live-preview
              "livePreview" = true; # live preview in source mode
              "tabSize" = 2;
              "foldIndent" = true;
              "showFrontmatter" = false; # hide YAML frontmatter in reading mode
              "vimMode" = false; # toggle if you ever want Vim keybindings
            };

            # ── Core Plugins ────────────────────────────────────────────────────────
            # These are Obsidian's built-in plugins. All are enabled by default in
            # the HM module — listed explicitly here so you can comment out what
            # you don't use and have an auditable record.
            corePlugins = [
              "backlink" # shows which notes link to the current note
              "bases" # Obsidian's native database/property system (new in 1.8)
              "bookmarks" # pin notes, headings, searches to sidebar
              "canvas" # infinite canvas for visual note layouts
              "command-palette" # Ctrl+P quick command launcher
              "daily-notes" # one-note-per-day journaling / scratchpad
              "editor-status" # word/char count in status bar
              "file-explorer" # left-panel file tree
              "file-recovery" # snapshots — saves you from accidental deletions
              # "footnotes"
              "global-search" # full-text search across all notes
              "graph" # knowledge graph visualisation
              "markdown-importer"
              "note-composer" # merge/split/extract notes
              "outgoing-link" # panel showing links from current note
              "outline" # heading tree of current note
              "page-preview" # hover preview on internal links
              "properties"
              # "publish"
              # "random-note"
              "slash-command"
              "slides" # presentation mode for notes
              "switcher" # Ctrl+O quick note switcher
              # "sync"
              "tag-pane" # sidebar listing all tags
              "templates" # basic templating (use Templater plugin for power use)
              "webview" # render web content in notes (e.g. YouTube embeds)
              "word-count" # document word count in status bar
              "workspaces"
              "zk-prefixer"
            ];

            # ── Community Plugins ───────────────────────────────────────────────────
            # Find plugin IDs at: https://obsidian.md/plugins?search=<name>
            # nixpkgs packages: pkgs.obsidianPlugins.<camelCaseName>
            #
            # Style Settings — exposes Catppuccin theme accent/font controls. Install this FIRST; without it the Catppuccin theme options panel
            # Obsidian Git — auto-commit and push vault to a git remote.
            # Dataview — query your vault like a database using frontmatter. Tag notes with project/status/date and query them in dashboards.
            # Templater — advanced templating with dynamic content. Replaces the built-in Templates for anything non-trivial.
            # Various Complements — autocomplete for wikilinks, tags, and words.
            # Advanced Tables — sane table editing in Markdown.
            # Iconize — add icons to files and folders in the file explorer.
            # Recent Files — sidebar panel of recently opened notes.
            # Better Word Count — counts selection, respects code blocks.
            #
            # ── Community plugins ──────────────────────────────────────────────────
            # Each entry is either a bare derivation (pkg only) or a submodule:
            #   { pkg = <drv>; enable = true; settings = { ... }; }
            # `settings` maps directly to the plugin's .obsidian/plugins/<id>/data.json.
            #
            # HOW TO GET THE HASH for a new plugin:
            #   nix-prefetch fetchFromGitHub --owner <owner> --repo <repo> --rev <tag>
            # or temporarily set hash = lib.fakeHash and let the build fail —
            # the error output contains the correct hash.
            communityPlugins = [

              # Style Settings — REQUIRED for Catppuccin flavor/accent selection.
              # Without this, the Catppuccin options panel in Preferences → Appearance
              # is empty and the theme renders with its default palette only.
              {
                pkg = pluginStyleSettings;
                # settings here become data.json for the style-settings plugin.
                # These keys set Catppuccin Mocha with Mauve accent.
                # Inspect your vault's .obsidian/plugins/obsidian-style-settings/data.json
                # after manual configuration to derive the exact key names.
                settings = {
                  # Catppuccin flavor: latte | frappe | macchiato | mocha
                  "catppuccin@@flavor" = "mocha";
                  # Catppuccin accent color
                  "catppuccin@@accent" = "mauve";
                };
              }

              # Obsidian Git — auto-commit vault to a git remote.
              {
                pkg = pluginObsidianGit;
                settings = {
                  "autoSaveInterval" = 10; # commit every 10 minutes
                  "autoPushInterval" = 0; # 0 = push on each commit
                  "commitMessage" = "vault: auto-commit {{date}}";
                  "disablePopups" = false;
                  "showStatusBar" = true;
                };
              }

              # Dataview — query vault frontmatter like a database.
              {
                pkg = pluginDataview;
                settings = {
                  "enableDataviewJs" = true;
                  "enableInlineDataviewJs" = false; # enable only if you use DQL inline
                  "warnOnEmptyResult" = false;
                  "defaultDateFormat" = "dd/MM/yyyy";
                  "defaultDateTimeFormat" = "HH:mm - dd/MM/yyyy";
                };
              }

              # Templater — advanced dynamic templating.
              # Supersedes the built-in Templates plugin for anything non-trivial.
              {
                pkg = pluginTemplater;
                settings = {
                  "trigger_on_file_creation" = false;
                  "auto_jump_to_cursor" = true;
                  "templates_folder" = "TEMPLATES"; # adjust to your vault layout
                };
              }

              # Recent Files — sidebar panel of recently opened notes.
              pluginRecentFiles # bare derivation — no settings needed
            ];

            # ── Themes ─────────────────────────────────────────────────────────────
            # Declares themes available in Obsidian's Appearance → Themes list.
            # `cssTheme` above selects which one is active.
            themes = [ themeCatppuccin ];

            # ── CSS snippets ───────────────────────────────────────────────────────
            # Inline snippets (text =) or file references (source =). These are placed
            # in .obsidian/snippets/ and can be toggled in Appearance → CSS Snippets.
            cssSnippets = [
              {
                name = "stop-blinking-cursor";
                text = ''
                  /* Disable blinking cursor in editor */
                  .cm-cursorLayer { animation: none !important; }
                '';
              }
              # To add a file-based snippet:
              # { source = ./snippets/my-snippet.css; }
            ];

            # ── Hotkeys ────────────────────────────────────────────────────────────
            # Maps to hotkeys.json. Format: "plugin-id:command-id" = [ { modifiers = []; key = ""; } ];
            # An empty list removes the default binding for that command.
            hotkeys = {
              "command-palette:open" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "P";
                }
              ];
              "app:open-help" = [ ]; # remove default F1 binding
              "switcher:open" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "O";
                }
              ];
              "editor:swap-line-down" = [
                {
                  modifiers = [ "Alt" ];
                  key = "ArrowDown";
                }
              ];
              "editor:swap-line-up" = [
                {
                  modifiers = [ "Alt" ];
                  key = "ArrowUp";
                }
              ];
              "editor:toggle-bold" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "B";
                }
              ];
              "editor:toggle-italics" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "I";
                }
              ];
              "daily-notes:goto-today" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "T";
                }
              ];
            };
          };

          # ── Vault Declaration ────────────────────────────────────────────────────
          # `target` is relative to $HOME. The vault directory will be created by HM
          # if it doesn't exist. Your actual notes inside are never touched — only
          # the .obsidian/ subdirectory is managed.
          # notes, .git, .trash, and everything else are never modified.

          vaults = {
            # Vault name (the Nix attribute key) is arbitrary — it's just an identifier
            # within the HM module. The `target` is what actually matters: it's the path
            # relative to $HOME that HM will manage .obsidian/ inside.
            #
            # If you are coming from an already existing vault with hand-crafted .obsidian/ (appearance.json,
            # app.json, core-plugins.json, graph.json, workspace.json), switching to the
            # declarative module will OVERWRITE those files with HM-managed symlinks.
            # Back up .obsidian/ before your first `home-manager switch` with this enabled:
            #
            #   cp -r ~/PATH/TO/YOUR/VAULT/.obsidian \
            #          ~/PATH/TO/YOUR/VAULT/.obsidian.bak
            #
            # Then inspect the backed-up JSONs to port your existing appearance/app settings
            # into the `settings` block here if you want to preserve them declaratively.
            my-obsidian-notes = {
              target = "DATA/FILES/PROJECTS/PRIVATE/PERSONAL/MY_OBSIDIAN_NOTES";
              # vault-specific overrides — uncomment and adjust if this vault
              # should diverge from defaultSettings above.
              # settings.appearance.cssTheme = "Minimal";
              # settings.corePlugins = [ ... ];
            };
          };
        };
      };
}
