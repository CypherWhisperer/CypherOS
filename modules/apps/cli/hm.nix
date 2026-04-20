{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.cli.enable ) {

      # enabling CLI tools with their own modules
      cypher-os.apps.cli.btop.enable = lib.mkDefault true;
      cypher-os.apps.cli.htop.enable = lib.mkDefault true;
      cypher-os.apps.cli.tmux.enable = lib.mkDefault true;
      cypher-os.apps.cli.fastfetch.enable = lib.mkDefault true;

      # Install the other CLI tools that don't have their own modules here.
      home.packages = with pkgs; [
        # ── CLI Tooling ───────────────────────────────────────────────────────────
        # INSTALLED VIA programs.[] -> (tmux, zsh, git)
        fzf # fuzzy finder — pipes, history search, file selection
        ripgrep # rg: fast grep replacement, respects .gitignore
        bat # cat with syntax highlighting and line numbers
        fd # find replacement: simpler syntax, faster
        tree # directory tree display
        ranger # vim-keyed terminal file manager


        curl
        wget
        pass # password-store: GPG-backed password manager
        rsync
        keychain # SSH/GPG key agent manager across sessions
        lf
        yazi # checkout yaziPlugins.[plugin] for yazi plugins
        #yaziPlugins.mediainfo
        #yaziPlugins.time-travel
        #yaziPlugins.[git, gitui, lazygit, vcs-files]
        #yaziPlugins.[starship,no-status, mediainfo, bookmarks, smartpaste,
        #    full-border, wl-clipboard, yatline-catppuccin, relative-motions,
        #    rich-preview, recycle-bin, smart-enter, toggle-pane
        # ] # CUSTOMIZATION
        #
        #yaziPlugins.sudo
        #yaziPlugins.[rsync, chmod
        #yaziPlugins.[ouch,lsar, compress] # archive related
      ];
    };
}
