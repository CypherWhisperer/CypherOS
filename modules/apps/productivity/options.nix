{ lib, ... }:

{
  options.cypher-os.apps.productivity = {
    enable = lib.mkEnableOption "CypherOS Productivity Applications";
    claude.enable = lib.mkEnableOption "Claude Desktop";
    obsidian.enable = lib.mkEnableOption "Obsidian Desktop App";
  };
}
