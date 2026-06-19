{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.productivity.enable) {

    cypher-os.apps.productivity.claude.enable = lib.mkDefault true;
    cypher-os.apps.productivity.obsidian.enable = lib.mkDefault true;
    cypher-os.apps.productivity.penpot.enable = lib.mkDefault true;

    # Installing the rest of productivity applications
    home.packages = with pkgs; [
      # ── System Design ────────────────────────────────────────────────────────
      drawio
      staruml

      # ── Creative Suite ───────────────────────────────────────────────────────
      #houdini
      gimp
      inkscape
      blender
      krita
      kdePackages.kdenlive
      audacity
      figma-agent

      # ── Media ────────────────────────────────────────────────────────────────
      vlc
      spotify
      clapper

      # ── Communication ────────────────────────────────────────────────────────
      discord
      whatsapp-electron # Electron wrapper around Whatsapp
      whatsapp-chat-exporter # WhatsApp database parser
      signal-desktop
      telegram-desktop

      # ── Workflow and Automation ──────────────────────────────────────────────
      #n8n # now handled by modules/devops/n8n.nix
    ];
  };
}
