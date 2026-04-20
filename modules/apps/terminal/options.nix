{ lib, ... }:

{
  options.cypher-os.apps.terminal = {
    enable = lib.mkEnableOption "CypherOS terminal applications/emulators";
    ghostty.enable = lib.mkEnableOption "CypherOS Ghostty terminal emulator";
    kitty.enable = lib.mkEnableOption "CypherOS Kitty terminal emulators";
  };
}
