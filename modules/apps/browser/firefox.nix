{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf  (
    config.cypher-os.apps.browser.enable &&
    config.cypher-os.apps.browser.firefox.enable ) {
      home.packages = with pkgs; [ firefox ];
  };
}
