{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.cypher-os.gaming.enable = lib.mkEnableOption "Enable Gaming";

  imports = [
    ./minecraft.nix
    ./steam-hm.nix
  ];

  config = lib.mkIf (
    config.cypher-os.profile.desktop.enable     # Ensure desktop profile is enabled, since Steam is a GUI app
    && config.cypher-os.gaming.enable ) {

    cypher-os.gaming.minecraft.enable = lib.mkDefault true;
    cypher-os.gaming.steam.enable = lib.mkDefault true;
  };
}
