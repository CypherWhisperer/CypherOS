# modules/de/gnome/options.nix

{ lib, ... }:
{
  options.cypher-os.de.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
    # Future options slot in here:
    # extensions.enable = lib.mkEnableOption "GNOME Shell extensions";
    # theme.accent = lib.mkOption { type = lib.types.str; default = "mauve"; ... };
  };
}
