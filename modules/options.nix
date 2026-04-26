{
  lib,
  ...
}:

{
  options = {
    cypher-os.extra-fonts = {
      enable = lib.mkEnableOption "CypherOS Extra Fonts";
    };

    cypher-os.xdg-config = {
      enable = lib.mkEnableOption "CypherOS XDG Configuration";
    };
  };
}
