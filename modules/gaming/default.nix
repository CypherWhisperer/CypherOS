{
  config,
  lib,
  ...
}:

{
  imports = [
    ./options.nix
    ./minecraft.nix
    ./steam-hm.nix
  ];

  config = lib.mkIf (config.cypher-os.profile.desktop.enable && config.cypher-os.gaming.enable) {
    cypher-os.gaming.minecraft.enable = lib.mkDefault true;
    cypher-os.gaming.steam.enable = lib.mkDefault true;
  };
}
