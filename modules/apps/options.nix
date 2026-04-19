# modules/apps/options.nix
#
# Declares the top-level master switch for all CypherOS app modules.
#
# cypher-os.apps.enable defaults to true — you almost never set this to false
# manually. Its purpose is as an emergency kill-switch (e.g. on a truly minimal
# ISO or rescue environment). Individual groups are controlled by their own
# enable options. Profiles set those group options via mkDefault.

{ lib, ... }:

{
  options = {
    cypher-os.apps.enable = lib.mkOption {
      type        = lib.types.bool;
      # Override the mkEnableOption default of false → make it default true.
      # mkEnableOption produces `default = false`; we override that here.
      default     = true;
      description = " CypherOS Application Layer: Master kill-switch for the CypherOS application layer.";
    };
  };
}
