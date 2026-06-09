# modules/de/gnome/theming.nix
#
# GNOME theming: GTK theme, cursor, fonts, and libadwaita (GTK4) assets.
#
# Owns the catppuccin theme let-bindings, gtk HM module configuration,
# and the xdg.configFile gtk-4.0/assets declaration.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ─────────────────────────────────────────────────────────────────────────
  # CATPPUCCIN THEME CONFIGURATION
  # ─────────────────────────────────────────────────────────────────────────
  # Valid accents: rosewater flamingo pink mauve red maroon peach yellow
  #               green teal sky sapphire blue lavender
  ctpAccent = "mauve";
  ctpVariant = "mocha"; # ← latte | frappe | macchiato | mocha
  ctpSize = "standard"; # ← standard | compact

  # The exact directory name the catppuccin-gtk package installs under
  # /share/themes/.
  ctpThemeName = "Catppuccin-${lib.strings.toUpper (lib.strings.substring 0 1 ctpVariant)}${
    lib.strings.substring 1 (-1) ctpVariant
  }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpSize)}${
    lib.strings.substring 1 (-1) ctpSize
  }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpAccent)}${
    lib.strings.substring 1 (-1) ctpAccent
  }-Dark";

  # The overridden package, referenced by gtk.theme.package and home.file sources
  ctpGtkPkg = pkgs.catppuccin-gtk.override {
    accents = [ ctpAccent ];
    size = ctpSize;
    tweaks = [ "normal" ]; # normal = standard window buttons (max/min/close)
    variant = ctpVariant;
  };

in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.cypher-os.de.gnome.enable {

    # ─────────────────────────────────────────────────────────────────────────────
    # GTK THEME, ICONS, CURSOR, FONTS
    # ─────────────────────────────────────────────────────────────────────────────
    # adw-gtk3: backports the libadwaita (GTK4) look to GTK3 apps, so older apps
    # look consistent with native GNOME apps. Toggle to
    # "Adwaita" + pkgs.gnome.adwaita-icon-theme if you prefer pure classic look.
    #
    # Layer 1: GTK3 apps (Nautilus file browser widget chrome, most older GNOME apps)
    # Layer 3: GTK4/Libadwaita (Settings, Text Editor) — handled via home.file below
    #           because libadwaita ignores gtk.theme and reads ~/.config/gtk-4.0/gtk.css
    gtk = {
      enable = true;
      theme = {
        name = ctpThemeName; # GTK3Dark variant -> "adw-gtk3-dark"
        package = ctpGtkPkg; # GTK3 -> pkgs.adw-gtk3
      };

      # Letting catppuccin/nix handle the icon and cursor themes globally for consistency across DEs and apps.
      #
      # iconTheme = {
      #   # catppuccin-papirus-folders: Papirus icon set with Catppuccin-coloured folders.
      #   # The accent here must be prefixed with "cat-mocha-" for the override to pick
      #   # the right folder colour set.
      #   name = "Papirus-Dark"; # ADWAITA -> "Adwaita"
      #   package = pkgs.catppuccin-papirus-folders.override {
      #     # ADWAITA -> pkgs.adwaita-icon-theme
      #     flavor = ctpVariant; # mocha
      #     accent = ctpAccent; # mauve
      #   };
      # };

      cursorTheme = {
        # catppuccin-cursors is an attribute set of pre-built cursor packages.
        # The attribute name is camelCase: mocha + Dark = mochaDark.
        # The cursor theme name string (what GNOME reads) is title-case with spaces:
        # "Catppuccin Mocha Dark" — confirmed from the nixpkgs package definition.

        # name = "Catppuccin Mocha Dark"; # ADWAITA -> "Adwaita";c
        # package = pkgs.catppuccin-cursors.mochaDark; # ADWAITA -> pkgs.adwaita-icon-theme;
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
      };

      font = {
        name = "Cantarell";
        size = 11;
      };

      gtk4.extraConfig = { };
    };

    # ─────────────────────────────────────────────────────────────────────────────
    # LAYER 3: LIBADWAITA (GTK4) THEMING
    # ─────────────────────────────────────────────────────────────────────────────
    # home.file.".config/gtk-4.0/gtk.css".source =
    # "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/gtk.css";
    #
    # home.file.".config/gtk-4.0/gtk-dark.css".source =
    # "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/gtk-dark.css";
    #
    # home.file.".config/gtk-4.0/assets" = {
    # recursive = true;
    # source    = "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/assets";
    # };

    # gtk.css and gtk-dark.css are handled by HM's gtk module automatically
    # (visible as absolute-path entries in home.file output).
    # Only assets/ needs an explicit declaration — the gtk module doesn't copy it.
    xdg.configFile."gtk-4.0/assets" = {
      recursive = true;
      source = "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/assets";
    };

    dconf.settings = {
      # Layer 2: GNOME Shell theme (top bar, overview, notifications, dash).
      "org/gnome/shell/extensions/user-theme" = {
        name = ctpThemeName;
      };

      # ── Interface ──────────────────────────────────────────────────────────
      "org/gnome/desktop/interface" = {
        # gtk-theme tells GTK3 apps which theme to load.
        # Must match gtk.theme.name exactly.
        gtk-theme = ctpThemeName; # ADWAITA -> "adw-gtk3";
      };
    };
  };
}
