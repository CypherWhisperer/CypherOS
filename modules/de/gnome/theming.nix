# modules/de/gnome/theming.nix
#
# GNOME theming: GTK theme, cursor, fonts, and libadwaita (GTK4) assets.
#
# GNOME theming: GTK3/GTK4/libadwaita theming via Fausto-Korpsvart's
# Catppuccin GTK Theme (https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme),
# plus cursor, fonts, and dconf accent settings.
#
# Why Fausto-Korpsvart instead of pkgs.catppuccin-gtk?
#   The nixpkgs catppuccin-gtk package (upstream: catppuccin/gtk) has been archived.
#
#   Fausto-Korpsvart's port is actively maintained, GNOME-focused, and crucially
#   overrides libadwaita's CSS custom properties (--accent-bg-color, etc.) so that
#   GTK4/libadwaita apps receive true Catppuccin colours — not just a dark fallback.
#
# Sources:
#   https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ─────────────────────────────────────────────────────────────────────────
  # CATPPUCCIN THEME CONFIGURATION: OLDSCHOOL
  # ─────────────────────────────────────────────────────────────────────────
  # Valid accents: rosewater flamingo pink mauve red maroon peach yellow
  #               green teal sky sapphire blue lavender
  # ctpAccent = "mauve";
  # ctpVariant = "mocha"; # ← latte | frappe | macchiato | mocha
  # ctpSize = "standard"; # ← standard | compact

  # The exact directory name the catppuccin-gtk package installs under
  # /share/themes/.
  # ctpThemeName = "Catppuccin-${lib.strings.toUpper (lib.strings.substring 0 1 ctpVariant)}${
  #   lib.strings.substring 1 (-1) ctpVariant
  # }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpSize)}${
  #   lib.strings.substring 1 (-1) ctpSize
  # }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpAccent)}${
  #   lib.strings.substring 1 (-1) ctpAccent
  # }-Dark";

  # The overridden package, referenced by gtk.theme.package and home.file sources
  # ctpGtkPkg = pkgs.catppuccin-gtk.override {
  #   accents = [ ctpAccent ];
  #   size = ctpSize;
  #   tweaks = [ "normal" ]; # normal = standard window buttons (max/min/close)
  #   variant = ctpVariant;
  # };

  # ─────────────────────────────────────────────────────────────────────────
  # CATPPUCCIN THEME CONFIGURATION: NEW SCHOOL
  # ─────────────────────────────────────────────────────────────────────────
  # ─────────────────────────────────────────────────────────────────────────
  # THEME PARAMETERS
  # Accent maps to Fausto-Korpsvart's --theme flag.
  # Valid accents: default|purple|pink|red|orange|yellow|green|teal|grey
  # "purple" is the closest available to Catppuccin's mauve.
  # ─────────────────────────────────────────────────────────────────────────
  fkAccent = "purple"; # → closest to Catppuccin mauve
  fkVariant = "mocha"; # → passed via --tweaks (frappe|macchiato; mocha is default)
  fkColor = "dark"; # → --color dark
  fkSize = "standard"; # → --size standard|compact

  # The theme name as installed by the script. Fausto-Korpsvart's install.sh
  # produces a directory named: Catppuccin-<Accent>-<Size> inside the dest.
  # With --color dark the suffix becomes "Dark":
  #
  #   Catppuccin-Purple-Standard (contains both light and dark subdirs inside,
  #   but for gtk3 we reference the Dark variant name that tweaks/GNOME expects).
  #
  # Confirmed naming from install.sh source:
  #   theme_name="Catppuccin${theme_accent:-}${theme_size:-}"
  #   → "Catppuccin-Purple-Standard" for purple + standard
  #
  # The GTK3 theme directory name is: "${theme_name}-Dark"
  fkThemeName = "Catppuccin-Purple-Standard-Dark";

  # ─────────────────────────────────────────────────────────────────────────
  # DERIVATION — compile Fausto-Korpsvart theme from source
  # Requires sassc and gtk-engine-murrine at build time.
  # The install script writes to --dest; we capture that as $out/share/themes.
  # ─────────────────────────────────────────────────────────────────────────
  fkGtkPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "catppuccin-gtk-fausto-${fkVariant}-${fkAccent}";
    version = "unstable-2025";

    src = pkgs.fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Catppuccin-GTK-Theme";
      # Pin to a specific commit for reproducibility.
      # Update this rev + hash after verifying a new upstream commit.
      rev = "HEAD";
      # replace accordingly. e.g:
      # nix-prefetch-url --unpack https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme/archive/HEAD.tar.gz
      hash = "sha256-WV9uMOd88GR8i77PEr1UyJFacIP1tXu1p9uDVxfYy6M=";
    };

    nativeBuildInputs = with pkgs; [
      sassc # SCSS compiler — required by install.sh
      gtk-engine-murrine # GTK2/3 Murrine engine — required for correct GTK3 rendering
      gnome-themes-extra # Provides Adwaita base assets relied on by the theme
      glib # gsettings — used internally by install.sh
      bc # arithmetic used in install.sh
    ];

    installPhase = ''
      runHook preInstall

      # install.sh expects a writable HOME for temporary files
      export HOME=$(mktemp -d)

      mkdir -p $out/share/themes

      bash install.sh \
        --dest    "$out/share/themes" \
        --name    "Catppuccin" \
        --theme   "${fkAccent}" \
        --color   "${fkColor}" \
        --size    "${fkSize}" \
        --libadwaita

      # --libadwaita symlinks gtk-4.0 into $HOME/.config/gtk-4.0 — we don't
      # want that side-effect in a Nix build. The gtk-4.0 assets inside
      # $out/share/themes/*/gtk-4.0/ are what we reference below via home.file.

      runHook postInstall
    '';

    meta = {
      description = "Catppuccin GTK theme by Fausto-Korpsvart (Mocha/Purple, libadwaita-aware)";
      homepage = "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.linux;
    };
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
    #
    # ─────────────────────────────────────────────────────────────────────────────
    # GTK3 THEME
    # Applies to GTK3 apps (Nautilus chrome, legacy GNOME apps, LibreOffice via
    # SAL_USE_VCLPLUGIN=gtk3).
    # ─────────────────────────────────────────────────────────────────────────────
    gtk = {
      enable = true;
      theme = {
        # GTK3Dark variant -> "adw-gtk3-dark"
        # Old School -> "ctpThemeName"
        name = fkThemeName;

        # GTK3 -> pkgs.adw-gtk3
        # Old School -> "ctpGtkPkg"
        package = fkGtkPkg;
      };

      # ─────────────────────────────────────────────────────────────────────────────
      # SILENCE HOME MANAGER 26.05 EVALUATION WARNING.
      # ─────────────────────────────────────────────────────────────────────────────
      # GTK4 theme — set to match GTK3 to silence the HM 26.05 warning and keep
      # legacy behaviour. HM writes gtk-4.0/gtk.css automatically from this package.
      # Do NOT also declare home.file."gtk-4.0/gtk.css" — that causes a conflict
      gtk4.theme = {
        # Old School: -> ctpThemeName
        name = fkThemeName;

        # Old School: -> ctpGtkPkg
        package = fkGtkPkg;
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
    #
    # NOTE: the xdg.configFile."gtk-4/assets" below achieves the same thing as the
    #       lines above. Together they conflict.

    # gtk.css and gtk-dark.css are handled by HM's gtk module automatically
    # (visible as absolute-path entries in home.file output).
    # Only assets/ needs an explicit declaration — the gtk module doesn't copy it.
    #
    # ─────────────────────────────────────────────────────────────────────────────
    # HM's gtk module writes gtk.css and gtk-dark.css automatically.
    # Only assets/ needs an explicit declaration — the module doesn't copy it.
    # ─────────────────────────────────────────────────────────────────────────────
    xdg.configFile."gtk-4.0/assets" = {
      recursive = true;
      # Old School:
      #source = "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/assets";

      source = "${fkGtkPkg}/share/themes/${fkThemeName}/gtk-4.0/assets";
    };

    # ─────────────────────────────────────────────────────────────────────────────
    # DCONF — interface settings
    # ─────────────────────────────────────────────────────────────────────────────
    dconf.settings = {
      # Layer 2: GNOME Shell theme (top bar, overview, notifications, dash).
      "org/gnome/shell/extensions/user-theme" = {
        # Old School: -> ctpThemeName
        name = fkThemeName;
      };

      # ── Interface ──────────────────────────────────────────────────────────
      "org/gnome/desktop/interface" = {
        # gtk-theme tells GTK3 apps which theme to load.
        # Must match gtk.theme.name exactly.

        # ADWAITA -> "adw-gtk3";
        # Old School: -> ctpThemeName
        gtk-theme = fkThemeName;

        color-scheme = "prefer-dark"; # drives the dark mode toggle

        # GNOME 47+ native accent-color — fallback for apps that read this key
        # directly instead of the GTK CSS. "purple" is the closest built-in
        # to Catppuccin mauve. Does not override libadwaita CSS; both work together.
        accent-color = "purple";

        # letting catppuccin/nix handle the icon and cursor themes globally
        # for consistency across DEs and apps.
        #
        #icon-theme = "Papirus-Dark"; # ADWAITA -> "Adwaita";

        # cursor-theme = "Catppuccin Mocha Dark"; # ADWAITA -> "Adwaita";
        cursor-theme = "Adwaita";
        cursor-size = 24;
      };

      # Enforde Dark Mode at XDG portal level
      "org/freedesktop/appearance" = {
        color-scheme = lib.hm.gvariant.mkUint32 1; # the value 1 does the magic
      };
    };
  };
}
