# modules/de/gnome.nix
#
# [NixOS]+ [Home Manager] module for the GNOME desktop environment.
#
# Home Manager module for GNOME desktop environment.
# Manages everything Gnome-specific: extensions, dconf settings, theming, fonts,
# the XDG profile launcher, and the gnome-specific packages
#
# WHAT THIS FILE OWNS:
#   - cypher-os.de.gnome.enable option declaration
#   - cypher-os.dm.gdm.enable option declaration
#   - GNOME Shell extensions (installed + enabled list)
#   - All dconf settings (keybindings, appearance, power, peripherals)
#   - GTK theme, icon theme, cursor, fonts
#   - The XDG profile launcher script (~/.local/bin/launch-gnome)
#   - GDM display manager (system-level, under config.cypher-os.dm.gdm.enable)
#
# WHAT THIS FILE DOES NOT OWN:
#   - User-space apps (brave, neovim, obsidian) → modules/apps/
#   - GDM (display manager)     → modules/dm/default.nix (cypher-os.dm.gdm.enable)
#   - System daemons            → NixOS: services.*
#   - Kernel / drivers          → NixOS: hardware.*
#
# Activated by setting:
#   cypher-os.de.gnome.enable = true   (in configuration.nix or profile module)

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
  # ══════════════════════════════════════════════════════════════════════════
  # OPTIONS — what this module exposes to the outside world
  # ══════════════════════════════════════════════════════════════════════════
  options.cypher-os.de.gnome = {
      enable = lib.mkEnableOption "GNOME desktop environment";
      # Future options slot in here:
      # extensions.enable = lib.mkEnableOption "GNOME Shell extensions";
      # theme.accent = lib.mkOption { type = lib.types.str; default = "mauve"; ... };
  };


  # ══════════════════════════════════════════════════════════════════════════
  # CONFIG — what this module does when its options are enabled
  # ══════════════════════════════════════════════════════════════════════════

  # ── GDM (system-level) ───────────────────────────────────────────────────
  # lib.mkIf reads the FINAL merged value of the option.
  # This block only activates if configuration.nix (or a profile module)
  # sets cypher-os.dm.gdm.enable = true.
  config = lib.mkIf config.cypher-os.de.gnome.enable {

    # desktopManager.gnome.enable pulls in gnome-shell, gnome-session,
    # gnome-control-center, nautilus, and the core GNOME session infrastructure.
    # It does NOT pull in every GNOME app — that's controlled separately below.
    services.desktopManager.gnome.enable = true;

    # ─────────────────────────────────────────────────────────────────────────────
    # GNOME BLOATWARE EXCLUSION
    # ─────────────────────────────────────────────────────────────────────────────
    # services.desktopManager.gnome.enable pulls in a default set of GNOME apps.
    # environment.gnome.excludePackages lets you surgically remove the ones you
    # don't want. This gives you a minimal GNOME — only what you explicitly
    # install via Home Manager, plus the essential shell infrastructure.
    #
    # Everything listed here would otherwise be installed system-wide automatically.
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour # first-run tour wizard — not needed
      yelp # GNOME help browser — documentation you'll never open
      totem # GNOME Videos — you use vlc
      gnome-maps # GNOME Maps
      gnome-weather # GNOME Weather widget
      gnome-contacts # GNOME Contacts
      gnome-music # GNOME Music — you use spotify
      epiphany # GNOME Web (built-in browser) — you use brave/firefox
      geary # GNOME Mail client — you use proton-mail
      gnome-calendar
      simple-scan # scanner app — keep if thou have a scanner, exclude if not
      gnome-clocks # keep or exclude based on preference
      # gnome-characters   # character/emoji picker — borderline useful
    ];

    # ─────────────────────────────────────────────────────────────────────────────
    # UNFREE PACKAGES
    # ─────────────────────────────────────────────────────────────────────────────
    # Some packages (spotify, obsidian, steam, etc.) carry proprietary licenses.
    # Nix refuses to build or install them unless you explicitly permit this.
    # Scoping it here keeps the allowance contained to this Home Manager config.
    #nixpkgs.config.allowUnfree = true; # the declaration on configuration.nix suffices

    # ─────────────────────────────────────────────────────────────────────────────
    # PACKAGES
    # ─────────────────────────────────────────────────────────────────────────────
    # Everything here is installed into your user profile at /nix/store and linked
    # into the Home Manager generation path. The native package manager (pacman,
    # apt, dnf) owns nothing in this list.
    #
    # Grouped by purpose. Order is irrelevant to Nix — it's a set, not a sequence.
    home.packages = with pkgs; [

      # ── GNOME Shell Extensions ───────────────────────────────────────────────
      # Installing the package makes the extension *available* to GNOME.
      # The dconf.settings block below tells GNOME Shell which UUIDs to *activate*.
      # You need both. An installed-but-not-enabled extension shows in the
      # Extensions app as toggled off. An enabled UUID with no package = error on load.
      gnomeExtensions.blur-my-shell
      gnomeExtensions.burn-my-windows
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.compact-quick-settings
      gnomeExtensions.compiz-alike-magic-lamp-effect
      gnomeExtensions.compiz-windows-effect
      gnomeExtensions.coverflow-alt-tab
      gnomeExtensions.desktop-cube
      gnomeExtensions.hide-top-bar
      gnomeExtensions.logo-menu
      gnomeExtensions.transparent-top-bar-adjustable-transparency
      gnomeExtensions.compiz-windows-effect
      gnomeExtensions.appindicator
      # Required for Layer 2 (GNOME Shell theme). Provides the user-theme extension
      # that reads org/gnome/shell/extensions/user-theme.name from dconf.
      gnomeExtensions.user-themes

      #gnomeExtensions.appimage-manager
      #gnomeExtensions.window-state-manager
      #gnomeExtensions.workspace-switcher-manager
      #gnomeExtensions.tweaks-in-system-menu

      # blur-my-shell covers the core blur use case (panel, overview, appfolder).
      gnome-extension-manager
    ];

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

      iconTheme = {
        # catppuccin-papirus-folders: Papirus icon set with Catppuccin-coloured folders.
        # The accent here must be prefixed with "cat-mocha-" for the override to pick
        # the right folder colour set.
        name = "Papirus-Dark"; # ADWAITA -> "Adwaita"
        package = pkgs.catppuccin-papirus-folders.override {
          # ADWAITA -> pkgs.adwaita-icon-theme
          flavor = ctpVariant; # mocha
          accent = ctpAccent; # mauve
        };
      };

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

    # ─────────────────────────────────────────────────────────────────────────────
    # DCONF SETTINGS
    # ─────────────────────────────────────────────────────────────────────────────
    # dconf is GNOME's configuration database. Every gsettings key ultimately
    # writes to dconf. Home Manager's dconf.settings block applies these
    # declaratively — no manual gsettings commands needed.
    #
    # Path mapping:
    #   dconf path:  /org/gnome/desktop/interface
    #   Nix key:     "org/gnome/desktop/interface"   (leading slash dropped)
    #
    # Type notes:
    #   plain string → Nix string "..."
    #   boolean      → Nix bool true/false
    #   integer      → Nix int (or lib.hm.gvariant.mkUint32 for uint32)
    #   float        → Nix float
    #   list         → Nix list [ ... ]
    #   tuple        → lib.hm.gvariant.mkTuple [ ... ]
    dconf.settings = {

      # ── Interface ──────────────────────────────────────────────────────────
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark"; # drives the dark mode toggle
        clock-format = "24h";
        show-battery-percentage = false;
        font-name = "Cantarell 11";
        document-font-name = "Cantarell 11";
        monospace-font-name = "Monospace 11";

        # gtk-theme tells GTK3 apps which theme to load.
        # Must match gtk.theme.name exactly.
        gtk-theme = ctpThemeName; # ADWAITA -> "adw-gtk3";
        icon-theme = "Papirus-Dark"; # ADWAITA -> "Adwaita";

        # cursor-theme = "Catppuccin Mocha Dark"; # ADWAITA -> "Adwaita";
        cursor-theme = "Adwaita";
        cursor-size = 24;
      };

      # Enforde Dark Mode at XDG portal level
      "org/freedesktop/appearance" = {
        color-scheme = lib.hm.gvariant.mkUint32 1; # the value 1 does the magic
      };

      # ── Keyboard: Layout & XKB Remapping ──────────────────────────────────
      # Your remapping lives here — no keyd daemon needed.
      #
      # ctrl:swapcaps   → Caps Lock ↔ Left Ctrl (swap physical keys)
      # menu:super       → Menu key becomes Super (Windows key)
      # altwin:menu_win  → Reinforces Menu→Super at XKB level
      #
      # sources: list of (type, layout) tuples. ('xkb', 'us') = US QWERTY.
      "org/gnome/desktop/input-sources" = {
        sources = [
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "us"
          ])
        ];
        xkb-options = [
          "ctrl:swapcaps"
          "menu:super"
          "altwin:menu_win"
        ];
      };

      # ── Window Manager Keybindings ─────────────────────────────────────────
      # Vim-style workspace navigation carried over from your Debian dconf dump.
      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-1 = [ "<Control>1" ];
        switch-to-workspace-2 = [ "<Control>2" ];
        switch-to-workspace-3 = [ "<Control>3" ];
        switch-to-workspace-4 = [ "<Control>4" ];
        switch-to-workspace-left = [ "<Control>h" ];
        switch-to-workspace-right = [ "<Control>l" ];
        switch-to-workspace-up = [ "<Control><Alt>Up" ];
        switch-to-workspace-down = [ "<Control><Alt>Down" ];
        move-to-workspace-left = [ "<Control><Shift>h" ];
        move-to-workspace-right = [ "<Control><Shift>l" ];
        move-to-workspace-up = [ "<Control><Shift><Alt>Up" ];
        move-to-workspace-down = [ "<Control><Shift><Alt>Down" ];
      };

      # ── Workspace Behaviour ────────────────────────────────────────────────
      # dynamic-workspaces: GNOME auto-creates/removes workspaces.
      # num-workspaces: upper bound (11 matches your Debian setup).
      "org/gnome/mutter" = {
        dynamic-workspaces = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 11;
      };

      # ── Power Management ───────────────────────────────────────────────────
      "org/gnome/desktop/session" = {
        # idle-delay = 0: never auto-dim or lock from inactivity alone.
        idle-delay = lib.hm.gvariant.mkUint32 0;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        idle-dim = false;
        power-button-action = "suspend";
        sleep-inactive-ac-type = "nothing"; # never sleep on AC
        sleep-inactive-battery-timeout = 900; # 15 min on battery
        sleep-inactive-battery-type = "nothing";
      };

      # ── Night Light ────────────────────────────────────────────────────────
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = false; # manual schedule, not auto-timezone
      };

      # ── Touchpad ───────────────────────────────────────────────────────────
      "org/gnome/desktop/peripherals/touchpad" = {
        natural-scroll = true;
        two-finger-scrolling-enabled = true;
        click-method = "fingers";
        speed = 0.45531914893617031;
      };

      # ── Mouse ──────────────────────────────────────────────────────────────
      "org/gnome/desktop/peripherals/mouse" = {
        natural-scroll = false;
        speed = 0.4893617021276595;
      };

      # ── Wallpaper ──────────────────────────────────────────────────────────
      "org/gnome/desktop/background" = {
        picture-uri = "file:///home/cypher-whisperer/.local/share/backgrounds/default-gnome-bg.jpg";
        picture-uri-dark = "file:///home/cypher-whisperer/.local/share/backgrounds/default-gnome-bg.jpg";
        picture-options = "zoom";
        color-shading-type = "solid";
        primary-color = "#000000000000";
        secondary-color = "#000000000000";
      };

      "org/gnome/desktop/screensaver" = {
        picture-uri = "file:///home/cypher-whisperer/.local/share/backgrounds/default-gnome-bg.jpg";
        picture-options = "zoom";
        color-shading-type = "solid";
        primary-color = "#000000000000";
        secondary-color = "#000000000000";
      };

      # ── Shell: Enabled Extensions + Dash Favorites ─────────────────────────
      "org/gnome/shell" = {
        # The UUID list tells GNOME Shell which extensions to load on startup.
        # Each string must exactly match the UUID in the extension's metadata.json.
        enabled-extensions = [
          "blur-my-shell@aunetx"
          "burn-my-windows@schneegans.github.com"
          "clipboard-indicator@tudmotu.com"
          "compact-quick-settings@gnome-shell-extensions.mariospr.org"
          "compiz-alike-magic-lamp-effect@hermes83.github.com"
          "compiz-windows-effect@hermes83.github.com"
          "CoverflowAltTab@palatis.blogspot.com"
          "desktop-cube@schneegans.github.com"
          "hidetopbar@mathieu.bidon.ca"
          "logomenu@aryan_k"
          "transparent-top-bar@zhanghai.me"
          "wobbly-windows@mecheye.net"
          "appindicatorsupport@rgcjonas.gmail.com"
          # Layer 2: GNOME Shell chrome (top bar, overview, notifications).
          # user-theme extension reads from org/gnome/shell/extensions/user-theme
          # and applies a shell theme from ~/.themes or the system themes directory.
          "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];

        # The dash/dock favorites list. These are .desktop file names — GNOME
        # looks them up in the applications directories on your PATH.
        # Order here = left-to-right order in the dash.
        # Apps not installed produce a broken icon; remove them or install the app.
        #
        # To find the .desktop names, simply run the command below that checks
        # places where GNOME looks for and returns a sorted list
        #
        #    find /run/current-system/sw/share/applications \
        #       ~/.local/share/applications \
        #       ~/.nix-profile/share/applications \
        #       /etc/profiles/per-user/$USER/share/applications \
        #      -name "*.desktop" 2>/dev/null | xargs -I{} basename {} | sort

        favorite-apps = [
          # browser
          "brave-browser.desktop"
          "firefox.desktop"
          # communication
          "discord.desktop"
          "com.github.dagmoller.whatsapp-electron.desktop"
          # development
          "code.desktop"
          "antigravity.desktop"
          "cursor.desktop"
          "webstorm.desktop"
          "android-studio.desktop"
          # terminal
          "com.mitchellh.ghostty.desktop"
          "kitty.desktop"
          # productivity
          "obsidian.desktop"
          "org.gnome.TextEditor.desktop"
          "vim.desktop"
          # creative
          "blender.desktop"
          "claude-desktop.desktop"
          "gimp.desktop"
          "org.inkscape.Inkscape.desktop"
          "org.kde.krita.desktop"
          "figma-linux.desktop"
          "Penpot.desktop"
          # misc
          "org.gnome.Nautilus.desktop"
          "spotify.desktop"
          "claude.desktop"
          "megasync.desktop"
          "com.github.rafostar.Clapper.desktop"
          "org.gnome.SystemMonitor.desktop"

          #  REMOVED:
          #   "nautilus-autorun-software.desktop"
          #   "audacity.desktop"
          #   "libreoffice-writer.desktop"
          #   "org.kde.kdenlive.desktop"
          #   "steam.desktop"
          #   "org.keepassxc.KeePassXC.desktop"
          #   "proton.vpn.app.gtk.desktop"
          #   "com.mattjakeman.ExtensionManager.desktop"
          #   "ca.desrt.dconf-editor.desktop"
          #   "proton-mail.desktop"
          #   "proton-pass.desktop"
          #   "proton.vpn.app.gtk.desktop"
          #   "staruml.desktop"
          #   "nixos-manual.desktop"
          #   "nvim.desktop"
          #   "starunl.desktop"
          #   "drawio.desktop"
        ];
      };

      # Layer 2: GNOME Shell theme (top bar, overview, notifications, dash).
      # Requires the user-theme extension to be installed and enabled above.
      # The name here must match ctpThemeName — the catppuccin-gtk package installs
      # a gnome-shell/ subdirectory inside the theme folder, which this extension reads.
      "org/gnome/shell/extensions/user-theme" = {
        name = ctpThemeName;
      };

      # ── Extension: hide-top-bar ───────────────────────────────────────────-
      "org/gnome/shell/extensions/hidetopbar" = {
        enable-active-window = true;
        enable-intellihide = true;
      };

      # ── Extension: blur-my-shell ───────────────────────────────────────────
      "org/gnome/shell/extensions/blur-my-shell" = {
        settings-version = 2;
      };

      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        brightness = 0.6;
        sigma = 30;
      };

      "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
        brightness = 0.6;
        sigma = 30;
      };

      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        blur = true;
        brightness = 0.6;
        sigma = 30;
        static-blur = true;
        style-dash-to-dock = 0;
      };

      "org/gnome/shell/extensions/blur-my-shell/window-list" = {
        brightness = 0.6;
        sigma = 30;
      };

      # ── Extension: logo-menu ───────────────────────────────────────────────
      # menu-button-icon-image = 19 selects the NixOS snowflake from the built-in
      # icon list. You may want a different index; the extension's settings UI
      # lets you preview them. symbolic-icon = true uses the monochrome variant.
      "org/gnome/shell/extensions/Logo-menu" = {
        menu-button-icon-image = 19;
        symbolic-icon = true;
        use-custom-icon = false;
      };

      # ── Extension: coverflow-alt-tab ──────────────────────────────────────
      "org/gnome/shell/extensions/coverflowalttab" = {
        switcher-background-color = lib.hm.gvariant.mkTuple [
          1.0
          1.0
          1.0
        ];
      };

      # ── Extension: compiz-windows-effect ──────────────────────────────────
      "org/gnome/shell/extensions/com/github/hermes83/compiz-windows-effect" = {
        last-version = 29;
        preset = "R";
      };

      # ── Extension: clipboard-indicator ────────────────────────────────────
      "org/gnome/shell/extensions/clipboard-indicator" = {
        notify-on-copy = true;
      };

      # ── Nautilus ──────────────────────────────────────────────────────────
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";
      };

      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "small";
      };

      "org/gnome/nautilus/compression" = {
        default-compression-format = "tar.xz";
      };

      # ── App Grid Folders ───────────────────────────────────────────────────
      "org/gnome/desktop/app-folders" = {
        folder-children = [
          "System"
          "Utilities"
        ];
      };

      "org/gnome/desktop/app-folders/folders/System" = {
        name = "X-GNOME-Shell-System.directory";
        translate = true;
        apps = [
          "nm-connection-editor.desktop"
          "org.gnome.baobab.desktop"
          "org.gnome.DiskUtility.desktop"
          "org.gnome.SystemMonitor.desktop"
          "org.gnome.tweaks.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Utilities" = {
        name = "X-GNOME-Shell-Utilities.directory";
        translate = true;
        apps = [
          "org.gnome.Evince.desktop"
          "org.gnome.font-viewer.desktop"
          "org.gnome.Loupe.desktop"
          "org.gnome.Logs.desktop"
        ];
      };

    }; # end dconf.settings

    # ─────────────────────────────────────────────────────────────────────────────
    # ASSETS: WALLPAPER & AVATAR
    # ─────────────────────────────────────────────────────────────────────────────
    # home.file places these into the user profile during `nixos-rebuild switch`,
    # BEFORE GDM or the GNOME session starts reading dconf. This solves the
    # first-boot blank/black wallpaper problem — the file is guaranteed to exist
    # at the path dconf points to.
    #
    # The source path uses builtins.path / a relative path from the module file.
    # Because modules/de/gnome.nix is the file being evaluated, ./assets/ resolves
    # relative to that file in the Nix store — fully hermetic.

    home.file.".local/share/backgrounds/default-gnome-bg.jpg" = {
      source = ../assets/images/default-gnome-bg.jpg;
    };

    # GNOME reads the user avatar from ~/.face (a well-known path).
    # AccountsService (the daemon behind the lock screen user tile) also checks
    # /var/lib/AccountsService/icons/<username>, but that's a system path —
    # we handle that separately in configuration.nix (see below).
    home.file.".face" = {
      source = ../assets/images/default-gnome-avatar.jpg;
    };

    # ─────────────────────────────────────────────────────────────────────────────
    # XDG PROFILE LAUNCHER SCRIPT
    # ─────────────────────────────────────────────────────────────────────────────
    # This script is the entry point for every GNOME session on this machine.
    # Before exec-ing gnome-session, it overrides all four XDG base directories
    # to point into ~/.*/profiles/gnome/ instead of the bare ~/.*.
    #
    # Why this matters: every GNOME component (shell, nautilus, mimeapps.list,
    # autostart, keyring) respects XDG_CONFIG_HOME etc. when deciding where to
    # read and write config. By redirecting those paths, GNOME gets a completely
    # isolated config namespace that Hyprland and KDE Plasma cannot touch.
    #
    # home.file places this script at $HOME/.local/bin/launch-gnome.
    # executable = true sets the +x bit automatically.
    #
    # The NixOS configuration.nix will reference this path in a custom
    # wayland-session .desktop entry so GDM shows it as a login option.
    home.file.".local/bin/launch-gnome" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # XDG Profile Launcher — GNOME
        # Managed by Home Manager (modules/de/gnome.nix). Do not edit manually.

        export XDG_CONFIG_HOME="$HOME/.config/profiles/gnome"
        export XDG_DATA_HOME="$HOME/.local/share/profiles/gnome"
        export XDG_CACHE_HOME="$HOME/.cache/profiles/gnome"
        export XDG_STATE_HOME="$HOME/.local/state/profiles/gnome"

        exec gnome-session
      '';
    };
  }; # end config
}
