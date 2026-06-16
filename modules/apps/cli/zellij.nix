{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.apps.cli.enable && config.cypher-os.apps.cli.zellij.enable) {
    home.packages = with pkgs; [ zellij ];
  };
}
