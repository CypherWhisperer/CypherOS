# modules/dm/gdm/default.nix
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
  pkgs,
  ...
}:

{
  # What options does this module EXPOSE to the outside world ?
  options = {
    cypher-os.dm.gdm.enable = lib.mkEnableOption "Enable GDM display manager";
  };

  # What does this module DO when those options have certain values?
  config = lib.mkIf config.cypher-os.dm.gdm.enable {
    services.displayManager.gdm = {
      enable = true;
      wayland = true; # prefer Wayland sessions; GDM falls back to X11 if needed
    };
  };
}
