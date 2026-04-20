# modules/devops/default.nix
#
# Entry point for the devops module directory.
# Imported by modules/home/default.nix (HM context) to register options.
#
# ONLY imports options.nix — the system config lives in system.nix
# which is imported directly by hosts/nixos/configuration.nix.

{ ... }:

{
  imports = [ ./options.nix ];
}
