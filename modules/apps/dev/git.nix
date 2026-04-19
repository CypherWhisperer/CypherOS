# modules/apps/git.nix
#
# Home Manager module for Git version control configuration.
#
# WHAT THIS FILE OWNS:
#   - Git identity (name, email)
#   - Core behaviour (defaultBranch, editor, pull strategy, push defaults)
#   - Git LFS declaration (enabled but minimal — you can remove if unused)
#   - Useful aliases
#   - Delta as the pager (syntax-highlighted diffs)
#
# WHAT THIS FILE DOES NOT OWN:
#   - SSH keys (generated manually, never in the repo)
#   - SSH config (modules/apps/ssh.nix)
#   - Credentials / tokens (Tier 1 secrets approach — Phase 11)


{ config, pkgs, lib, ... }:

{
  options.cypher-os.apps.dev.git.enable = lib.mkEnableOption "Git Version Control System";

  config = lib.mkIf config.cypher-os.apps.dev.git.enable {

    home.packages = with pkgs; [
      ## ────────────── GIT ─────────────────────────────────────────────────────
      git-lfs
      delta # git pager (pulled in by programs.git.delta but good to be explicit)
    ];

    programs.git = {
      enable = true;

      # ── Signing format ─────────────────────────────────────────────────────────
      # Explicitly set to null to adopt the new default and silence the warning.
      # NOTE: If you later set up commit signing (GPG or SSH), update accordingly.
      signing.format = null;

      # ── Git LFS ───────────────────────────────────────────────────────────────
      # Declares the LFS filter. Only activates for repos that have LFS objects.
      lfs.enable = true;

      # ── Settings ──────────────────────────────────────────────────────────────
      # programs.git.settings is the new unified home for identity, core behaviour,
      # and aliases (previously split across userName, userEmail, extraConfig, aliases).
      settings = {

        # ── Identity ────────────────────────────────────────────────────────────
        user.name  = "CypherWhisperer";
        user.email = "cypherwhisperer@gmail.com";

        # ── Core Behaviour ──────────────────────────────────────────────────────
        init.defaultBranch = "master";

        # Pull strategy: merge (false = create merge commit on diverged pull).
        # Honest history — you can see where things came from.
        # Switch to rebase = true when comfortable with git workflows.
        pull.rebase = false;

        # push.autoSetupRemote: automatically set the upstream on first push
        # of a new branch. Saves typing `--set-upstream origin <branch>`.
        push.autoSetupRemote = true;

        # core.editor: nvim for commit messages, rebase todo lists, etc.
        core.editor = "nvim";

        # core.autocrlf: never mangle line endings (you're on Linux everywhere)
        core.autocrlf = false;

        # merge.conflictstyle: show the common ancestor in conflict markers.
        # Makes conflicts easier to reason about than the default two-way diff.
        merge.conflictstyle = "diff3";

        # diff.colorMoved: colour moved lines differently from added/removed.
        # Makes refactors (moving code around) much easier to read in diffs.
        diff.colorMoved = "default";

        # rerere.enabled: remember how you resolved a conflict and replay it
        # automatically if the same conflict appears again (e.g. after rebase).
        rerere.enabled = true;

        # column.ui: use column layout for branch listings and similar output.
        column.ui = "auto";

        # branch.sort: show most recently used branches first in `git branch`.
        branch.sort = "-committerdate";

        # ── Aliases ─────────────────────────────────────────────────────────────
        # These complement the OMZ git plugin aliases already in zsh.nix.
        # OMZ covers: gst (status), gco (checkout), gp (push), gl (pull), etc.
        # These add the ones OMZ doesn't have or that you'll use differently.
        alias = {
          # Pretty log — one line per commit with graph, colours, relative dates
          lg  = "log --oneline --graph --decorate --all";
          lga = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";

          # Undo last commit, keep changes staged
          undo = "reset --soft HEAD~1";

          # Stage all changes and commit with message: `git save 'wip'`
          save = "!git add -A && git commit -m";

          # Show files changed in the last commit
          last = "diff HEAD~1 HEAD --name-only";

          # List all branches sorted by last commit date
          branches = "branch --sort=-committerdate --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:green)(%(committerdate:relative))%(color:reset) %(contents:subject)'";

          # Discard all unstaged changes
          discard = "checkout --";

          # Show the diff of what's staged (about to be committed)
          staged = "diff --cached";

          # Quick amend last commit (no message change)
          amend = "commit --amend --no-edit";
        };
      };

      # ── Global Ignores ────────────────────────────────────────────────────────
      # Files to ignore in every repository — things that should never be committed
      # regardless of project type.
      ignores = [
        # OS and editor artifacts
        ".DS_Store"
        "Thumbs.db"
        ".directory"

        # Editor state files
        "*.swp"
        "*.swo"
        "*~"
        ".vim/"
        ".nvim/"

        # Nix build artifacts
        "result"
        "result-*"

        # Environment and secrets files (belt-and-suspenders alongside .gitignore)
        ".env"
        ".env.local"
        ".env.*.local"
        "secrets/env"
        "*.age"            # encrypted age secrets (except when intentionally committed)

        # Node
        "node_modules/"
        ".npm/"

        # Python
        "__pycache__/"
        "*.py[cod]"
        ".venv/"
        "venv/"

        # Logs
        "*.log"
      ];
    };

    # ── Delta Pager ─────────────────────────────────────────────────────────────
    # delta: a syntax-highlighting pager for git diffs, log, and blame.
    # Replaces the default `less` output with coloured, side-by-side-capable diffs.
    # Moved out of programs.git per the deprecation rename.
    programs.delta = {
      enable = true;
      enableGitIntegration = true;   # explicit — silences the deprecation warning
      options = {
        navigate     = true;   # n/N to move between diff sections
        side-by-side = false;  # unified diff by default; toggle with `delta --side-by-side`
        line-numbers = true;
        syntax-theme = "Catppuccin-mocha"; # matches terminal palette
        features     = "decorations";
        decorations = {
          commit-decoration-style      = "blue ol";
          commit-style                 = "raw";
          file-style                   = "omit";
          hunk-header-decoration-style = "blue box";
          hunk-header-file-style       = "red";
          hunk-header-line-number-style = "#067a00";
          hunk-header-style            = "file line-number syntax";
        };
      };
    };
  };
}
