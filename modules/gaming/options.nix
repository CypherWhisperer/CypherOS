{ lib, ... }:

{
  options.cypher-os.gaming = {
    enable = lib.mkEnableOption "Enable Gaming";
    steam.enable = lib.mkEnableOption "Enable Steam and gaming infrastructure";
    minecraft.enable = lib.mkEnableOption "Enable Minecraft and related gaming infrastructure";
  };
}
