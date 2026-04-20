# modules/profile/default.nix
#
# CypherOS host profiles — meta-switches that configure a host's purpose.
#
# A profile is a convenience layer: it sets a collection of cypher-os options
# to sensible defaults for a given use case. Individual options can always be
# overridden in configuration.nix after the profile is applied.
#
# lib.mkDefault is used throughout — it sets options at a lower priority than
# a normal assignment. This means:
#   cypher-os.profile.desktop.enable = true;   ← enables gnome by default
#   cypher-os.de.gnome.enable = false;         ← this override still wins
#
# IMPORTANT: No `imports` live here. All module imports are handled
# unconditionally in modules/home/default.nix. This file only sets values.

# HOME MANAGER CONCERNS

{ config, lib, ... }:

{
  imports = [
    ./options.nix
  ];

  config = lib.mkMerge [
    # ── Desktop profile defaults ───────────────────────────────────────────
    # Turns on all groups. User can override any of these downward in
    # configuration.nix using a plain assignment (which beats mkDefault).
    #
    (lib.mkIf config.cypher-os.profile.desktop.enable {
      # so that Gnome's Home Manager Module ca 'see' the option set.
      cypher-os.de.gnome.enable = lib.mkDefault true;
      # mkDefault means these activate UNLESS configuration.nix overrides them.
      # Example override: set desktop.enable = true but gdm.enable = false
      # and sddm.enable = true → sddm wins, gdm stays off.
      cypher-os.gaming.minecraft.enable = lib.mkDefault true;

      # apps is always set to true as a default. If you need to
      # override that as an emergency kill-switch, set it to false.
      # cypher-os.apps.enable = lib.mkDefault false;

      cypher-os.apps.common.enable = lib.mkDefault true;
      cypher-os.apps.common.diskUtils.enable = lib.mkDefault true;
      cypher-os.apps.common.fonts.enable = lib.mkDefault true;
      cypher-os.apps.common.proton.enable = lib.mkDefault true;
      cypher-os.apps.common.security.enable = lib.mkDefault true;
      cypher-os.apps.common.xdg.enable = lib.mkDefault true;

      cypher-os.apps.shell.enable = lib.mkDefault true;
      cypher-os.apps.shell.zsh.enable = lib.mkDefault true;

      cypher-os.apps.cli.enable = lib.mkDefault true;
      cypher-os.apps.cli.btop.enable = lib.mkDefault true;
      cypher-os.apps.cli.htop.enable = lib.mkDefault true;
      cypher-os.apps.cli.tmux.enable = lib.mkDefault true;
      cypher-os.apps.cli.fastfetch.enable = lib.mkDefault true;

      cypher-os.apps.dev.enable = lib.mkDefault true;
      cypher-os.apps.dev.ssh.enable = lib.mkDefault true;
      cypher-os.apps.dev.git.enable = lib.mkDefault true;

      cypher-os.apps.editor.enable = lib.mkDefault true;
      cypher-os.apps.editor.vim.enable = lib.mkDefault true;
      cypher-os.apps.editor.neovim.enable = lib.mkDefault true;
      cypher-os.apps.editor.vscode.enable = lib.mkDefault true;

      cypher-os.apps.terminal.enable = lib.mkDefault true;
      cypher-os.apps.terminal.ghostty.enable = lib.mkDefault true;
      cypher-os.apps.terminal.kitty.enable = lib.mkDefault true;

      cypher-os.apps.browser.enable = lib.mkDefault true;
      cypher-os.apps.browser.brave.enable = lib.mkDefault true;
      cypher-os.apps.browser.firefox.enable = lib.mkDefault true;

      cypher-os.apps.productivity.enable = lib.mkDefault true;
      cypher-os.apps.productivity.claude.enable = lib.mkDefault true;
      cypher-os.apps.productivity.obsidian.enable = lib.mkDefault true;

    })

    # ── Server profile defaults ────────────────────────────────────────────
    # Only enables headless-safe groups. GUI groups stay at their mkEnableOption
    # default of false — no need to explicitly set them.
    # apps.enable stays true (its new default) so group conditions still fire.
    #
    (lib.mkIf config.cypher-os.profile.server.enable {
      # No DE or DM — their defaults are already false, nothing to do.

      # GUI groups are absent — mkEnableOption defaults them to false already.
      # apps.enable stays true (its default) so group-level mkIf conditions fire.
      cypher-os.apps.common.enable = lib.mkDefault true;
      cypher-os.apps.shell.enable = lib.mkDefault true;
      cypher-os.apps.cli.enable = lib.mkDefault true;
      cypher-os.apps.editor.enable = lib.mkDefault true;
      cypher-os.apps.dev.enable = lib.mkDefault true;
    })
  ];
}
