{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (
    config.cypher-os.apps.productivity.enable &&
    config.cypher-os.apps.productivity.zathura.enable ) {
      home.packages = with pkgs; [ zathura ];
  };
}
