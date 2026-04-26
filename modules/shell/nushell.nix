{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.shell.enable && config.cypher-os.shell.nushell.enable) {

    home.packages = with pkgs; [
      nushell
    ];
  };
}
