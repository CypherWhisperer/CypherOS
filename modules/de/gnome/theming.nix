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
  # Single source of truth for the theme variant. Change `ctpAccent` here
  # and every downstream reference — gtk.theme.name, dconf shell theme key,
  # gtk-4.0 symlinks — updates automatically.
  #
  # Valid accents: rosewater flamingo pink mauve red maroon peach yellow
  #               green teal sky sapphire blue lavender
  ctpAccent = "mauve"; # ← your accent pick
  ctpVariant = "mocha"; # ← latte | frappe | macchiato | mocha
  ctpSize = "standard"; # ← standard | compact

  # The exact directory name the catppuccin-gtk package installs under
  # /share/themes/. This string must match perfectly — it feeds gtk.theme.name,
  # the dconf shell theme key, and the gtk-4.0 symlink sources.
  # Pattern: Catppuccin-{Variant}-{Size}-{Accent}-Dark
  ctpThemeName = "Catppuccin-${lib.strings.toUpper (lib.strings.substring 0 1 ctpVariant)}${
    lib.strings.substring 1 (-1) ctpVariant
  }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpSize)}${
    lib.strings.substring 1 (-1) ctpSize
  }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpAccent)}${
    lib.strings.substring 1 (-1) ctpAccent
  }-Dark";
  # That lib.strings gymnastics just title-cases each segment. If you prefer
  # clarity over dynamism, you can hardcode it instead:
  # ctpThemeName = "Catppuccin-Mocha-Standard-Mauve-Dark";

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
    # The `gtk` Home Manager module writes:
    #   ~/.config/gtk-3.0/settings.ini
    #   ~/.config/gtk-4.0/settings.ini
    # GTK applications read these on launch to pick theme, icons, cursor, font.
    #
    # adw-gtk3: backports the libadwaita (GTK4) look to GTK3 apps, so older apps
    # look consistent with native GNOME 48 apps. Toggle to
    # "Adwaita" + pkgs.gnome.adwaita-icon-theme if you prefer pure classic look.
    #
    # Layer 1: GTK3 apps (Nautilus file browser widget chrome, most older GNOME apps)
    # Layer 3: GTK4/Libadwaita (Settings, Text Editor) — handled via home.file below
    #           because libadwaita ignores gtk.theme and reads ~/.config/gtk-4.0/gtk.css
    gtk = {
      enable = true;

      # gtk4.theme is intentionally omitted here.
      # The gtk HM module would write ~/.config/gtk-4.0/gtk.css automatically
      # if gtk4.theme is set, conflicting with our explicit home.file declarations
      # below that handle libadwaita theming. home.file wins for GTK4/libadwaita —
      # it writes the full CSS + assets that libadwaita actually reads at runtime.
      theme = {
        # ctpThemeName must exactly match the directory under /share/themes/
        # inside the catppuccin-gtk store path — the let binding above guarantees this.
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

      # Explicitly disable gtk4 theme management. On recent HM unstable, gtk.enable = true
      # with a theme set causes the gtk module to auto-generate ~/.config/gtk-4.0/gtk.css,
      # which conflicts with our explicit home.file declarations below that handle
      # libadwaita theming properly. Setting gtk4.extraConfig to empty and not declaring
      # gtk4.theme prevents HM from touching that path.
      gtk4.extraConfig = { };
    };

    # ─────────────────────────────────────────────────────────────────────────────
    # LAYER 3: LIBADWAITA (GTK4) THEMING
    # ─────────────────────────────────────────────────────────────────────────────
    # Libadwaita apps (GNOME Settings, Text Editor, Calculator, etc.) deliberately
    # ignore gtk.theme — they only read ~/.config/gtk-4.0/gtk.css at startup.
    # home.file places these symlinks into the profile on every HM switch, so the
    # CSS is always present before any app launches.
    #
    # `recursive = true` on the assets directory tells HM to recurse into the
    # source directory rather than symlinking the directory itself.
    #
    # xdg.configFile targets $XDG_CONFIG_HOME (~/.config/) using a separate HM
    # namespace from home.file, avoiding the collision with the absolute-path entry
    # the gtk module generates internally for gtk-4.0/gtk.css.

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
      # Requires the user-theme extension to be installed and enabled above.
      # The name here must match ctpThemeName — the catppuccin-gtk package installs
      # a gnome-shell/ subdirectory inside the theme folder, which this extension reads.
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
