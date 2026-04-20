# modules/apps/ghostty.nix
#
# Home Manager module for Ghostty terminal emulator.
#
# Ghostty is minimal by design — it ships with sensible defaults for nearly
# everything. This module captures only the settings you actually changed.
# The extensive template comments from the generated config file are dropped —
# they belong in the Ghostty docs, not in a managed config.
#
# programs.ghostty in Home Manager writes to:
#   $XDG_CONFIG_HOME/ghostty/config
# Under XDG profile separation this resolves per-DE correctly.

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.apps.terminal.enable &&
    config.cypher-os.apps.terminal.ghostty.enable ) {

    programs.ghostty = {
      enable = true;

      themes = {
        catppuccin-mocha = {
          background = "1e1e2e";
          cursor-color = "f5e0dc";
          foreground = "cdd6f4";
          palette = [
            "0=#45475a"
            "1=#f38ba8"
            "2=#a6e3a1"
            "3=#f9e2af"
            "4=#89b4fa"
            "5=#f5c2e7"
            "6=#94e2d5"
            "7=#bac2de"
            "8=#585b70"
            "9=#f38ba8"
            "10=#a6e3a1"
            "11=#f9e2af"
            "12=#89b4fa"
            "13=#f5c2e7"
            "14=#94e2d5"
            "15=#a6adc8"
          ];
          selection-background = "353749";
          selection-foreground = "cdd6f4";
        };
      };

      settings = {
        # ── Font ──────────────────────────────────────────────────────────────
        # Matching kitty's font for consistency across terminals.
        # Ghostty will find this from the fonts installed by Home Manager.
        font-family = "CaskaydiaCove Nerd Font Mono";
        font-size   = 13;

        # ── Window ────────────────────────────────────────────────────────────
        window-padding-x = 1;
        window-padding-y = 1;

        # ── Theme ─────────────────────────────────────────────────────────────
        theme = "catppuccin-mocha";
        #theme = "TokyoNight Storm";

        # ── Shell Integration ──────────────────────────────────────────────────
        # Ghostty's shell integration adds prompt markers, semantic zones, and
        # allows Ghostty to know when a command is running vs idle. It's opt-in
        # and works with zsh automatically when enabled here.
        shell-integration = "zsh";

        # ── Cursor ────────────────────────────────────────────────────────────
        cursor-style            = "block";
        cursor-style-blink      = true;

        # ── Copy on Select ────────────────────────────────────────────────────
        # Automatically copy selected text to the clipboard. Useful when working
        # across kitty and ghostty — consistent behaviour.
        copy-on-select = true;
      };
    };
  };
}
