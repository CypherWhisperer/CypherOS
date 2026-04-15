# CLI tools: fzf, ripgrep, bat, etc.

{ config, pkgs, lib, ... }:

{
  imports = [
    ../apps/git.nix
    ../apps/zsh.nix
    ../apps/tmux.nix
    ../apps/ssh.nix
    ../apps/htop.nix
    ../apps/btop.nix
    ../apps/fastfetch.nix
    ../apps/vim.nix
    ../apps/neovim.nix    
  ];
  home.packages = with pkgs; [
    
    # ── CLI Tooling ───────────────────────────────────────────────────────────
    # INSTALLED VIA programs.[] -> (tmux, zsh, git)
    fzf # fuzzy finder — pipes, history search, file selection
    ripgrep # rg: fast grep replacement, respects .gitignore
    bat # cat with syntax highlighting and line numbers
    fd # find replacement: simpler syntax, faster
    fastfetch # system info display (neofetch successor)
    btop # interactive resource monitor
    htop # lighter resource monitor
    tree # directory tree display
    ranger # vim-keyed terminal file manager
    fish
    nushell
 
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
}

