# modules/profile/system.nix
#
# NixOS-context profile module for CypherOS.
#
# WHY THIS FILE EXISTS:
#   NixOS modules and Home Manager modules evaluate in separate contexts.
#   Options set inside the HM evaluation (modules/profile/default.nix) are
#   invisible to NixOS system modules (de/gnome/system.nix, dm/gdm/system.nix).
#
#   This file is the NixOS-side counterpart — it imports the same
#   cypher-os.profile.*, cypher-os.de.*, and cypher-os.dm.* options that
#   system.nix modules gate on, and applies the same mkDefault cascade when
#   a profile is enabled.

# SYSTEM LEVEL (NIXOS) CONCERNS

{ config, lib, ... }:

{
  imports = [
    # SYSTEM LEVEL OPTIONS IMPORTED HERE
    # Profile Options
    ./options.nix
    # DE options
    ../de/gnome/options.nix
    # DM options
    ../dm/gdm/options.nix
    # steam option
    ../gaming/options.nix
    # Virtualization options
    ../virtualisation/options.nix
    # Devops options
    ../devops/options.nix
  ];

  config = lib.mkMerge [

    # ── Desktop profile cascade ──────────────────────────────────────────────
    # When desktop.enable = true, activate GNOME + GDM by default.
    # Any of these can be overridden downward in configuration.nix with a plain
    # assignment — mkDefault loses to an explicit set.
    (lib.mkIf config.cypher-os.profile.desktop.enable {
      cypher-os.de.gnome.enable = lib.mkDefault true;
      cypher-os.dm.gdm.enable = lib.mkDefault true;
      cypher-os.gaming.enable = lib.mkDefault true;
      cypher-os.gaming.steam.enable = lib.mkDefault true;

      # ─────────────────────────────────────────────────────────────────────────────
      # DEVOPS INFRASTRUCTURE
      # ─────────────────────────────────────────────────────────────────────────────
      cypher-os.devops.enable = lib.mkDefault true;
      cypher-os.devops.containers.enable = lib.mkDefault true;
      cypher-os.devops.kubernetes.enable = lib.mkDefault true;
      cypher-os.devops.databases.enable = lib.mkDefault true;
      cypher-os.devops.iac.enable = lib.mkDefault true;
      cypher-os.devops.secrets.enable = lib.mkDefault true;
      cypher-os.devops.n8n.enable = lib.mkDefault true;
      # ─────────────────────────────────────────────────────────────────────────────
      # VIRTUALISATION HELPERS TOGGLE
      # ─────────────────────────────────────────────────────────────────────────────
      cypher-os.virtualisation.helpers.enable = lib.mkDefault true;
    })

    # ── Server profile cascade ───────────────────────────────────────────────
    # No DE or DM — their mkEnableOption defaults are already false.
    # Nothing to cascade; the block is here for symmetry and future additions.
    (lib.mkIf config.cypher-os.profile.server.enable {
      # ─────────────────────────────────────────────────────────────────────────────
      # DEVOPS INFRASTRUCTURE
      # ─────────────────────────────────────────────────────────────────────────────
      cypher-os.devops.enable = lib.mkDefault true;
      cypher-os.devops.containers.enable = lib.mkDefault true;
      cypher-os.devops.kubernetes.enable = lib.mkDefault true;
      cypher-os.devops.databases.enable = lib.mkDefault true;
      cypher-os.devops.iac.enable = lib.mkDefault true;
      cypher-os.devops.secrets.enable = lib.mkDefault true;
      # ─────────────────────────────────────────────────────────────────────────────
      # VIRTUALISATION HELPERS TOGGLE
      # ─────────────────────────────────────────────────────────────────────────────
      cypher-os.virtualisation.helpers.enable = lib.mkDefault false;
    })

  ];
}
