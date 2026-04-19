# modules/apps/obsidian.nix
#
# Declarative Obsidian configuration via Home Manager's programs.obsidian module.
#
# ARCHITECTURE NOTE:
# The module manages vault config by writing files into <vault>/.obsidian/.
# These files are symlinked from the Nix store, which means Obsidian cannot
# write back to them at runtime — plugins that try to persist settings to
# their data.json will fail silently unless you declare those settings here.
#
# IMPORTANT: Because the module unconditionally overwrites plugin lists,
# any plugin you want active MUST be declared here. Don't mix declarative
# and manual plugin management for the same vault.

{ config, pkgs, lib, ... }:

{
  options.cypher-os.apps.productivity.obsidian.enable = lib.mkEnableOption "Obsidian Desktop App";

  config = lib.mkIf config.cypher-os.apps.productivity.obsidian.enable {

    programs.obsidian = {
      enable  = true;
      package = pkgs.obsidian;

      # defaultSettings apply to all vaults. Vault-specific settings.* override these.
      defaultSettings = {

        # ── Core Plugins ────────────────────────────────────────────────────────
        # These are Obsidian's built-in plugins. All are enabled by default in
        # the HM module — listed explicitly here so you can comment out what
        # you don't use and have an auditable record.
        corePlugins = [
          "backlink"         # shows which notes link to the current note
          "bases"            # Obsidian's native database/property system (new in 1.8)
          "bookmarks"        # pin notes, headings, searches to sidebar
          "canvas"           # infinite canvas for visual note layouts
          "command-palette"  # Ctrl+P quick command launcher
          "daily-notes"      # one-note-per-day journaling / scratchpad
          "editor-status"    # word/char count in status bar
          "file-explorer"    # left-panel file tree
          "file-recovery"    # snapshots — saves you from accidental deletions
          "global-search"    # full-text search across all notes
          "graph"            # knowledge graph visualisation
          "note-composer"    # merge/split/extract notes
          "outgoing-link"    # panel showing links from current note
          "outline"          # heading tree of current note
          "page-preview"     # hover preview on internal links
          "switcher"         # Ctrl+O quick note switcher
          "tag-pane"         # sidebar listing all tags
          "templates"        # basic templating (use Templater plugin for power use)
          "word-count"       # document word count in status bar
        ];

        # ── Community Plugins ───────────────────────────────────────────────────
        # Each entry requires `name` (the plugin ID as it appears in
        # .obsidian/community-plugins.json) and `pkg` (the nixpkgs package).
        # Optional: `enable = false` to install but leave disabled.
        # Optional: `settings = { ... }` to declaratively set data.json config.
        #
        # Find plugin IDs at: https://obsidian.md/plugins?search=<name>
        # nixpkgs packages: pkgs.obsidianPlugins.<camelCaseName>

        # When obsidianPlugins drops in nixpkgs, re-enable
        # this block and migrate. Until then, HM only manages corePlugins and the vault
        # path — community plugins are outside its scope.

        # communityPlugins = [

          # Style Settings — exposes Catppuccin theme accent/font controls.
          # Install this FIRST; without it the Catppuccin theme options panel
          # in Obsidian Settings → Appearance is empty.
          # {
            # name = "obsidian-style-settings";
            # pkg  = pkgs.obsidianPlugins.obsidian-style-settings;
          # }

          # Obsidian Git — auto-commit and push vault to a git remote.
          # Pairs with your existing git workflow. Configure remote in settings.
          # {
            # name = "obsidian-git";
            # pkg  = pkgs.obsidianPlugins.obsidian-git;
            # Optional: declarative settings (maps to data.json)
            # settings = {
            #   autoSaveInterval     = 10;  # commit every 10 minutes
            #   autoPushInterval     = 0;   # push on each commit
            #   commitMessage        = "vault: auto-commit {{date}}";
            #   disablePopups        = false;
            # };
          # }

          # Dataview — query your vault like a database using frontmatter.
          # Tag notes with project/status/date and query them in dashboards.
          # {
            # name = "dataview";
            # pkg  = pkgs.obsidianPlugins.dataview;
          # }

          # Templater — advanced templating with dynamic content.
          # Replaces the built-in Templates for anything non-trivial.
          # {
            # name = "templater-obsidian";
            # pkg  = pkgs.obsidianPlugins.templater-obsidian;
          # }

          # Various Complements — autocomplete for wikilinks, tags, and words.
          # {
            # name = "various-complements";
            # pkg  = pkgs.obsidianPlugins.various-complements;
          # }

          # Advanced Tables — sane table editing in Markdown.
          # {
            # name = "table-editor-obsidian";
            # pkg  = pkgs.obsidianPlugins.table-editor-obsidian;
          # }

          # Iconize — add icons to files and folders in the file explorer.
          # {
            # name = "obsidian-icon-folder";
            # pkg  = pkgs.obsidianPlugins.obsidian-icon-folder;
          # }

          # Recent Files — sidebar panel of recently opened notes.
          # {
            # name = "recent-files-obsidian";
            # pkg  = pkgs.obsidianPlugins.recent-files-obsidian;
          # }

          # Better Word Count — counts selection, respects code blocks.
          # {
            # name = "better-word-count";
            # pkg  = pkgs.obsidianPlugins.better-word-count;
          # }
        # ];
      };

      # ── Vault Declaration ────────────────────────────────────────────────────
      # `target` is relative to $HOME. The vault directory will be created by HM
      # if it doesn't exist. Your actual notes inside are never touched — only
      # the .obsidian/ subdirectory is managed.
      vaults = {
        # Vault name (the Nix attribute key) is arbitrary — it's just an identifier
        # within the HM module. The `target` is what actually matters: it's the path
        # relative to $HOME that HM will manage .obsidian/ inside.
        #
        # IMPORTANT: HM only touches <vault>/.obsidian/ — your notes, .git, .trash,
        # and everything else inside your vault are never modified.
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
          # vault-specific overrides go here if you ever need them
          # settings.corePlugins = [ ... ]; # overrides defaultSettings for this vault only
        };
      };
    };
  };
}
