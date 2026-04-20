# modules/de/gnome/options.nix
#
# Declares cypher-os.de.gnome option.
# Imported unconditionally by modules/home/default.nix so the option
# exists in the merged set before any mkIf references it.
# No config lives here — only option shapes.

{ lib, ... }:
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
}
