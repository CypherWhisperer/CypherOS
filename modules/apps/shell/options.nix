{ lib, ... }:

{
  options.cypher-os.apps.shell = {
    enable = lib.mkEnableOption "CypherOS shell environment";
    zsh.enable = lib.mkEnableOption "Zsh shell environment for CypherOS";
  };
}
