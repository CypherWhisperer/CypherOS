# devenv.nix
#
# devenv + direnv — per-project declarative development environments.
#
# devenv: a Nix-based tool for declaring reproducible project shells with
#   services (MySQL, Redis, etc.), language toolchains, and process management.
#   Invoked per-project via `devenv shell` or `devenv up`.
#
# direnv: a shell hook that watches for .envrc files. When you cd into a
#   directory containing .envrc (with `use flake` or `use devenv`), the
#   declared environment activates automatically. cd out — it unloads.
#
# nix-direnv: the Nix-aware backend for direnv. Replaces direnv's naive
#   shell evaluation with a proper nix develop call, with caching so
#   re-entering a directory doesn't re-evaluate the flake from scratch.

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.apps.dev.enable && config.cypher-os.apps.dev.devenv.enable) {

    home.packages = [
      pkgs.devenv
    ];

    # programs.direnv handles both the direnv binary and the nix-direnv
    # integration in one block. enableNixDirenvIntegration replaces the
    # default direnv stdlib with nix-direnv's, which:
    #   - caches devShell evaluations (fast re-entry)
    #   - keeps shells alive across `nixos-rebuild switch` (GC-safe)
    #   - supports `use flake` and `use devenv` directives in .envrc
    programs.direnv = {
      enable = true;
      enableBashIntegration = true; # hooks into bash if you ever drop to it
      enableZshIntegration = true; # adjust to your actual shell
      nix-direnv.enable = true; # this is the key — activates nix-direnv
    };
  };
}
