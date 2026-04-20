# security oriented software applications and tools
{ config, pkgs, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.cypher-os.apps.common.security.enable {

      home.packages = with pkgs; [
        # ── Security & Networking ─────────────────────────────────────────────────
        nmap
        tor
        tcpdump
        strace
        gobuster
      ];
    })

    (lib.mkIf (
      config.cypher-os.apps.common.security.enable &&
      config.cypher-os.profile.desktop.enable ) {

      home.packages = with pkgs; [
        # GUI apps that are only relevant if the desktop profile is enabled.
        wireshark
        keepassxc
      ];
    })
  ];
}
