# modules/de/gnome/gnome/hm.nix
#
# Home Manager module for the GNOME desktop environment.
#
# Home Manager module for GNOME desktop environment.
# Manages everything Gnome-specific: extensions, dconf settings, theming, fonts,
# the XDG profile launcher, and the gnome-specific packages
# The main module file imports and composes the smaller, focused modules in this
# directory: extensions.nix, dconf.nix, theming.nix, and assets.nix.

{
  config,
  lib,
  ...
}:

{
  imports = [
    ./extensions.nix
    ./assets.nix
    ./theming.nix
    ./dconf.nix
  ];

  config = lib.mkIf config.cypher-os.de.gnome.enable {
    # ─────────────────────────────────────────────────────────────────────────────
    # UNFREE PACKAGES
    # ─────────────────────────────────────────────────────────────────────────────
    # Some packages (spotify, obsidian, steam, etc.) carry proprietary licenses.
    # Nix refuses to build or install them unless you explicitly permit this.
    # Scoping it here keeps the allowance contained to this Home Manager config.
    #nixpkgs.config.allowUnfree = true; # the declaration on configuration.nix suffices

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
