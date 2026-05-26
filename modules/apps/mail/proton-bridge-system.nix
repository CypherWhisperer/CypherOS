{ config, lib, ... }:

let
  cfg = config.cypher-os.apps.mail.protonBridge;
  inherit (lib) mkIf;
in
{
  imports = [ ./options.nix ];

  config = mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.mail.enable && cfg.enable) {

    # Bridge requires the freedesktop.org Secret Service API to persist its
    # Proton session token across reboots. GNOME Keyring is the supported
    # Secret Service backend on NixOS/GNOME.
    services.gnome.gnome-keyring.enable = true;

    # Ensure PAM unlocks the login keyring on session start so Bridge can
    # retrieve its stored credentials without user interaction on subsequent
    # boots (after the one-time interactive login ceremony).
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
