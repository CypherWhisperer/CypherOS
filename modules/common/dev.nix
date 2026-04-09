# modules/common/dev.nix
#
# Development environment: runtime tooling, compilers, language servers,
# and ecosystem-specific engine wiring.
#
# WHAT THIS FILE OWNS:
#   - Dev packages available in every shell session (Node, Python, Docker CLI, etc.)
#   - Persistent environment variables that wire tooling to Nix-managed binaries
#   - Shell integrations that belong to the dev environment (e.g. direnv)
#
# WHAT THIS FILE DOES NOT OWN:
#   - Project-specific devShells — those live in each project's flake.nix
#   - Secrets or credentials — those are never in Nix
#   - Language-specific LSPs tied to an editor — those live in the relevant
#     editor module (e.g. modules/apps/vscode.nix or neovim.nix)
#
# ── Prisma / Node.js note ────────────────────────────────────────────────────
#
# NixOS has a non-standard filesystem layout (no /lib/ld-linux.so), so Prisma
# cannot use its default strategy of downloading precompiled engine binaries
# from binaries.prisma.sh at install time — those binaries are ELF executables
# linked against glibc paths that don't exist on NixOS.
#
# The fix: declare prisma-engines from nixpkgs and expose the binary paths via
# home.sessionVariables. Prisma reads these env vars before attempting any
# download, so the download is skipped entirely.
#
# home.sessionVariables vs shellHook
#   shellHook only fires inside `nix develop` / `nix-shell` sub-shells.
#   home.sessionVariables writes into your shell's login environment (via
#   ~/.nix-profile/etc/profile.d/hm-session-vars.sh), so these vars are
#   present in every terminal, every project, every tool that inherits your
#   environment — including Cursor, Ghostty tabs, and any Node process
#   that spawns Prisma. No per-project boilerplate needed.
#
# Version alignment:
#   nixpkgs keeps nodePackages.prisma and prisma-engines on compatible
#   versions. If a project pins a specific Prisma CLI version in package.json
#   that diverges significantly from the nixpkgs revision in your flake.lock,
#   you may see API mismatch warnings. Handle that at the project level with a
#   devShell override — it is an edge case, not the common path.
# ─────────────────────────────────────────────────────────────────────────────

{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [

    # ── JavaScript / Node.js ──────────────────────────────────────────────────
    #nodejs          # Node.js runtime — provides `node` and `npm`
    pnpm  # Fast, disk-efficient package manager (preferred over npm)

    # Prisma CLI — the `prisma` binary used by `bunx prisma`, `npx prisma`, etc.
    # Paired with prisma-engines below; nixpkgs keeps them version-aligned.
    # nodePackages.prisma # <- nodePackages was  removed due to maintenance issues
    prisma_7

    # Prisma engine binaries — Nix-packaged so no ELF download is attempted.
    # The four binaries exposed here cover all Prisma operations:
    #   schema-engine  → `prisma migrate`, `prisma db push`
    #   query-engine   → runtime query execution (binary mode)
    #   libquery_engine → runtime query execution (library/node-api mode, default)
    #   prisma-fmt     → `prisma format`, editor schema formatting
    prisma-engines

    # ── Python ────────────────────────────────────────────────────────────────
    #python3          # CPython interpreter
    #python3Packages.pip  # Package installer (use venv per project)

    # ── Containers ────────────────────────────────────────────────────────────
    #docker           # Docker CLI — daemon is managed by the host OS, not HM
    #docker-compose   # Multi-container orchestration for local dev stacks

    # ── General tooling ───────────────────────────────────────────────────────
    #jq               # JSON processor — useful for inspecting API responses, CI
    #httpie           # Human-friendly HTTP client; complements curl for API dev
    #direnv           # Per-directory env loading (.envrc); integrates with flakes

  ];

  # ── Prisma engine path wiring ───────────────────────────────────────────────
  #
  # These four variables are the canonical interface between the Prisma CLI
  # and the engine binaries. When set, Prisma skips all download logic and
  # uses the paths directly — which is exactly what we want on NixOS.
  #
  # The `${pkgs.prisma-engines}` interpolation is resolved at `home-manager
  # switch` time and written as a literal store path (e.g.
  # /nix/store/abc123-prisma-engines-5.x.x/bin/schema-engine) into your
  # shell environment file. It will not drift between switches unless you
  # explicitly update your flake inputs.
  # ───────────────────────────────────────────────────────────────────────────
  home.sessionVariables = {
    PRISMA_SCHEMA_ENGINE_BINARY  = "${pkgs.prisma-engines}/bin/schema-engine";
    PRISMA_QUERY_ENGINE_BINARY   = "${pkgs.prisma-engines}/bin/query-engine";
    PRISMA_QUERY_ENGINE_LIBRARY  = "${pkgs.prisma-engines}/lib/libquery_engine.node";
    PRISMA_FMT_BINARY            = "${pkgs.prisma-engines}/bin/prisma-fmt";
  };

  # ── direnv shell hook ───────────────────────────────────────────────────────
  #
  # programs.direnv.enable wires direnv into your shell (zsh, bash) so that
  # entering a directory with a .envrc automatically loads its environment.
  # enableNixDirenvIntegration enables `use flake` in .envrc files — meaning
  # per-project devShells activate automatically on `cd`, no `nix develop`
  # needed. This is the recommended workflow for flake-based projects.
  # ───────────────────────────────────────────────────────────────────────────
  #programs.direnv = {
  #  enable                       = true;
  #  enableZshIntegration         = true;  # hooks into the zsh session managed by zsh.nix
  #  nix-direnv.enable            = true;  # enables `use flake` in .envrc
  #};
}
