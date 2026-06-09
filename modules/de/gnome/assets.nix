# modules/de/gnome/assets.nix
#
# GNOME assets: wallpaper and user avatar.
#
# Owns the home.file declarations that place static image assets into the
# user profile before GDM or the GNOME session reads dconf. Keeping these
# here guarantees the files exist at their dconf-referenced paths on every
# boot, solving the first-boot blank/black wallpaper problem.

{
  config,
  lib,
  ...
}:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.cypher-os.de.gnome.enable {

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

  }; # end config
}
