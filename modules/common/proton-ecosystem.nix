{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    
    # ── Proton Ecosystem ─────────────────────────────────────────────────────
    proton-vpn
    proton-pass
    protonmail-desktop
    megasync
    #protonmail-bridge-gui
    #protonmail-bridge

  ];
}
