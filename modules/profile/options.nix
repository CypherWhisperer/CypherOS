{
  lib,
  ...
}:

{
  options = {
    cypher-os.profile.desktop = {
      enable = lib.mkEnableOption "CypherOS desktop profile (DE + DM + GUI apps)";
      # Sets up a full desktop environment with apps and display manager.
      # Override individual options in configuration.nix after setting this.
    };

    cypher-os.profile.server = {
      enable = lib.mkEnableOption "CypherOS server profile (CLI + dev, no DE)";
      # Minimal headless profile — no DE, no display manager, no GUI apps.
    };
  };
}
