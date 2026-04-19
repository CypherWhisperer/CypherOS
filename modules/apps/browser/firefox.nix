{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.cypher-os.apps.browser.firefox.enable = lib.mkEnableOption "Enable Firefox browser";

  config = lib.mkIf config.cypher-os.apps.browser.firefox.enable  {
      home.packages = with pkgs; [ firefox ];
  };
}
