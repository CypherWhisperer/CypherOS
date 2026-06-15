{
  lib,
  config,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf
      (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.affine.enable)
      {
        home.packages = with pkgs; [ affine ];
      };
}
