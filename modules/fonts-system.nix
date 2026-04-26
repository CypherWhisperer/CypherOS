{
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [ options.nix ];

  config = lib.mkIf config.cypher-os.extra-fonts.enable {
    # ─────────────────────────────────────────────────────────────────────────────
    # FONTS (SYSTEM LEVEL)
    # ─────────────────────────────────────────────────────────────────────────────
    # Fonts declared here are available system-wide (GDM login screen, all users).
    # User fonts (in Home Manager) are in addition to these.
    fonts.fontDir.enable = true;
    fonts.enableGhostscriptFonts = true;
    fonts.packages = with pkgs; [
      cantarell-fonts
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono

      #fira-code
      nerd-fonts.fira-code # Fira Code:
      nerd-fonts.hack # Hack:
      #nerd-fonts.source-code-pro  # Source Code Pro:
      #nerd-fonts.cascadia-code    # Cascadia Code:
      #nerd-fonts.iosevka          # Iosevka:
      #nerd-fonts.victor-mono      # Victor Mono:
      nerd-fonts.jetbrains-mono # JetBrains Mono:
      nerd-fonts.lilex # Lilex:
      nerd-fonts.monaspace # Monaspace:
      nerd-fonts.noto # Noto:
      nerd-fonts.roboto-mono # Roboto Mono:
      nerd-fonts.ubuntu-mono # Ubuntu Mono:
      #nerd-fonts.meslo-lg         # Meslo LG:
      nerd-fonts.sauce-code-pro # Sauce Code Pro:
    ];
  };
}
