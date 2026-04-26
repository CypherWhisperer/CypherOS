{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.shell.enable && config.cypher-os.shell.fish.enable) {

    home.packages = with pkgs; [
      fish
    ];
  };
}
