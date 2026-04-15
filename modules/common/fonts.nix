{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    
    # ── Fonts ────────────────────────────────────────────────────────────────
    # Cantarell: GNOME's default UI font — declared here for non-NixOS hosts.
    # On NixOS it comes in via the GNOME system packages automatically.
    cantarell-fonts
    noto-fonts-color-emoji # basic
    #noto-fonts-cjk-sans
    #noto-fonts-extra
    nerd-fonts.caskaydia-cove # font for kitty + ghostty

     # As of November 2024, the nerdfonts package has been separated into 
    # individual packages under the namespace nerd-fonts. If your system throws
    # errors or warnings about terminus-nerdfont being redundant, you should 
    # replace the override method with the specific package:
    nerd-fonts.jetbrains-mono

    #fira-code
    nerd-fonts.fira-code        # Fira Code: 
    nerd-fonts.hack             # Hack: 
    nerd-fonts.source-code-pro  # Source Code Pro: 
    nerd-fonts.cascadia-code    # Cascadia Code: 
    nerd-fonts.iosevka          # Iosevka: 
    nerd-fonts.victor-mono      # Victor Mono: 
    nerd-fonts.jetbrains-mono   # JetBrains Mono: 
    nerd-fonts.lilex            # Lilex: 
    nerd-fonts.monaspace        # Monaspace: 
    nerd-fonts.noto             # Noto: 
    nerd-fonts.roboto-mono      # Roboto Mono: 
    nerd-fonts.ubuntu-mono      # Ubuntu Mono: 
    nerd-fonts.meslo-lg         # Meslo LG: 
    nerd-fonts.sauce-code-pro   # Sauce Code Pro: 
  ];
}
   
