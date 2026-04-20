# modules/common/xdg.nix
#
# Owns two things:
#   1. XDG user dirs  — where standard dirs (Downloads, Videos, etc.) live on @data
#   2. GTK bookmarks  — what shows up in file manager sidebars across all DEs
#
# Applied everywhere (via modules/common/default.nix) for cross-DE consistency.
# File managers that respect ~/.config/gtk-3.0/bookmarks:
#   Nautilus, Dolphin, Thunar, Nemo, PCManFM — all of them.
#
# Symlink XDG user dirs into @data so the standard dirs point at our data lake.
# Mount point: ~/DATA/
# These are written to ~/.config/user-dirs.dirs and respected by GNOME,
# file managers, and any app that calls xdg-user-dir.

{
  config, # <- Without this, xdg is not in scope — it's a Home Manager
  pkgs, # option, not a bare Nix attribute. The module system
  lib, # injects `config`, `pkgs`, `lib`, and the option tree
  ... # (including `xdg`) only when the file is a proper module function like this.
}:

{
  config = lib.mkIf (
    config.cypher-os.apps.common.xdg.enable &&
    config.cypher-os.profile.desktop.enable ) {

    # ── 1. XDG user dirs ────────────────────────────────────────────────────────
    #
    # xdg.userDirs is a Home Manager option available in home-manager/modules/misc/xdg.nix.
    # In NixOS, the system-wide configuration must use environment.etc."xdg/user-dirs.defaults"
    # to set default directory paths, but this does not automatically create the directories for
    # existing users without manual invocation of xdg-user-dirs-update.
    #
    # For Home Manager configurations, xdg.userDirs is the correct and supported method,
    # allowing users to enable, disable, and customize directories like download, documents,
    # and pictures.
    #
    # Writes ~/.config/user-dirs.dirs. Respected by GNOME, all file managers,
    # and any app that calls xdg-user-dir at runtime.
    # createDirectories = false because @data is a BTRFS subvolume that already
    # exists at mount time — letting HM recreate them would fight the mount.
    xdg.userDirs = {
      enable = true;
      createDirectories = false; # dirs already exist on @data — don't recreate

      documents = "$HOME/DATA/FILES/dox";
      videos = "$HOME/DATA/FILES/Videos";
      download = "$HOME/DATA/FILES/DE_FILES/SHARED/Downloads";
      desktop = "$HOME/DATA/FILES"; # no separate Desktop dir — point at root
      templates = "$HOME/DATA/FILES"; # same
      publicShare = "$HOME/DATA/FILES"; # same
      music = "$HOME/DATA/FILES/Music";
      pictures = "$HOME/DATA/FILES/DE_FILES/SHARED/Pictures";

      # extraConfig: non-standard dirs that apps sometimes read
      extraConfig = {
        XDG_PROJECTS_DIR = "$HOME/DATA/FILES/PROJECTS";
        # XDG_MEGA_DIR = "$HOME/DATA/FILES/MEGA";
      };
    };

    # ── 2. GTK bookmarks ────────────────────────────────────────────────────────
    #
    # Format per line:
    #   file:///absolute/path
    #   file:///absolute/path Optional Display Label
    #
    # Rules:
    #   • Path must be absolute — no $HOME, no ~ (file managers expand literally).
    #     Use config.home.homeDirectory to get the runtime home path from Nix.
    #   • Label is optional. Without it, the file manager shows the directory name.
    #     With it, you can write anything — "📥 Downloads", "Projects", etc.
    #   • Order in this file = order in the sidebar. Be intentional.
    #   • Blank lines and comments are NOT valid in the bookmarks file itself —
    #     only in this Nix heredoc. The `text` value below is the rendered file.
    #   • Icons: you cannot set icons here. File managers assign icons based on
    #     whether the path matches a known XDG dir (auto-icon) or falls back to
    #     a generic folder. To get custom icons on non-XDG dirs, you'd need a
    #     .directory file inside each folder — out of scope here, future enhancement.
    #
    # To add a bookmark:
    #   1. Add a line: file://${home}/DATA/FILES/YOUR_PATH Optional Label
    #
    # To add a section separator (supported by Nautilus, not all file managers):
    #   Some file managers treat consecutive bookmarks as grouped. There is no
    #   official separator syntax in the GTK bookmarks format — grouping is visual
    #   only via ordering.

    xdg.configFile."gtk-3.0/bookmarks" =
      let
        home = config.home.homeDirectory; # resolves to /home/cypher-whisperer at eval time
      in
      {
        text = ''
          file://${home}/DATA/FILES/dox Documents
          file://${home}/DATA/FILES/DE_FILES/SHARED/Downloads Downloads
          file://${home}/DATA/FILES/DE_FILES/SHARED/Pictures Pictures
          file://${home}/DATA/FILES/Videos Videos
          file://${home}/DATA/FILES/PROJECTS Projects
          file://${home}/DATA/FILES Vault
          file://${home}/DATA/FILES/Music Music
        '';
        # Uncomment to add more — examples:
        # file://${home}/DATA/FILES/MEGA MEGA
        # file://${home}/DATA/FILES/PROJECTS/pentara-tech Pentara
        # file://${home}/DATA/FILES/DEV Dev
      };
    };
}
