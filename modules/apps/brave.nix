# modules/apps/brave.nix
#
# Home Manager module for Brave browser configuration.
#
# WHAT THIS FILE OWNS:
#   - Brave installation (via nixpkgs)
#   - ~/.config/BraveSoftware/Brave-Browser/Default/Preferences (seeded, not symlinked)
#   - ~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks  (seeded, not symlinked)
#
# WHAT THIS FILE DOES NOT OWN:
#   - Runtime state: Cache, Session Storage, History, Cookies, Login Data
#   - Extension blobs — Brave auto-installs from the Web Store using the
#     extension IDs embedded in the seeded Preferences file
#   - Any file not explicitly listed under home.activation below
#
# SEEDING STRATEGY (home.activation copy, NOT home.file symlink):
#   Brave requires mutable config files — it writes back to Preferences
#   on every launch. A symlink into the Nix store would be read-only and
#   cause Brave to silently discard settings changes or corrupt the profile.
#
#   home.activation copies the seed files once on a fresh install (guarded
#   by [ ! -f "$TARGET" ]). On subsequent `home-manager switch` runs the
#   guard prevents overwriting Brave's live state.
#
#   To force a re-seed (e.g. after a wipe or deliberate reset):
#     rm ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
#     rm ~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks
#     home-manager switch
#
# UPDATING THE SEED FILES:
#   When you want to snapshot your current Brave state into the repo:
#     cp ~/.config/BraveSoftware/Brave-Browser/Default/Preferences \
#        <repo>/configs/browser/brave/Preferences
#     cp ~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks \
#        <repo>/configs/browser/brave/Bookmarks
#     git add -p   # review the diff before committing
#     git commit -m "chore(brave): snapshot settings/bookmarks"
#
#   Note: Preferences will contain runtime noise (timestamps, metrics, etc.).
#   This is acceptable for now — the goal is reproducibility, not clean diffs.
#   See the "FUTURE" section below if that becomes a concern.
#
# EXTENSIONS:
#   Installed extensions are encoded in Preferences under
#   `extensions.settings`. Brave reads those IDs on first launch and
#   auto-installs them from the Chrome Web Store. No extension source
#   directories are tracked in this repo.
#
# FUTURE (when you want cleaner diffs):
#   Graduate to a jq-based merge script that extracts only the keys you
#   care about (extensions.settings, extensions.theme, browser.*, search.*)
#   and deep-merges them into a Brave-generated Preferences on activation.
#   This trades setup complexity for a noise-free, auditable config.
#
# VERIFYING THE SETUP:
#   1. After `home-manager switch`, check the files exist and are mutable:
#        ls -la ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
#        # Should be a regular file (-rw-r--r--), NOT a symlink (lrwxrwxrwx)
#   2. Launch Brave — settings, theme, and extension IDs should be present.
#   3. Extensions will auto-install on first launch (requires internet).

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Absolute path to the seed files inside the Nix store.
  # pkgs.lib.cleanSource or a plain path both work here; a plain
  # repo-relative path is simplest and is what Home Manager expects.
  braveConfigDir = ../../configs/browser/brave;

in
{
  # ── Package ───────────────────────────────────────────────────────────────
  home.packages = [ pkgs.brave ];

  # ── Seed Activation ───────────────────────────────────────────────────────
  #
  # entryAfter ["writeBoundary"]: runs after HM has written all managed files,
  # so we're not racing with any other home.file declarations.
  #
  # $DRY_RUN_CMD: HM injects this as an empty string on real runs and as
  # "echo" on dry runs (`home-manager switch --dry-run`), letting you preview
  # what would happen without touching the filesystem.
  #
  # $VERBOSE_ECHO: prints the message only when --verbose is passed.
  home.activation.seedBraveConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser/Default"

    $DRY_RUN_CMD mkdir -p "$BRAVE_DIR"
    $DRY_RUN_CMD mkdir -p "$BRAVE_DIR/sanitized_background_images"

    # ── Seed flat config files ─────────────────────────────────────────────
    for seed_file in Preferences Bookmarks; do
      TARGET="$BRAVE_DIR/$seed_file"
      SOURCE="${braveConfigDir}/$seed_file"

      if [ ! -f "$TARGET" ]; then
        $VERBOSE_ECHO "Brave: seeding $seed_file → $TARGET"
        $DRY_RUN_CMD cp "$SOURCE" "$TARGET"
        $DRY_RUN_CMD chmod 644 "$TARGET"
      else
        $VERBOSE_ECHO "Brave: $seed_file already present, skipping"
      fi
    done

    # ── Seed background image ──────────────────────────────────────────────
    # Brave reads this on launch for the custom NTP background.
    # The filename must match exactly what Preferences references internally.
    BG_TARGET="$BRAVE_DIR/sanitized_background_images/brave_bg.jpg"
    BG_SOURCE="${braveConfigDir}/sanitized_background_images/brave_bg.jpg"

    if [ ! -f "$BG_TARGET" ]; then
      $VERBOSE_ECHO "Brave: seeding NTP background → $BG_TARGET"
      $DRY_RUN_CMD cp "$BG_SOURCE" "$BG_TARGET"
      $DRY_RUN_CMD chmod 644 "$BG_TARGET"
    else
      $VERBOSE_ECHO "Brave: NTP background already present, skipping"
    fi
  '';
}
