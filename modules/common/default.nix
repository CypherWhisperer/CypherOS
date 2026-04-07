# imports all common sub-modules

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./cli.nix
    ./dev.nix
    ./security.nix
    ./xdg.nix
  ];
}

  {
    # stub — not yet implemented
  }
