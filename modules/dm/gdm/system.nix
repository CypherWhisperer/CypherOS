# modules/dm/gdm/system.nix
# GDM (GNOME Display Manager) module for CypherOS.
# WHAT THIS FILE OWNS:
#   - cypher-os.dm.gdm.enable option
#   - Enabling GDM when that option is true
#
# GDM (GNOME Display Manager) is the login screen. It handles session
# selection and hands off to either the GNOME Wayland or X11 session.
{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.profile.desktop.enable && config.cypher-os.dm.gdm.enable) {
    services.displayManager.gdm = {
      enable = true;
      # This option is no longer supported with GNOME 50. This came after a
      # flake update 2026-06-05.
      # wayland = true; # prefer Wayland sessions; GDM falls back to X11 if needed
    };
  };
}
