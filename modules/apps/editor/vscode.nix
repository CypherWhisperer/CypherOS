# modules/apps/vscode.nix
#
# Home Manager module for VSCode and its forks (Cursor, Antigravity).
#
# ARCHITECTURE:
#   VSCode forks share one settings.json — deployed via xdg.configFile to
#   each editor's config path. Extensions are managed per-editor since each
#   fork has its own extension host and marketplace integration.
#
#   programs.vscode handles the VSCode binary and its extensions declaratively.
#   Cursor and Antigravity share the settings deployed via xdg.configFile.
#
# EXTENSIONS — TWO TIERS:
#   Tier 1 (nixpkgs): extensions available as pkgs.vscode-extensions.*
#     Managed by Nix — reproducible, no network call at activation time.
#
#   Tier 2 (marketplace): extensions not in nixpkgs, fetched from
#     pkgs.nix-vscode-extensions.vscode-marketplace.Previous approach via
#     Open VSX/ VS Marketplace (via vscode-utils.buildVscodeMarketplaceExtension)
#     Was ruled over due to issues with building (hash mismatches).
#
# MAPLE MONO FONT NOTE:
#   settings.json specifies Maple Mono as the editor font. Not in nixpkgs.
#   To install:
#     1. Download from https://github.com/subframe7536/maple-font/releases
#     2. Place TTF files in configs/fonts/maple-mono/
#     3. Add a home.file entry deploying them to ~/.local/share/fonts/
#     4. Run `fc-cache -f` once after first switch
#   Until then the config falls back to JetBrains Mono (already installed).
#
# SHARED SETTINGS STRATEGY:
#   One settings.json is deployed to VSCode, Cursor, and Antigravity.
#   If editor-specific overrides are needed, add separate xdg.configFile
#   entry that writes only the differing keys — the last writer wins for
#   each key in VSCode's settings merge.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ── nix-vscode-extensions aliases ─────────────────────────────────────────
  # These give us short names to reach the two registries.
  #
  # vscode-marketplace: Microsoft's official registry.
  #   Use for extensions that are exclusive to it (proprietary, AI tools, etc.)
  #
  # open-vsx: The vendor-neutral open-source registry.
  #   Prefer this when an extension is available on both — no Microsoft ToS
  #   concerns, and the extension is byte-for-byte identical in most cases.
  #
  # IMPORTANT: publisher and extension names are ALWAYS fully lowercase
  # in Nix attribute paths, even when the marketplace shows mixed case.
  # e.g. "Prisma" publisher → prisma.prisma, "fwcd" → fwcd.kotlin
  vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;

  # ── Shared settings.json ──────────────────────────────────────────────────
  sharedSettings = {

    # ── Theme ───────────────────────────────────────────────────────────────────
    # workbench.colorTheme is intentionally absent here.
    # It is set automatically by the catppuccin.vscode HM module in config above,
    # which builds the correct theme string from the flavor/accent options.
    # Setting it here would conflict — do not re-add it.
    #
    # HyDE-era themes — uncomment to switch:
    # "workbench.colorTheme" = "Decayce";              # decaycs.decay
    # "workbench.colorTheme" = "Tokyo Night";          # tokyonight.tokyonight
    # "workbench.colorTheme" = "One Dark Pro";         # zhuangtongfa.material-theme
    # "workbench.colorTheme" = "Dracula";              # dracula-theme.theme-dracula
    # "workbench.colorTheme" = "Gruvbox Dark Hard";    # jdinhlife.gruvbox
    # "workbench.colorTheme" = "Cyberpunk";            # max-ss.cyberpunk
    # "workbench.colorTheme" = "Nord";                 # arcticicestudio.nord-visual-studio-code
    #
    # NOTE: Catppuccin themes are handled separately via the catppuccin/nix flake module (see below).
    #
    # To switch flavour: change catppuccin.vscode.flavor above and rebuild.
    # Available commented-out alternatives kept for reference:
    #
    # "workbench.colorTheme" = "Catppuccin Mocha"; # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Macchiato"; # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Frappé";    # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Latte";     # catppuccin.catppuccin-vsc

    # ── Font ────────────────────────────────────────────────────────────────
    "editor.fontFamily" = "'Maple Mono', 'JetBrainsMono Nerd Font', 'monospace', monospace";
    "editor.fontSize" = 12;
    "editor.fontLigatures" = true;

    # ── Editor Core ─────────────────────────────────────────────────────────
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = false;
    "editor.tabSize" = 2;
    "editor.detectIndentation" = true;
    "editor.wordWrap" = "off";
    "editor.cursorBlinking" = "smooth";
    "editor.cursorSmoothCaretAnimation" = "on";
    "editor.smoothScrolling" = true;
    "editor.linkedEditing" = true;
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.inlineSuggest.enabled" = true;
    "editor.suggestSelection" = "first";
    "editor.renderWhitespace" = "boundary"; # show spaces at line boundaries
    "editor.rulers" = [
      80
      100
    ]; # soft column guides

    # ── Scrollbar ───────────────────────────────────────────────────────────
    "editor.scrollbar.vertical" = "hidden";
    "editor.scrollbar.verticalScrollbarSize" = 0;
    "editor.scrollbar.horizontal" = "auto";
    "editor.overviewRulerBorder" = false;

    # ── Minimap ─────────────────────────────────────────────────────────────
    "editor.minimap.side" = "left";
    "editor.minimap.enabled" = true;
    "editor.minimap.scale" = 1;

    # ── Workbench ───────────────────────────────────────────────────────────
    "workbench.statusBar.visible" = false;
    "workbench.activityBar.location" = "top";
    "workbench.tree.indent" = 16;
    "workbench.tree.renderIndentGuides" = "always";
    "workbench.sideBar.location" = "right";
    "window.menuBarVisibility" = "toggle";
    "workbench.startupEditor" = "none"; # no welcome tab on launch

    # ── Terminal ────────────────────────────────────────────────────────────
    "terminal.external.linuxExec" = "kitty";
    "terminal.explorerKind" = "both";
    "terminal.sourceControlRepositoriesKind" = "both";
    "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
    "terminal.integrated.fontSize" = 12;
    "terminal.integrated.cursorBlinking" = true;
    "terminal.integrated.scrollback" = 10000;
    "terminal.integrated.defaultProfile.linux" = "zsh";

    # ── File Handling ────────────────────────────────────────────────────────
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "files.autoSave" = "onFocusChange";
    "files.exclude" = {
      "**/.git" = true;
      "**/node_modules" = true;
      "**/__pycache__" = true;
      "**/.venv" = true;
      "**/result" = true;
      "**/.dart_tool" = true;
      "**/.flutter-plugins" = true;
    };

    # ── Explorer ─────────────────────────────────────────────────────────────
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;
    "explorer.sortOrder" = "type";

    # ── Git ──────────────────────────────────────────────────────────────────
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableSmartCommit" = true;

    # ── Breadcrumbs ──────────────────────────────────────────────────────────
    "breadcrumbs.enabled" = true;

    # ── Language: Python ─────────────────────────────────────────────────────
    "[python]" = {
      "editor.defaultFormatter" = "ms-python.python";
      "editor.tabSize" = 4;
      "editor.formatOnSave" = true;
    };
    "python.analysis.typeCheckingMode" = "basic";
    "python.analysis.autoImportCompletions" = true;
    "python.terminal.activateEnvironment" = true;

    # ── Language: JavaScript / TypeScript ────────────────────────────────────
    "[javascript]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "[javascriptreact]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "[typescriptreact]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "eslint.validate" = [
      "javascript"
      "javascriptreact"
      "typescript"
      "typescriptreact"
    ];
    "eslint.run" = "onSave";
    # TypeScript: use workspace version if available, fall back to bundled
    "typescript.tsdk" = "node_modules/typescript/lib";
    "typescript.enablePromptUseWorkspaceTsdk" = true;

    # ── Language: JSON ───────────────────────────────────────────────────────
    "[json]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };

    # ── Language: HTML / CSS ─────────────────────────────────────────────────
    "[html]" = {
      "editor.defaultFormatter" = "vscode.html-language-features";
    };
    "[css]" = {
      "editor.defaultFormatter" = "vscode.css-language-features";
    };
    "[scss]" = {
      "editor.defaultFormatter" = "vscode.css-language-features";
    };

    # ── Language: Bash / Shell ───────────────────────────────────────────────
    "[shellscript]" = {
      "editor.defaultFormatter" = "mads-hartmann.bash-ide-vscode";
    };
    "shellcheck.enable" = true;
    "shellcheck.executablePath" = "shellcheck"; # in PATH via home.packages
    "bashIde.shellcheckPath" = "shellcheck";

    # ── Language: Lua ────────────────────────────────────────────────────────
    "[lua]" = {
      "editor.defaultFormatter" = "sumneko.lua";
    };
    # Tell the Lua LSP about Neovim's global API so it doesn't flag vim.* as unknown
    "Lua.workspace.library" = [
      "\${3rd}/luv/library" # luv (libuv bindings)
    ];
    "Lua.workspace.checkThirdParty" = false;
    "Lua.diagnostics.globals" = [ "vim" ]; # suppress "undefined global vim"
    "Lua.runtime.version" = "LuaJIT"; # Neovim uses LuaJIT

    # ── Language: Nix ────────────────────────────────────────────────────────
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
      "editor.tabSize" = 2;
    };
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nixd"; # nixd LSP — declared in home.packages
    "nix.serverSettings" = {
      nixd = {
        formatting.command = [ "nixfmt" ]; # nixfmt in home.packages
      };
    };

    # ── Language: Rust ───────────────────────────────────────────────────────
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "editor.formatOnSave" = true;
    };
    "rust-analyzer.checkOnSave" = true;
    "rust-analyzer.cargo.allFeatures" = true;
    "rust-analyzer.procMacro.enable" = true;

    # ── Language: SQL ────────────────────────────────────────────────────────
    # SQLTools connections are added interactively via the SQLTools panel
    # (they contain credentials — not declared here).
    # Driver format hint: PostgreSQL connection stored in
    # $XDG_CONFIG_HOME/Code/User/settings.json under "sqltools.connections"
    # once you add one via the UI.
    "sqltools.useNodeRuntime" = true;
    "sqltools.autoOpenSessionFiles" = false;

    # ── Language: Flutter / Dart ─────────────────────────────────────────────
    # Flutter SDK path: Home Manager installs flutter to the Nix store.
    # The path below is set dynamically — replace with the actual store path
    # or set it to the flutter binary location after first switch:
    #   `which flutter | xargs dirname | xargs dirname`
    #  e.g /etc/profiles/per-user/cypher-whisperer
    # Alternatively leave unset and let the extension auto-detect.
    # "dart.flutterSdkPath" = "/path/to/flutter";  # set after first switch
    "dart.debugExternalPackageLibraries" = false;
    "dart.debugSdkLibraries" = false;
    "dart.openDevTools" = "flutter";
    "[dart]" = {
      "editor.defaultFormatter" = "Dart-Code.dart-code";
      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
      "editor.rulers" = [ 80 ];
      "editor.selectionHighlight" = false;
      "editor.suggest.snippetsPreventQuickSuggestions" = false;
      "editor.tabCompletion" = "onlySnippets";
      "editor.wordBasedSuggestions" = "off";
    };

    # ── Language: Vue ────────────────────────────────────────────────────────
    "[vue]" = {
      "editor.defaultFormatter" = "vue.volar";
    };

    # ── Language: Svelte ─────────────────────────────────────────────────────
    "[svelte]" = {
      "editor.defaultFormatter" = "svelte.svelte-vscode";
    };

    # ── DevOps: Docker ───────────────────────────────────────────────────────
    "[dockerfile]" = {
      "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
    };
    "docker.showStartPage" = false;

    # ── DevOps: Kubernetes ───────────────────────────────────────────────────
    "[yaml]" = {
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "vs-kubernetes" = {
      "vs-kubernetes.kubectl-path" = "kubectl"; # in PATH via home.packages
    };

    # ── Extension: Better Comments ───────────────────────────────────────────
    "better-comments.tags" = [
      {
        tag = "!";
        color = "#FF2D00";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "?";
        color = "#3498DB";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "//";
        color = "#474747";
        strikethrough = true;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "todo";
        color = "#FF8C00";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "*";
        color = "#98C379";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
    ];

    # ── Extension: Color Highlight ───────────────────────────────────────────
    "color-highlight.enable" = true;

    # ── Security ─────────────────────────────────────────────────────────────
    "security.workspace.trust.enabled" = false;
    "security.workspace.trust.untrustedFiles" = "newWindow";
    "security.workspace.trust.startupPrompt" = "never";

    # ── Telemetry ────────────────────────────────────────────────────────────
    "telemetry.telemetryLevel" = "off";
    "redhat.telemetry.enabled" = false;

    # ── Extensions ───────────────────────────────────────────────────────────
    "extensions.autoUpdate" = false;
    "extensions.autoCheckUpdates" = false;
  };

in
{
  config =
    lib.mkIf
      (
        config.cypher-os.apps.editor.enable
        && config.cypher-os.profile.desktop.enable
        && config.cypher-os.apps.editor.vscode.enable
      )
      {
        # ── Catppuccin Theme ────────────────────────────────────────────────────────
        # Configured via the catppuccin/nix HM module (imported in flake.nix).
        # This approach pre-compiles the chosen flavour at derivation time,
        # which is necessary because the extension normally writes its compiled
        # theme JSON to its own directory at activation — impossible in the
        # read-only Nix store.
        #
        # The module automatically adds the patched extension to programs.vscode
        # and sets workbench.colorTheme in userSettings. We therefore must NOT:
        #   - list catppuccin.catppuccin-vsc in programs.vscode extensions (already removed)
        #   - set workbench.colorTheme in sharedSettings (already removed)
        #
        # Flavours: latte (light), frappe, macchiato, mocha (darkest)
        # Accents:  blue, flamingo, green, lavender, maroon, mauve, peach,
        #           pink, red, rosewater, sapphire, sky, teal, yellow
        catppuccin.vscode.profiles.default = {
          enable = true;
          flavor = "mocha"; # current preference
          accent = "mauve"; # adjust to taste
        };

        # ── VSCode ──────────────────────────────────────────────────────────────────
        programs.vscode = {
          enable = true;

          # mutableExtensionsDir = false: prevents VSCode from writing to the
          # extensions directory at runtime. All extensions come from Nix.
          # Set to true if you want to install extensions manually alongside
          # the Nix-managed ones (useful while evaluating new extensions).
          mutableExtensionsDir = true; # true during active configuration phase

          # userSettings: written to VSCode's settings.json.
          # Shared settings are merged here.
          profiles.default.userSettings = sharedSettings;

          profiles.default.extensions =
            with pkgs.vscode-extensions;
            [
              # ── Theme ────────────────────────────────────────────────────────────
              # Uncomment to install alongside (switch via workbench.colorTheme above):
              # enkia.tokyo-night
              #
              # NOTE: Catppuccin themes are handled separately via the catppuccin/nix flake module.
              #       (see above)
              #
              # catppuccin.catppuccin-vsc
              # dracula-theme.theme-dracula
              # zhuangtongfa.material-theme   # One Dark Pro
              # jdinhlife.gruvbox
              # arcticicestudio.nord-visual-studio-code

              # ── General Productivity ─────────────────────────────────────────────
              aaron-bond.better-comments
              naumovs.color-highlight
              christian-kohler.path-intellisense
              christian-kohler.npm-intellisense
              visualstudioexptteam.vscodeintellicode
              visualstudioexptteam.intellicode-api-usage-examples

              # ── Web / HTML / CSS ──────────────────────────────────────────────────
              ecmel.vscode-html-css
              ritwickdey.liveserver

              # ── Web: Prisma ───────────────────────────────────────────────────────────────
              # Syntax highlighting, formatting, auto-completion, and jump-to-definition
              # for .prisma schema files. In nixpkgs — no marketplace fetch needed.
              prisma.prisma

              # ── JavaScript / TypeScript ───────────────────────────────────────────
              dbaeumer.vscode-eslint

              # ── Vue / Svelte ──────────────────────────────────────────────────────
              vue.volar # Vue 3 official language support
              svelte.svelte-vscode # Svelte language support

              # ── SVG ──────────────────────────────────────────────────────────────
              jock.svg

              # ── Python ───────────────────────────────────────────────────────────
              ms-python.python
              ms-python.vscode-pylance
              ms-python.debugpy
              njpwerner.autodocstring
              batisteo.vscode-django
              wholroyd.jinja

              # ── Bash / Shell ─────────────────────────────────────────────────────
              mads-hartmann.bash-ide-vscode # bash LSP (bash-language-server)
              timonwong.shellcheck # ShellCheck linting integration

              # ── Lua ───────────────────────────────────────────────────────────────
              sumneko.lua # Lua LSP — essential for CypherIDE config editing

              # ── Nix ───────────────────────────────────────────────────────────────
              # jnoortheen.nix-ide is referenced in language settings above.
              # Adding it here makes the formatter actually available.
              jnoortheen.nix-ide # Nix language support + nixd LSP integration

              # ── Rust ─────────────────────────────────────────────────────────────
              rust-lang.rust-analyzer
              serayuzgur.crates # Cargo.toml dependency helper
              tamasfe.even-better-toml # TOML syntax + validation
              vadimcn.vscode-lldb # LLDB debugger for Rust/C/C++

              # ── C / C++ ──────────────────────────────────────────────────────────
              ms-vscode.cpptools
              ms-vscode.cpptools-extension-pack
              ms-vscode.cmake-tools
              twxs.cmake

              # ── Vim keybindings ──────────────────────────────────────────────────
              #vscodevim.vim

              # ── Flutter / Dart ────────────────────────────────────────────────────
              dart-code.flutter # Flutter tooling, hot reload, device management
              dart-code.dart-code # Dart language support (flutter depends on this)

              # ── Mobile: React Native ──────────────────────────────────────────────
              # msjsdiag.vscode-react-native is in marketplace tier (not in nixpkgs)

              # ── DevOps: Docker ────────────────────────────────────────────────────
              ms-azuretools.vscode-docker
              ms-vscode-remote.remote-containers
              # ── DevOps: Containers  ───────────────────────────────────────────────
              ms-azuretools.vscode-containers
              ms-vscode-remote.remote-containers

              # ── DevOps: Kubernetes ────────────────────────────────────────────────
              ms-kubernetes-tools.vscode-kubernetes-tools
              redhat.vscode-yaml # YAML support — used by k8s manifests, GH Actions

              # ── DevOps: CI/CD ─────────────────────────────────────────────────────
              github.vscode-github-actions
            ]
            ++ [
              # ── Tier 2: nix-vscode-extensions (marketplace/open-vsx) ──────────────────
              # Extensions not packaged in nixpkgs, sourced from nix-community/nix-vscode-extensions.
              # No sha256 needed — hashes are pre-computed in the flake's JSON cache.
              # To update all of these to their latest versions: nix flake update nix-vscode-extensions
              #
              # Naming convention: vscMkt.<publisher>.<extension-name> (all lowercase)
              # Check Open VSX first (openVsx.*) — prefer it over vscMkt when available.

              # ── AI / Code Review ───────────────────────────────────────────────────────
              vscMkt.coderabbit.coderabbit-vscode
              vscMkt.openai.chatgpt

              # ── Code Runner ────────────────────────────────────────────────────────────
              vscMkt.formulahendry.code-runner

              # ── Theme ──────────────────────────────────────────────────────────────────
              # Catppuccin handled separately via catppuccin/nix flake module (see below)
              vscMkt.decaycs.decay
              vscMkt.nishantg96.dark-decay-pro

              # ── HTML ───────────────────────────────────────────────────────────────────
              vscMkt.george-alisson.html-preview-vscode
              vscMkt.sidthesloth.html5-boilerplate
              vscMkt.riazxrazor.html-to-jsx

              # ── CSS ────────────────────────────────────────────────────────────────────
              vscMkt.phoenisx.cssvar

              # ── SVG ────────────────────────────────────────────────────────────────────
              vscMkt.henoc.svgeditor
              vscMkt.sidthesloth.svg-snippets

              # ── JavaScript / TypeScript / React ────────────────────────────────────────
              vscMkt.xabikos.javascriptsnippets
              vscMkt.xabikos.reactsnippets
              vscMkt.dsznajder.es7-react-js-snippets
              vscMkt.burkeholland.simple-react-snippets
              vscMkt.ms-vscode.vscode-typescript-next
              vscMkt.jasonnutter.search-node-modules
              vscMkt.infeng.vscode-react-typescript
              vscMkt.msjsdiag.vscode-react-native
              vscMkt.jawandarajbir.react-vscode-extension-pack

              # ── Python ─────────────────────────────────────────────────────────────────
              vscMkt.donjayamanne.python-environment-manager
              vscMkt.kevinrose.vsc-python-indent

              # ── Rust ───────────────────────────────────────────────────────────────────
              vscMkt.dustypomerleau.rust-syntax
              # Nix attribute names cannot start with a digit.
              # Use the string-subscript form: attrset."string-key" instead of attrset.identifier
              vscMkt."1yib".rust-bundle
              vscMkt.swellaby.rust-pack

              # ── Assembly ───────────────────────────────────────────────────────────────
              # Nix attribute names cannot start with a digit.
              # Use the string-subscript form: attrset."string-key" instead of attrset.identifier
              vscMkt."13xforever".language-x86-64-assembly

              # ── SQL ────────────────────────────────────────────────────────────────────
              vscMkt.mtxr.sqltools
              vscMkt.mtxr.sqltools-driver-pg

              # ── Mobile: Kotlin ─────────────────────────────────────────────────────────
              # Not in nixpkgs — sourced from nix-vscode-extensions.
              vscMkt.fwcd.kotlin

              # ── DevOps: Docker Compose ─────────────────────────────────────────────────
              # p1c2u's Docker Compose extension — not in nixpkgs.
              vscMkt.p1c2u.docker-compose

              # ── DevOps: Docker Extension Pack (Jun Han) ────────────────────────────────
              # The pack itself; ms-azuretools.vscode-docker is already in Tier 1 above.
              vscMkt.formulahendry.docker-extension-pack

              # ── AI: Claude Code ────────────────────────────────────────────────────────
              # Anthropic's Claude Code extension — not in nixpkgs.
              vscMkt.anthropic.claude-code
            ];
        };
        # ── Shared Settings Deployment ──────────────────────────────────────────────
        # Deploy the same settings.json to Cursor and Antigravity.
        # Both editors respect the XDG config path pattern.
        # The JSON is generated from sharedSettings (same source as VSCode above).
        xdg.configFile."Cursor/User/settings.json".text = builtins.toJSON sharedSettings;

        xdg.configFile."antigravity/User/settings.json".text = builtins.toJSON sharedSettings;
      };
}
