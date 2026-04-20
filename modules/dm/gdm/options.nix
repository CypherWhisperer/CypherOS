{ lib, ... }:

{
  options.cypher-os.dm.gdm.enable = lib.mkEnableOption "GDM display manager";
}
