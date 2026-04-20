{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.browser.enable) {
    cypher-os.apps.browser.brave.enable = lib.mkDefault true;
    cypher-os.apps.browser.firefox.enable = lib.mkDefault true;
  };
}
