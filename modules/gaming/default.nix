{ ... }:

{
  imports = [
    #../gaming/steam.nix # <- imported in configuration.nix
    ../gaming/steam-data.nix
    ../gaming/minecraft.nix
  ];
}
