# Empty stub to be populated at the right phase

{ config, pkgs, lib, ... }:

{
  options.cypher-os.apps.shell.enable = lib.mkEnableOption "CypherOS shell environment";

  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.shell.enable ) {

      # importing relevant modules
      imports = [
        ./zsh.nix
      ];

      # Enabling options from imported modules
      cypher-os.apps.shell.zsh.enable = lib.mkDefault true;

      # Installing other shell-related packages
      home.packages = with pkgs; [
        fish
        nushell
      ];
  };
}
