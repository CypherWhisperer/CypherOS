# Empty stub to be populated at the right phase

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.shell.enable ) {

      cypher-os.apps.shell.zsh.enable = lib.mkDefault true;

      # Installing other shell-related packages
      home.packages = with pkgs; [
        fish
        nushell
      ];
  };
}
