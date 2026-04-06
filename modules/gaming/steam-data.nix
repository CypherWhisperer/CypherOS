# modules/gaming/steam-data.nix  (Home Manager)
#
# Home Manager module for wiring Steam's user-space data directories to their
# canonical locations under my (~/DATA/FILES/GAMING/STEAM_FILES/).
#
# WHAT THIS FILE OWNS:
#   - Symlinks from ~/.local/share/Steam/{userdata,steamapps} → STEAM_FILES/Steam/
#   - A migration activation script that handles the "Steam already created
#     ~/.local/share/Steam/ before HM ran" scenario
#
# WHAT THIS FILE DOES NOT OWN:
#   - programs.steam — that lives in the NixOS system config (steam.nix)
#   - The Steam binary, kernel options, udev rules — all system-level
#   - SteamLibrary registration — done once in Steam UI > Settings > Storage;
#     Steam persists this in config/libraryfolders.vdf at runtime
#   - Game installations — imperative, managed by Steam
#
# ARCHITECTURE RATIONALE:
#   Steam's data root (~/.local/share/Steam/) contains two categories:
#
#   1. RUNTIME BLOBS — Steam re-downloads and manages these on every update:
#        linux32/, linux64/, ubuntu12_32/, ubuntu12_64/, bin/, package/,
#        bootstrap.tar.xz, steam.sh, *.dll, *.so, steamrt64/, clientui/, etc.
#      → Do NOT symlink, back up, or manage these. Let Steam own them entirely.
#
#   2. PERSONAL DATA — your saves, credentials, and game installs:
#        userdata/   — per-account save data, screenshots, controller profiles
#        steamapps/  — installed games (if you choose to keep them here vs
#                      in SteamLibrary; for CypherOS, SteamLibrary is preferred)
#      → These are symlinked to STEAM_FILES/Steam/ so they survive reinstalls,
#        are backed up with my personal data, and are shared across OS lenses.
#
# CROSS-OS SHARING (CypherOS context):
#   userdata/ and steamapps/ are safe to share across OSs.
#   because they are game data, not OS-specific runtime binaries.
#   config/ is intentionally NOT shared — Steam embeds machine context in it
#   and will re-challenge Steam Guard on OS switches if config/ is shared.
#   Let config/ regenerate per OS lens; this is correct behavior.
#
# STEMLIBRARY:
#   ~/DATA/FILES/GAMING/STEAM_FILES/SteamLibrary/ is our secondary game store.
#   Register it once: Steam > Settings > Storage > Add Library Folder.
#   Steam writes the path to config/libraryfolders.vdf — no Nix declaration needed.
#   Games installed there are visible to any OS lens that has that path mounted.
#
# MIGRATION (first home-manager switch on a machine where Steam has already run):
#   If ~/.local/share/Steam/ already exists with real content, the activation
#   script below will back it up rather than clobber it, then create the symlinks.
#   After the switch, you can inspect the backup and merge userdata/ manually if needed.
#
# FIRST-RUN ORDER:
#   1. home-manager switch  (creates the symlink structure)
#   2. Launch Steam         (it self-updates into ~/.local/share/Steam/,
#                            finds userdata/ and steamapps/ already symlinked)
#   3. Settings > Storage > Add ~/DATA/FILES/GAMING/STEAM_FILES/SteamLibrary/

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Canonical source paths — all under your personal DATA tree
  steamFilesRoot = "${config.home.homeDirectory}/DATA/FILES/GAMING/STEAM_FILES";
  steamDataSrc = "${steamFilesRoot}/Steam";
  # steamLibrarySrc = "${steamFilesRoot}/SteamLibrary";

  # Steam's expected XDG data location
  steamXdgRoot = "${config.home.homeDirectory}/.local/share/Steam";

in
{
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

    # ── Back up and clear any pre-existing real directories ──────────────────
    # We check: if the path exists AND is not already a symlink → back up.
    for dir in userdata steamapps; do
      TARGET="$STEAM_XDG/$dir"
      if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
        echo "[steam-data] WARNING: $TARGET exists and is not a symlink."
        echo "[steam-data] Backing up to $TARGET.bak-$TIMESTAMP"
        ${pkgs.coreutils}/bin/mv "$TARGET" "$TARGET.bak-$TIMESTAMP"
        echo "[steam-data] Inspect the backup and merge into $STEAM_SRC/$dir if needed."
      fi
    done
  '';
}
