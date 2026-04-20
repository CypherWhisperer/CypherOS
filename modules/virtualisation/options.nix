# modules/virtualisation/options.nix
#
# Declares cypher-os.virtualisation.* options.
# Imported unconditionally by modules/home/default.nix so the option
# exists in the merged set before any mkIf references it.
# No config lives here — only option shapes.

{ lib, ... }:

{
  options.cypher-os.virtualisation.helpers.enable = lib.mkEnableOption
    "virtualisation helpers (distrobox, winboat, vagrant, virt-viewer)";
}
