{ config, pkgs, lib, ... }:

{
  options.cypher-os.apps.common.proton.enable =
    lib.mkEnableOption "CypherOS Proton Ecosystem Applications";

  config = lib.mkIf (
    config.cypher-os.profile.desktop.enable &&
    config.cypher-os.apps.common.proton.enable ) {

    home.packages = with pkgs; [

      # ── Proton Ecosystem ─────────────────────────────────────────────────────
      proton-vpn
      proton-pass
      protonmail-desktop
      #protonmail-bridge-gui
      #protonmail-bridge

      # MegaSync
      megasync
    ];
  };
}
