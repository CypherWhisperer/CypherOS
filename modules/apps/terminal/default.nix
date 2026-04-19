# Empty stub to be populated at the right phase

{ config, pkgs, lib, ... }:

{
  options.cypher-os.apps.terminal.enable = lib.mkEnableOption "CypherOS terminal applications/emulators";

  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.terminal.enable ) {
      imports = [
        ./ghostty.nix
        ./kitty.nix
      ];

      cypher-os.apps.terminal.ghostty.enable = lib.mkDefault true;
      cypher-os.apps.terminal.kitty.enable = lib.mkDefault true;
  };
}
