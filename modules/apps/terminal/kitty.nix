# modules/apps/kitty.nix
#
# Home Manager module for Kitty terminal emulator.
#
# WHAT THIS FILE OWNS:
#   - All kitty settings (font, padding, cursor, bell, colors)
#   - Tokyo Night color scheme (inlined)
#   - Tab bar configuration
#
# WHAT THIS FILE DOES NOT OWN:
#   - The CaskaydiaCove Nerd Font package — declared in gnome.nix (or common/)
#   - Kitty package itself — programs.kitty.enable pulls it in automatically


{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.apps.terminal.enable &&
    config.cypher-os.apps.terminal.kitty.enable ) {

    programs.kitty = {
      enable = true;

      # ── Font ────────────────────────────────────────────────────────────────
      # CaskaydiaCove Nerd Font Mono: your existing font, kept for continuity.
      # The package nerd-fonts.caskaydia-cove must be in home.packages.
      # bold/italic/bold_italic are resolved automatically from the font family.
      font = {
        name = "CaskaydiaCove Nerd Font Mono";
        size = 10;
      };

      # ── Settings ─────────────────────────────────────────────────────────────
      # programs.kitty.settings maps directly to kitty.conf key = value pairs.
      settings = {
        # ── Cursor ──────────────────────────────────────────────────────────
        cursor_trail          = 1;     # animated cursor trail (your setup had this)
        cursor                = "#c0caf5";
        cursor_text_color     = "#1a1b26";

        # ── Window ──────────────────────────────────────────────────────────
        window_padding_width  = 1;    # PADDING

        # ── Bell ────────────────────────────────────────────────────────────
        enable_audio_bell     = false; # no bell — matches both your configs

        # ── URL ─────────────────────────────────────────────────────────────
        url_color             = "#9ece6a";
        url_style             = "curly";

        # ── Selection ───────────────────────────────────────────────────────
        selection_foreground  = "none";
        selection_background  = "#28344a";

        # ── Window Borders ───────────────────────────────────────────────────
        active_border_color   = "#3d59a1";
        inactive_border_color = "#101014";
        bell_border_color     = "#e0af68";

        # ── Tab Bar ─────────────────────────────────────────────────────────
        tab_bar_style             = "fade";
        tab_fade                  = "1";
        active_tab_foreground     = "#3d59a1";
        active_tab_background     = "#16161e";
        active_tab_font_style     = "bold";
        inactive_tab_foreground   = "#787c99";
        inactive_tab_background   = "#16161e";
        inactive_tab_font_style   = "bold";
        tab_bar_background        = "#101014";

        # ── Tokyo Night: 16-Color Palette ────────────────────────────────────
        # These are the exact colors from our theme.conf — Tokyo Night Storm/Night.
        foreground = "#a9b1d6";
        background = "#24283b";

        # Black
        color0  = "#414868";
        color8  = "#414868";
        # Red
        color1  = "#f7768e";
        color9  = "#f7768e";
        # Green
        color2  = "#73daca";
        color10 = "#73daca";
        # Yellow
        color3  = "#e0af68";
        color11 = "#e0af68";
        # Blue
        color4  = "#7aa2f7";
        color12 = "#7aa2f7";
        # Magenta
        color5  = "#bb9af7";
        color13 = "#bb9af7";
        # Cyan
        color6  = "#7dcfff";
        color14 = "#7dcfff";
        # White
        color7  = "#c0caf5";
        color15 = "#c0caf5";
      };
    };
  };
}
