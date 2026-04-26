{ lib, ... }:

{
  options.cypher-os.apps.common = {
    enable = lib.mkEnableOption "CypherOS Common Applications And Configurations";
    diskUtils.enable = lib.mkEnableOption "CypherOS Common Disk Utilities";
    fonts.enable = lib.mkEnableOption "CypherOS Common Fonts";
    proton.enable = lib.mkEnableOption "CypherOS Proton Ecosystem Applications";
    security.enable = lib.mkEnableOption "CypherOS Common Security-Oriented Applications";
  };
}
