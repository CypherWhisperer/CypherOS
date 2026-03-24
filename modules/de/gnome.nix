# modules/de/gnome.nix
#
# Home Manager module for GNOME desktop environment.
# Manages everything user-space: extensions, dconf settings, theming, fonts,
# the XDG profile launcher, and the applications installed for GNOME sessions.
#
# WHAT THIS FILE OWNS:
#   - GNOME Shell extensions (installed + enabled list)
#   - All dconf settings (keybindings, appearance, power, peripherals)
#   - GTK theme, icon theme, cursor, fonts
#   - The XDG profile launcher script (~/.local/bin/launch-gnome)
#   - User-space applications
#
# WHAT THIS FILE DOES NOT OWN:
#   - GDM (display manager)    → NixOS: services.displayManager.gdm
#   - gnome-shell itself        → NixOS: services.desktopManager.gnome
#   - System daemons            → NixOS: services.*
#   - Kernel / drivers          → NixOS: hardware.*
#
# Usage:
#   imports = [ ../../modules/de/gnome.nix ];

{ config, pkgs, lib, ... }:

{
  # ─────────────────────────────────────────────────────────────────────────────
  # UNFREE PACKAGES
  # ─────────────────────────────────────────────────────────────────────────────
  # Some packages (spotify, obsidian, steam, etc.) carry proprietary licenses.
  # Nix refuses to build or install them unless you explicitly permit this.
  # Scoping it here keeps the allowance contained to this Home Manager config.
  nixpkgs.config.allowUnfree = true;


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
    gnomeExtensions.wobbly-windows
    gnomeExtensions.appindicator

    # blur-me and blur-provider: not in nixpkgs at time of writing.
    # blur-my-shell covers the core blur use case (panel, overview, appfolder).
    # Can be fetched via fetchurl from extensions.gnome.org if needed later.

    # gnome-fuzzy-app-search: not in nixpkgs. Revisit if GNOME's built-in
    # search feels lacking.

    # ── Browsers ─────────────────────────────────────────────────────────────
    brave
    firefox

    # ── Terminals ────────────────────────────────────────────────────────────
    kitty
    ghostty

    # ── Editors & IDEs ───────────────────────────────────────────────────────
    neovim
    # cursor  ← pkgs.cursor exists but may lag upstream. Uncomment when needed.
    # vscode  ← pkgs.vscode if needed. Both are unfree (covered above).

    # ── Communication ────────────────────────────────────────────────────────
    discord

    # ── Notes & Productivity ─────────────────────────────────────────────────
    obsidian          # unfree
    libreoffice
    keepassxc

    # ── Creative Suite ───────────────────────────────────────────────────────
    gimp
    inkscape
    blender
    krita
    kdenlive
    audacity
    obs-studio

    # ── Media ────────────────────────────────────────────────────────────────
    vlc
    spotify           # unfree

    # ── Proton Ecosystem ─────────────────────────────────────────────────────
    protonvpn-gui
    megasync
    # proton-mail: check pkgs.proton-mail — available in nixpkgs as of late 2024.
    # Uncomment once confirmed against your nixpkgs channel.
    # proton-mail

    # ── Gaming ───────────────────────────────────────────────────────────────
    steam             # unfree; includes steam-run and pressure-vessel
    wine
    winetricks

    # ── CLI Tooling ───────────────────────────────────────────────────────────
    fzf               # fuzzy finder — pipes, history search, file selection
    ripgrep           # rg: fast grep replacement, respects .gitignore
    bat               # cat with syntax highlighting and line numbers
    fd                # find replacement: simpler syntax, faster
    fastfetch         # system info display (neofetch successor)
    btop              # interactive resource monitor
    htop              # lighter resource monitor
    tmux              # terminal multiplexer
    tree              # directory tree display
    ranger            # vim-keyed terminal file manager
    zsh
    fish
    nushell
    git
    git-lfs
    curl
    wget
    pass              # password-store: GPG-backed password manager
    rsync
    keychain          # SSH/GPG key agent manager across sessions

    # ── Dev Tooling ───────────────────────────────────────────────────────────
    nodejs_20         # pinned to LTS; change to nodejs if you want latest
    python3
    cmake
    pipx              # install Python CLI tools in isolated envs
    mkcert            # generate locally-trusted TLS certs for dev
    docker-client     # CLI only — the daemon itself is an OS-level concern

    # ── Security & Networking ─────────────────────────────────────────────────
    nmap
    wireshark
    tor
    tcpdump
    strace
    gobuster

    # ── Fonts ────────────────────────────────────────────────────────────────
    # Cantarell: GNOME's default UI font — declared here for non-NixOS hosts.
    # On NixOS it comes in via the GNOME system packages automatically.
    cantarell-fonts
    fira-code
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "RobotoMono" "JetBrainsMono" ]; })

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
  # look consistent with native GNOME 48 apps. Closer to your Debian feel than
  # raw "Adwaita" which is the GTK3-era style. Toggle to "Adwaita" + pkgs.gnome.adwaita-icon-theme
  # if you prefer the pure classic look.
  gtk = {
    enable = true;

    theme = {
      name    = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name    = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    cursorTheme = {
      name    = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size    = 24;
    };

    font = {
      name = "Cantarell";
      size = 11;
    };
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
      color-scheme            = "prefer-dark";   # drives the dark mode toggle
      clock-format            = "24h";
      show-battery-percentage = false;
      font-name               = "Cantarell 11";
      document-font-name      = "Cantarell 11";
      monospace-font-name     = "Monospace 11";
      gtk-theme               = "adw-gtk3";
      icon-theme              = "Adwaita";
      cursor-theme            = "Adwaita";
      cursor-size             = 24;
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
      sources     = [ (lib.hm.gvariant.mkTuple [ "xkb" "us" ]) ];
      xkb-options = [ "ctrl:swapcaps" "menu:super" "altwin:menu_win" ];
    };

    # ── Window Manager Keybindings ─────────────────────────────────────────
    # Vim-style workspace navigation carried over from your Debian dconf dump.
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-1    = [ "<Control>1" ];
      switch-to-workspace-2    = [ "<Control>2" ];
      switch-to-workspace-3    = [ "<Control>3" ];
      switch-to-workspace-4    = [ "<Control>4" ];
      switch-to-workspace-left  = [ "<Control>h" ];
      switch-to-workspace-right = [ "<Control>l" ];
      switch-to-workspace-up    = [ "<Control><Alt>Up" ];
      switch-to-workspace-down  = [ "<Control><Alt>Down" ];
      move-to-workspace-left    = [ "<Control><Shift>h" ];
      move-to-workspace-right   = [ "<Control><Shift>l" ];
      move-to-workspace-up      = [ "<Control><Shift><Alt>Up" ];
      move-to-workspace-down    = [ "<Control><Shift><Alt>Down" ];
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
      idle-dim                       = false;
      power-button-action            = "suspend";
      sleep-inactive-ac-type         = "nothing";   # never sleep on AC
      sleep-inactive-battery-timeout = 900;          # 15 min on battery
      sleep-inactive-battery-type    = "nothing";
    };

    # ── Night Light ────────────────────────────────────────────────────────
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled            = true;
      night-light-schedule-automatic = false;  # manual schedule, not auto-timezone
    };

    # ── Touchpad ───────────────────────────────────────────────────────────
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll              = true;
      two-finger-scrolling-enabled = true;
      click-method                = "fingers";
      speed                       = 0.45531914893617031;
    };

    # ── Mouse ──────────────────────────────────────────────────────────────
    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
      speed          = 0.4893617021276595;
    };

    # ── Wallpaper ──────────────────────────────────────────────────────────
    # After first boot, copy your wallpaper image to:
    #   ~/.local/share/backgrounds/cypher-wallpaper.jpg
    # This dconf entry will then point at it correctly.
    "org/gnome/desktop/background" = {
      picture-uri        = "file:///home/cypher-whisperer/.local/share/backgrounds/cypher-wallpaper.jpg";
      picture-uri-dark   = "file:///home/cypher-whisperer/.local/share/backgrounds/cypher-wallpaper.jpg";
      picture-options    = "zoom";
      color-shading-type = "solid";
      primary-color      = "#000000000000";
      secondary-color    = "#000000000000";
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri        = "file:///home/cypher-whisperer/.local/share/backgrounds/cypher-wallpaper.jpg";
      picture-options    = "zoom";
      color-shading-type = "solid";
      primary-color      = "#000000000000";
      secondary-color    = "#000000000000";
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
      ];

      # The dash/dock favorites list. These are .desktop file names — GNOME
      # looks them up in the applications directories on your PATH.
      # Order here = left-to-right order in the dash.
      # Apps not installed produce a broken icon; remove them or install the app.
      favorite-apps = [
        "brave-browser.desktop"
        "firefox.desktop"
        "discord.desktop"
        "org.gnome.Nautilus.desktop"
        "kitty.desktop"
        "com.mitchellh.ghostty.desktop"
        "nvim.desktop"
        "obsidian.desktop"
        "libreoffice-writer.desktop"
        "org.gimp.GIMP.desktop"
        "org.inkscape.Inkscape.desktop"
        "org.kde.kdenlive.desktop"
        "vlc.desktop"
        "spotify.desktop"
        "steam.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "megasync.desktop"
        "proton.vpn.app.gtk.desktop"
        "org.gnome.SystemMonitor.desktop"
        "com.mattjakeman.ExtensionManager.desktop"
        "ca.desrt.dconf-editor.desktop"
      ];
    };

    # ── Extension: blur-my-shell ───────────────────────────────────────────
    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      brightness = 0.6;
      sigma      = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = 0.6;
      sigma      = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur               = true;
      brightness         = 0.6;
      sigma              = 30;
      static-blur        = true;
      style-dash-to-dock = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = 0.6;
      sigma      = 30;
    };

    # ── Extension: logo-menu ───────────────────────────────────────────────
    # menu-button-icon-image = 19 selects the NixOS snowflake from the built-in
    # icon list. You may want a different index; the extension's settings UI
    # lets you preview them. symbolic-icon = true uses the monochrome variant.
    "org/gnome/shell/extensions/Logo-menu" = {
      menu-button-icon-image = 19;
      symbolic-icon          = true;
      use-custom-icon        = false;
    };

    # ── Extension: coverflow-alt-tab ──────────────────────────────────────
    "org/gnome/shell/extensions/coverflowalttab" = {
      switcher-background-color = lib.hm.gvariant.mkTuple [ 1.0 1.0 1.0 ];
    };

    # ── Extension: compiz-windows-effect ──────────────────────────────────
    "org/gnome/shell/extensions/com/github/hermes83/compiz-windows-effect" = {
      last-version = 29;
      preset       = "R";
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
      folder-children = [ "System" "Utilities" ];
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      name      = "X-GNOME-Shell-System.directory";
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
      name      = "X-GNOME-Shell-Utilities.directory";
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


  # ─────────────────────────────────────────────────────────────────────────────
  # HOME MANAGER STATE VERSION
  # ─────────────────────────────────────────────────────────────────────────────
  # Set once, never change. This tells HM which release its config schema
  # was written against — it gates migration logic, not which packages you get.
  home.stateVersion = "24.11";
}
