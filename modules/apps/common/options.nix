{ lib, ... }:

{
  options.cypher-os.apps.common = {
    enable = lib.mkEnableOption "CypherOS Common Applications And Configurations";
    disk-utils.enable = lib.mkEnableOption "CypherOS Common Disk Utilities";
    proton.enable = lib.mkEnableOption "CypherOS Proton Ecosystem Applications";
    security.enable = lib.mkEnableOption "CypherOS Common Security-Oriented Applications";
  };
}
