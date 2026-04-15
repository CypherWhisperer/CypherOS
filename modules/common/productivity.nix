{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    
    # ── System Design ────────────────────────────────────────────────────────
    drawio
    staruml

    libreoffice
    
    # ── Creative Suite ───────────────────────────────────────────────────────
    #houdini
    gimp
    inkscape
    blender
    krita
    kdePackages.kdenlive
    audacity
    obs-studio
    penpot-desktop
    figma-linux
    figma-agent

    # ── Media ────────────────────────────────────────────────────────────────
    vlc
    spotify # unfree
    clapper

    # ── Communication ────────────────────────────────────────────────────────
    discord
    whatsapp-electron # Electron wrapper around Whatsapp
    whatsapp-chat-exporter # WhatsApp database parser
    
    # ── Browsers ─────────────────────────────────────────────────────────────
    # brave # handled by ../apps/brave.nix
    firefox
 
    # ── Workflow and Automation ──────────────────────────────────────────────
    #n8n  # NOTE: the install memory intensive (keeps failing on my side).
  ];
}
