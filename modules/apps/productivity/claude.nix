# modules/apps/claude.nix
#
# Claude Desktop — Home Manager module
#
# IMPORTANT: This module handles only the user-space side.
# The overlay that makes pkgs.claude-desktop available MUST be registered
# at the NixOS system level in hosts/nixos-gnome/configuration.nix:
#
#   nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];
#
# Without that, pkgs.claude-desktop will not exist and this module will fail.

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.apps.productivity.enable &&
    config.cypher-os.apps.productivity.claude.enable ) {

    # ── Package ──────────────────────────────────────────────────────────────
    # The package is injected into pkgs by the system-level overlay.
    # Home Manager installs it into the user profile from there.
    home.packages = [ pkgs.claude-desktop ];

    # ── Wayland / display server environment ────────────────────────────────
    # Claude Desktop is Electron-based. On a Wayland session (GNOME on Wayland)
    # it needs these flags to run natively rather than falling back to XWayland.
    # OZONE_PLATFORM tells Chromium/Electron to use the Wayland backend.
    # ELECTRON_OZONE_PLATFORM_HINT=auto lets it decide at runtime — safer than
    # hardcoding "wayland" because it gracefully falls back on XWayland sessions.
    home.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # ── MCP configuration ────────────────────────────────────────────────────
    # ~/.config/Claude/claude_desktop_config.json is the canonical MCP config
    # location. We manage it declaratively so it's version-controlled.
    #
    # NOTE: This path is relative to XDG_CONFIG_HOME. Because gnome.nix sets
    # XDG_CONFIG_HOME=~/.config/profiles/gnome for the GNOME session, Claude
    # Desktop will read from ~/.config/profiles/gnome/Claude/claude_desktop_config.json
    # when launched inside the GNOME XDG profile. This is correct behaviour —
    # each DE profile gets its own MCP server registrations.
    xdg.configFile."Claude/claude_desktop_config.json" = {
      text = builtins.toJSON {
        mcpServers = {
          # Placeholder — add your MCP server entries here, e.g.:
          # filesystem = {
          #   command = "npx";
          #   args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/cypher-whisperer/Projects" ];
          # };
        };
      };
    };
  };
}
