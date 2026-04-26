{
  config,
  lib,
  ...
}:

{
  imports = [
    ./options.nix
  ];

  config =
    lib.mkIf
      (
        config.cypher-os.shell.enable # Ensure shell is enabled
        && config.cypher-os.shell.zsh.enable # ensure zsh is enabled
      )
      {
        # ─────────────────────────────────────────────────────────────────────────────
        # ZSH (SYSTEM LEVEL)
        # ─────────────────────────────────────────────────────────────────────────────
        # Setting the user shell to pkgs.zsh - as done - requires zsh to be enabled at the
        # system level — NixOS won't add it to /etc/shells otherwise, which breaks login.
        programs.zsh.enable = true;
      };
}
