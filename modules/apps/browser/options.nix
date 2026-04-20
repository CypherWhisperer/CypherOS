{ lib, ... }:

{
  options.cypher-os.apps.browser = {
    enable      = lib.mkEnableOption "Browser applications";
    brave.enable = lib.mkEnableOption "Brave web browser";
    firefox.enable = lib.mkEnableOption "Firefox web browser";
  };
}
