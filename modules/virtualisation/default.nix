# modules/virtualisation/default.nix
#
# Entry point for the virtualisation module directory.
# Imported by modules/home/default.nix (HM context) to register options.
#
# ONLY imports options.nix — the system config lives in system.nix
# which is imported directly by hosts/nixos/configuration.nix.

# This becomes a thin re-export shim. Since modules/home/default.nix
# imports ../virtualisation, it resolves to this file. All it needs to
# do is pull in options.nix so HM gets the declarations.
{ ... }:

{
  imports = [ ./options.nix ];
}
