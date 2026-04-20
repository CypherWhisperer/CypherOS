# imports all common sub-modules

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.common.enable ) {
      # Common apps and configs that apply regardless of DE or profile.
      # These are the unconditionally installed applications and configurations

      # Now to enable each of the apps/ configurations.
      cypher-os.apps.common.security.enable = lib.mkDefault true;
      cypher-os.apps.common.diskUtils.enable = lib.mkDefault true;
      cypher-os.apps.common.proton.enable = lib.mkDefault true;
      cypher-os.apps.common.fonts.enable = lib.mkDefault true;
      cypher-os.apps.common.xdg.enable = lib.mkDefault true;
    };
}
