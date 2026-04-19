# modules/common/dev.nix
#
# Home manager module for Development environment: runtime tooling, compilers,
# language servers, and ecosystem-specific engine wiring.
#
# WHAT THIS FILE OWNS:
#   - Dev packages available in every shell session (Node, Python, Docker CLI, etc.)
#   - Persistent environment variables that wire tooling to Nix-managed binaries
#   - Shell integrations that belong to the dev environment (e.g. direnv)
#   - Language runtimes and version managers (Rust, Go, Zig, Lua, Python, Node.js)
#   - Build toolchain fundamentals (gnumake, libgcc)
#   - Language-adjacent CLI tools (bun, deno)

# WHAT THIS FILE DOES NOT OWN:
#   - Project-specific devShells — those live in each project's flake.nix
#   - Secrets or credentials — those are never in Nix
#   - Language-specific LSPs tied to an editor — those live in the relevant
#     editor module (e.g. modules/apps/vscode.nix or neovim.nix)
#   - LSP servers — installed via mason.nvim in CypherIDE (runtime managed, not Nix)
#   - Project-level dependencies — those live in each project's lock files
#     (Cargo.lock, go.sum, package-lock.json, etc.)
#   - Python virtual environments — created per-project with `uv venv`
#
# HOME MANAGER vs SYSTEM LEVEL:
#   Language tooling lives in Home Manager  rather than configuration.nix
#   because:
#     a) You want these on non-NixOS hosts too (Arch, Debian homeConfigurations)
#     b) User-space package management is the right scope for dev tools
#   Exception: none. All languages below are user-space tools, no daemon needed.
#
# PYTHON TOOLING DECISION:
#   pyenv is explicitly excluded (see comment). uv is the recommended default.
#   python3 is included as the system interpreter for scripts and tooling.
#
#   pyenv: manages Python version installation by compiling from source.
#   On NixOS, this conflicts deeply with the Nix store's immutable paths.
#   pyenv tries to install to ~/.pyenv and link system headers — headers that
#   NixOS puts in /nix/store/<hash>-glibc/include, not /usr/include. The
#   result is a broken build environment that fights you at every step.
#   Verdict: DO NOT USE pyenv on NixOS. Use uv or nix shells instead.
#
#   uv: Astral's Python package manager (written in Rust). Manages Python
#   versions, virtual environments, and package installation in one fast tool.
#   Works correctly on NixOS because it uses its own managed Python installs
#   rather than trying to compile against system headers.
#   Verdict: DEFAULT CHOICE. Fast, correct, modern.
#
#   nix develop / nix shell: the "pure NixOS" approach. Pin Python version and
#   packages declaratively per project. Zero conflicts, fully reproducible.
#   Steeper learning curve. Consider migrating key projects to this pattern over
#   time. Not mutually exclusive with uv for quick scripts.
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
  options.cypher-os.apps.dev.enable = lib.mkEnableOption "CypherOS development environment";

  config = lib.mkIf (
    config.cypher-os.apps.enable &&
    config.cypher-os.apps.dev.enable ) {

      # Import modules
      imports = [
        ./git.nix
        ./ssh.nix
      ];

      # Enable options from imported modules
      cypher-os.apps.dev.git.enable = lib.mkDefault true;
      cypher-os.apps.dev.ssh.enable = lib.mkDefault true;

      # Install The rest of the dev tooling.
      home.packages = with pkgs; [
        # ── ANDROID  ──────────────────────────────────────────────────
        # android-studio # installed via modules/apps/editor/default.nix
        android-tools # adb + fastboot — enable when you start using a device
        flutter # includes dart SDK
        kotlin
        # kotlin-language-server

        # ── LSP servers + Formatters ──────────────────────────────────────────────────
        # LSP servers and formatters referenced in settings above
        nixd             # Nix language server (nix.serverPath)
        nixfmt-rfc-style # Nix formatter (nix.serverSettings.nixd.formatting.command)
        shellcheck       # Bash linting (shellcheck.executablePath)

        # ── JavaScript / Node.js ──────────────────────────────────────────────────
        pnpm  # Fast, disk-efficient package manager (preferred over npm)

        # ── Node.js ───────────────────────────────────────────────────────────────
        # nodejs_22: Node.js LTS v22. Required for your Next.js and TypeScript work.
        # Includes npm. For version management across projects, consider using
        # fnm (Fast Node Manager) or nix shells with pinned Node versions.
        # Usage: node --version   npm --version
        nodejs_20        # pinned to LTS; change to nodejs if you want latest
        #nodejs_22
        #nodejs          # Node.js runtime — provides `node` and `npm`

        # ──────── BUN ─────────────────────────────────────────────────────────────
        # bun: fast JavaScript runtime, bundler, transpiler and package manager
        # all in one. Subset of Node.js
        # API compatibility with much faster startup and install times. Good for:
        #   - Scripts where startup speed matters
        #   - Workspaces where you want faster `bun install` vs `npm install`
        #   - Running TypeScript files directly: bun script.ts
        # Not a full Node replacement yet, but increasingly capable.
        bun

        # deno: secure-by-default JavaScript/TypeScript runtime. Explicit permission
        # model (no file/network access without flags), built-in formatter/linter,
        # TypeScript without a build step. Learn its philosophy alongside Node/Bun.
        # Usage: deno run --allow-net script.ts
        deno

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
        # python3: the CPython interpreter. Used for scripts, automation, data work,
        # and as the runtime for Python-based tools (ansible, etc.).
        # Note: this is the bare interpreter. For project dependencies, use uv below.
        python3          # CPython interpreter

        # uv: Astral's Python package and project manager. Replaces pip, venv, pipx,
        # and pyenv in one fast (Rust-native) tool.
        # Key operations:
        #   uv python install 3.12    # install a Python version
        #   uv venv                   # create a virtual environment
        #   uv pip install requests   # install into the venv
        #   uv run script.py          # run with the venv active
        #   uv tool install ruff      # install a global CLI tool
        # On NixOS: preferred over pyenv (see module header for full rationale).
        uv

        # python3Packages.virtualenv: the traditional venv tool. Included as a
        # fallback for scripts and tutorials that explicitly call `virtualenv`
        # rather than `python -m venv` or `uv venv`. Most new code won't need it.
        python3Packages.virtualenv
        #python3Packages.pip  # Package installer (use venv per project)
        pipx # install Python CLI tools in isolated envs

        # ── General tooling ───────────────────────────────────────────────────────
        #jq               # JSON processor — useful for inspecting API responses, CI
        #httpie           # Human-friendly HTTP client; complements curl for API dev
        #direnv           # Per-directory env loading (.envrc); integrates with flakes

        # ── Build Toolchain Fundamentals ──────────────────────────────────────────
        # gnumake: the GNU make build system. Required by many native build processes
        # (C extensions in Python packages, some Rust crates, Node.js native modules).
        gnumake

        # libgcc: GCC runtime libraries. Needed for linking compiled binaries and
        # running programs that depend on GCC's runtime (libgcc_s, libstdc++).
        # Most native compilation on Linux depends on this being present.
        libgcc

        cmake
        gcc
        vcpkg            # C++ Library Manager for Windows, Linux, and macOS

        # ── Rust ──────────────────────────────────────────────────────────────────
        # rustup: the official Rust toolchain manager. Installs rustc, cargo, and
        # the standard library. Manages multiple toolchain versions (stable, beta,
        # nightly) and targets (for cross-compilation).
        # Usage: rustup toolchain install stable && rustup default stable
        # After install: cargo --version   rustc --version
        #
        # NOTE: rustup on NixOS requires RUSTUP_HOME and CARGO_HOME to be set.
        # zsh.nix should export:
        #   export RUSTUP_HOME="$HOME/.rustup"
        #   export CARGO_HOME="$HOME/.cargo"
        #   export PATH="$CARGO_HOME/bin:$PATH"
        rustup

        # ── Go ────────────────────────────────────────────────────────────────────
        # go: the Go toolchain. Includes go build, go test, go get, gofmt, and the
        # Go standard library. Go tools (kubectl, k3d, many DevOps CLIs) are written
        # in Go — having the toolchain lets you build from source when needed.
        # Usage: go version   go build ./...   go run main.go
        go

        # ── Zig ───────────────────────────────────────────────────────────────────
        # zig: Zig language compiler and build system. Low-level systems language
        # with manual memory management and C interop. Also functions as a C/C++
        # cross-compiler (zig cc). Increasingly used as a C toolchain replacement.
        # Usage: zig version   zig build   zig cc (as a C compiler)
        zig

        # ── Lua ───────────────────────────────────────────────────────────────────
        # lua: the Lua interpreter. Required for CypherIDE (Neovim config is written
        # in Lua). Also used in game scripting, Redis scripting, and nginx config.
        # Usage: lua --version   lua script.lua
        lua

        openssl # Cryptographic library that implements the SSL and TLS protocols

        # ── DEFERRED — Other Languages ────────────────────────────────────────────
        # Add these when you have concrete projects that need them.

        # jdk / temurin-bin: Java Development Kit. Needed for Android SDK, some
        # build tools (Gradle, Maven), and Kotlin development.
        # pkgs.temurin-bin  # OpenJDK-compatible, from Adoptium

        # dotnet-sdk: .NET SDK for C# and F# development.
        # pkgs.dotnet-sdk

        # elixir: functional language on the BEAM VM. If you ever explore Phoenix
        # (web framework) or LiveView.
        # pkgs.elixir

        # haskell tooling: if you want to explore functional programming properly.
        # pkgs.ghc  (Glasgow Haskell Compiler)
        # pkgs.cabal-install
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
    };
}
