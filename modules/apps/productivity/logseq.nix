# modules/apps/productivity/logseq-hm.nix
#
# Sync across devices (e.g., Android phone) is handled at the filesystem layer
# via Syncthing — not by Logseq itself. Syncthing is declared separately.
#
# This module:
#   1. Installs the Logseq desktop app (with Electron version override to
#      work around the nixpkgs insecure-electron marker on Logseq's pinned version)
#   2. Declares the graph base directory so it exists under ~/DATA/ for backups
#   3. Manages config.edn and custom.css declaratively via home.file
#
# Graph data lives at:
#   ~/DATA/FILES/DE_FILES/SHARED/APPS/logseq/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/graph/
#
# Logseq writes to the graph directory constantly — Home Manager manages only
# the logseq/ subdirectory config files, not the graph content itself.

{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.cypher-os.apps.productivity.logseq;

  # Override the pinned Electron version to avoid the insecure-package error.
  # Electron 34 has been tested and the app runs correctly; upstream issue tracked
  # at nixpkgs#528213. Revisit this override when nixpkgs updates Logseq's Electron pin.
  logseq-patched = pkgs.logseq.override {
    electron_27 = pkgs.electron_34; # attribute name reflects what logseq's derivation expects
  };

  graphBase = "${config.home.homeDirectory}/DATA/FILES/DE_FILES/SHARED/APPS/logseq/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/graph";

in
{
  config = lib.mkIf (config.cypher-os.apps.productivity.enable && cfg.enable) {

    home.packages = [ logseq-patched ];

    # ── Graph directory ────────────────────────────────────────────────────────
    # Ensure the graph directory exists. Logseq will populate it on first launch
    # when you open this path as a new graph.
    home.file."${graphBase}/.keep" = {
      text = "";
    };

    # ── config.edn ─────────────────────────────────────────────────────────────
    # Logseq reads logseq/config.edn inside the graph directory.
    # :custom-css-url is overridden by a local custom.css if present —
    # we use local CSS to avoid any outbound network dependency.
    home.file."${graphBase}/logseq/config.edn" = {
      text = ''
        {:meta/version 1

         ;; Preferred file format for new pages
         :preferred-format :markdown

         ;; Preferred workflow (todo or now)
         :preferred-workflow :todo

         ;; Journals directory
         :journals-directory "journals"

         ;; Pages directory
         :pages-directory "pages"

         ;; Hide these paths from the file tree
         :hidden []

         ;; Disable telemetry — Logseq respects this flag
         :telemetry-enabled false

         ;; Daily notes template name (set to your Logseq template name if you use one)
         ;; :default-templates {:journals ""}

         ;; Feature flags
         :feature/enable-block-timestamps? false
         :feature/enable-whiteboards? false
        }
      '';
    };

    # ── custom.css — Catppuccin Mocha ──────────────────────────────────────────
    # Logseq auto-loads logseq/custom.css from the graph directory.
    # Using a local file (not :custom-css-url) avoids any outbound request —
    # consistent with the privacy-first posture.
    #
    # Source: https://logseq.catppuccin.com/ctp-mocha.css
    # Pinned to a local copy so theming works fully offline.
    #
    # To update: curl -o logseq-catppuccin-mocha.css https://logseq.catppuccin.com/ctp-mocha.css
    # then embed it here or reference it via a path in the nix store.
    home.file."${graphBase}/logseq/custom.css" = {
      source = ./config/catppuccin-mocha.css;
    };
  };
}
