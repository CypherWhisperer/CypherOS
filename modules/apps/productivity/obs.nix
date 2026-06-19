# modules/apps/productivity/obs.nix
#
# OBS Studio — Home Manager module.
#
# Manages OBS via the HM programs.obs-studio module, which is required for
# catppuccin/nix to inject the Catppuccin theme into ~/.config/obs-studio/themes/.
# Installing OBS via environment.systemPackages bypasses this hook entirely.
#
# Catppuccin theming is applied via catppuccin/nix's programs.obs-studio module,
# which writes the theme files and sets the active theme in OBS's global config.
# With catppuccin.autoEnable = true set globally, the catppuccin sub-option is
# enabled automatically — no explicit programs.obs-studio.catppuccin.enable needed.
#
# Sources:
#   https://nix.catppuccin.com/options/v1.1/home/programs.obs-studio/
#   https://github.com/catppuccin/obs
#   https://mynixos.com/home-manager/options/programs.obs-studio

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config =
    lib.mkIf
      (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.obs.enable)
      {

        programs.obs-studio = {
          enable = true;

          # ── Package ──────────────────────────────────────────────────────────
          # Use the default nixpkgs OBS; override here if you need a custom fork.
          package = pkgs.obs-studio;

          # ── Plugins ──────────────────────────────────────────────────────────
          # Add plugins as needed. Each entry is a derivation from pkgs.obs-studio-plugins.
          # Common picks:
          plugins = with pkgs.obs-studio-plugins; [
            obs-vkcapture # Vulkan/OpenGL game capture on Wayland
            obs-pipewire-audio-capture # Per-application audio capture via PipeWire
            wlrobs # wlroots-based Wayland screen capture
            # obs-backgroundremoval  # AI background removal (heavy — enable if needed)
            # obs-move-transition    # Smooth move transitions between scenes
            # obs-source-clone       # Clone sources across scenes
          ];
        };
      };
}
