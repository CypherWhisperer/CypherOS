{ lib, ... }:

{
  options.cypher-os.apps.cli = {
    enable = lib.mkEnableOption "CLI applications";
    btop.enable = lib.mkEnableOption "btop resource monitor";
    htop.enable = lib.mkEnableOption "htop process viewer";
    tmux.enable = lib.mkEnableOption "tmux terminal multiplexer";
    zellij.enable = lib.mkEnableOption "zellij terminal multiplexer";
    fastfetch.enable = lib.mkEnableOption "fastfetch system info";
  };
}
