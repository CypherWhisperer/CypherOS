# Empty stub to be populated at the right phase

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.terminal.enable ) {

      cypher-os.apps.terminal.ghostty.enable = lib.mkDefault true;
      cypher-os.apps.terminal.kitty.enable = lib.mkDefault true;
  };
}
