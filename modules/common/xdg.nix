# Symlink XDG user dirs into @data so the standard dirs point at your data lake.
# Mount point: ~/DATA (adjust if Phase 0 decides on a different path).
# These are written to ~/.config/user-dirs.dirs and respected by GNOME,
# file managers, and any app that calls xdg-user-dir.
xdg.userDirs = {
  enable     = true;
  createDirectories = false;  # dirs already exist on @data — don't recreate

  documents  = "$HOME/DATA/FILES/dox";
  videos     = "$HOME/DATA/FILES/Videos";
  download   = "$HOME/DATA/FILES/DE_FILES/SHARED/Downloads";
  desktop    = "$HOME/DATA/FILES";          # no separate Desktop dir — point at root
  templates  = "$HOME/DATA/FILES";          # same
  publicShare = "$HOME/DATA/FILES";         # same
  music      = "$HOME/DATA/FILES/Music";
  pictures   = "$HOME/DATA/FILES/DE_FILES/SHARED/Pictures";

  # extraConfig: non-standard dirs that apps sometimes read
  extraConfig = {
    XDG_PROJECTS_DIR = "$HOME/DATA/FILES/PROJECTS";
    # XDG_MEGA_DIR = "$HOME/DATA/FILES/MEGA";
  };
};
