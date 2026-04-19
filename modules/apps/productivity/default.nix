{ config, pkgs, lib, ... }:

{
  options.cypher-os.apps.productivity.enable = lib.mkEnableOption "CypherOS Productivity Applications";

  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.productivity.enable ) {

    # Importing relevant modules
    imports = [
      ./claude.nix
      ./obsidian.nix
    ];

    # Enabling options for the imported modules
    cypher-os.apps.productivity.claude.enable = lib.mkDefault true;
    cypher-os.apps.productivity.obsidian.enable = lib.mkDefault true;

    # Installing the rest of productivity applications
    home.packages = with pkgs; [
      # ── System Design ────────────────────────────────────────────────────────
      drawio
      staruml

      # ── Office Suite ───────────────────────────────────────────────────────
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
      #signal-desktop # unfree, also doesn't work well in nixpkgs

      # ── Workflow and Automation ──────────────────────────────────────────────
      n8n
    ];
  };
}
