{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.cypher-os.gaming.enable = lib.mkEnableOption "Enable Gaming";

  config = lib.mkIf (
    config.cypher-os.profile.desktop.enable     # Ensure desktop profile is enabled, since Steam is a GUI app
    && config.cypher-os.gaming.enable ) {

    imports = [
      #./steam.nix # <- imported in configuration.nix
      ./minecraft.nix
      ./steam.nix
    ];

    cypher-os.gaming.minecraft.enable = lib.mkDefault true;
    cypher-os.gaming.steam.enable = lib.mkDefault true;
  };
}
