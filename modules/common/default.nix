# imports all common sub-modules

#{
#  config,
#  pkgs,
#  lib,
#  ...
#}:

{ ... }:

{
  imports = [
    ./cli.nix
    ./dev.nix
    ./security.nix
    ./xdg.nix
    ./productivity.nix
    ./proton-ecosystem.nix
    ./fonts.nix
    ./disk-utils.nix
  ];
}

#{
  # stub — not yet implemented
#}
