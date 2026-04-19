{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.cypher-os.apps.browser.enable = lib.mkEnableOption "Enable browser applications";

  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.browser.enable ) {
      imports = [
        ./brave.nix
        ./firefox.nix
      ];

      cypher-os.apps.browser.brave.enable = lib.mkDefault true;
      cypher-os.apps.browser.firefox.enable = lib.mkDefault true;
    };
}
