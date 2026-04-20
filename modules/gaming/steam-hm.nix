{ config, lib, pkgs, ... }:

{
  options.cypher-os.gaming.steam.enable = lib.mkEnableOption "Enable Steam and gaming infrastructure";

  config = lib.mkIf config.cypher-os.gaming.steam.enable (let
    # Canonical source paths — all under your personal DATA tree
    steamFilesRoot = "${config.home.homeDirectory}/DATA/FILES/GAMING/STEAM_FILES";
    steamDataSrc = "${steamFilesRoot}/Steam";
    # steamLibrarySrc = "${steamFilesRoot}/SteamLibrary";

    # Steam's expected XDG data location
    steamXdgRoot = "${config.home.homeDirectory}/.local/share/Steam";

  in {
    # ── Symlinks ────────────────────────────────────────────────────────────────
    #
    # home.file creates a symlink at the HM-managed path pointing to `source`.
    # `recursive = false` (default) means HM creates a single symlink, not a
    # mirror — which is what we want: ~/.local/share/Steam/userdata → our path.
    #
    # IMPORTANT: home.file will refuse to overwrite paths that were not created
    # by Home Manager. The activation script below handles pre-existing dirs.

    home.file = {
      # ~/.local/share/Steam/userdata → STEAM_FILES/Steam/userdata
      ".local/share/Steam/userdata" = {
        source = "${steamDataSrc}/userdata";
        # recursive = false → single symlink (correct)
        # The directory at source must already exist; Steam will populate it.
      };

      # ~/.local/share/Steam/steamapps → STEAM_FILES/Steam/steamapps
      # Only if you want the default steamapps location here vs SteamLibrary.
      # uncomment this if you install games at ~/.local/share/Steam/steamapps/.
      #".local/share/Steam/steamapps" = {
      #  source = "${steamDataSrc}/steamapps";
      #};

      # ~/.local/share/Steam/steamapps → STEAM_FILES/Steam/config
      ".local/share/Steam/config" = {
        source = "${steamDataSrc}/config";
      };

    };

    # ── Migration / bootstrap activation ────────────────────────────────────────
    #
    # Runs during every `home-manager switch`, before the home.file symlinks
    # are applied. Handles two scenarios:
    #
    #   a) Fresh machine: ~/.local/share/Steam/ doesn't exist yet.
    #      → Create the parent dir so Steam can self-populate it on first launch.
    #      → Ensure source directories exist so home.file symlinking succeeds.
    #
    #   b) Steam already ran: ~/.local/share/Steam/userdata or steamapps exist
    #      as real directories (not symlinks).
    #      → Back them up with a timestamp suffix, then remove so HM can create
    #        the symlinks. You can merge the backed-up data manually afterward.

    home.activation.steamDataWiring = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      # ── Helpers ──────────────────────────────────────────────────────────────
      STEAM_XDG="${steamXdgRoot}"
      STEAM_SRC="${steamDataSrc}"
      TIMESTAMP=$(date +%Y%m%d-%H%M%S)

      # Ensure the XDG Steam root exists (Steam needs the parent dir present)
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_XDG"

      # Ensure our source directories exist (home.file symlink target must exist)
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_SRC/userdata"
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_SRC/steamapps"
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_SRC/config"

      # ── Back up and clear any pre-existing real directories ──────────────────
      # We check: if the path exists AND is not already a symlink → back up.
      for dir in userdata steamapps config; do
        TARGET="$STEAM_XDG/$dir"
        if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
          echo "[steam-data] WARNING: $TARGET exists and is not a symlink."
          echo "[steam-data] Backing up to $TARGET.bak-$TIMESTAMP"
          ${pkgs.coreutils}/bin/mv "$TARGET" "$TARGET.bak-$TIMESTAMP"
          echo "[steam-data] Inspect the backup and merge into $STEAM_SRC/$dir if needed."
        fi
      done
    '';
  });
}
