# security oriented software applications and tools
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    keepassxc

    # ── Security & Networking ─────────────────────────────────────────────────
    nmap
    wireshark
    tor
    tcpdump
    strace
    gobuster
  ];
}
