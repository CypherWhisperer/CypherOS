
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
#   Cursor and Antigravity are declared in home.packages (no HM module exists
#   for them) with settings deployed via xdg.configFile.
#
# EXTENSIONS — TWO TIERS:
#   Tier 1 (nixpkgs): extensions available as pkgs.vscode-extensions.*
#     Managed by Nix — reproducible, no network call at activation time.
#   Tier 2 (marketplace): extensions not in nixpkgs, fetched from Open VSX
#     or the VS Marketplace via vscode-utils.buildVscodeMarketplaceExtension.
#     These require a hash — use lib.fakeHash first, build, copy the correct
#     hash from the error output, update the file.
#     Hash update workflow (same as tmux plugins):
#       nix-prefetch-url --unpack \
#         https://marketplace.visualstudio.com/_apis/public/gallery/publishers/<publisher>/vsextensions/<name>/<version>/vspackage
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
#   If you need editor-specific overrides later, add a separate xdg.configFile
#   entry that writes only the differing keys — the last writer wins for
#   each key in VSCode's settings merge.
#
# ANDROID STUDIO / FLUTTER NOTE:
#   Flutter and Dart are declared in home.packages below. Android Studio
#   is left as a bare package — run it once to let it download its own SDK
#   via the built-in SDK Manager before investing in declarative SDK config.
#   When ready, replace pkgs.android-studio with an androidenv.composeAndroidPackages
#   derivation — see modules/apps/android.nix (future).

{ config, pkgs, lib, ... }:

let
  # ── Marketplace Extension Builder ─────────────────────────────────────────
  # For extensions not in nixpkgs.
  # Replace sha256 = lib.fakeHash with the value from the build error.
  buildExt = { publisher, name, version, sha256 }:
    pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = { inherit publisher name version; };
      inherit sha256;
    };

  # ── Extensions not in nixpkgs ────────────────────────────────────────────
  marketplaceExtensions = [
    # AI / Code Review
    (buildExt { publisher = "coderabbit";     name = "coderabbit-vscode";            version = "0.7.5";   sha256 = "sha256-fnM6vFxopCqGQnyMMfVYclwa20bWJSI1MTQ1N87JAic="; })
    (buildExt { publisher = "openai";         name = "chatgpt";                      version = "0.4.69";  sha256 = "sha256-9iIFRYSpXoravyBJK2KpTGKOv+K3z1yyILSlcwR2boM="; })

    # Code runner
    (buildExt { publisher = "formulahendry"; name = "code-runner";                   version = "0.12.2";  sha256 = "sha256-TI5K6n3QfJwgFz5xhpdZ+yzi9VuYGcSzdBckZ68DsUQ="; })

    # Theme
    (buildExt { publisher = "decaycs";        name = "decay";                        version = "1.0.9";   sha256 = "sha256-TwDq8K757CTFEBBBGbP5eOC5nMrQzgf/XYIHi9UCAkU="; })
    (buildExt { publisher = "nishantg96";     name = "dark-decay-pro";               version = "1.0.0";   sha256 = "sha256-9m5lBdG3COn9MWb3KZ/rYUTpE0eKWn5F9c35smqmqxk="; })

    # HTML
    (buildExt { publisher = "george-alisson"; name = "html-preview-vscode";          version = "0.2.5";   sha256 = "sha256-1kjhNLFRUashPYko5F7p8gNwe+heT4wKAPZiJsTqgdg="; })
    (buildExt { publisher = "sidthesloth";    name = "html5-boilerplate";            version = "1.1.1";   sha256 = "sha256-gLflPFwythZ0QDgDiXKGRleJlqvHAO34/VSTIWEJQNo="; })
    (buildExt { publisher = "riazxrazor";     name = "html-to-jsx";                  version = "0.0.1";   sha256 = "sha256-7LBILbqa6MSrVZ7xf5CZCgOFiaZl5bocVYt45VaJ+Vc="; })

    # CSS
    (buildExt { publisher = "phoenisx";       name = "cssvar";                       version = "2.6.5";   sha256 = "sha256-nmi0T7fkP+mIqCYSbGiCqLIj5QOdMaZuNPrPNhpOk1c="; })

    # SVG
    (buildExt { publisher = "henoc";          name = "svgeditor";                    version = "2.9.0";   sha256 = "sha256-29CA3ZoOXNj6lM1hqOwXOGEOLpaNkwKlRhiSQXKr3x8="; })
    (buildExt { publisher = "sidthesloth";    name = "svg-snippets";                 version = "1.0.1";   sha256 = "sha256-pkTNbUgYelc3y09o4NPz3xGQ2LNqKbpipmNmBkLdLhg="; })

    # JavaScript / TypeScript / React
    (buildExt { publisher = "xabikos";        name = "javascriptsnippets";           version = "1.8.0";   sha256 = "sha256-ht6Wm1X7zien+fjMv864qP+Oz4M6X6f2RXjrThURr6c="; })
    #(buildExt { publisher = "xabikos";        name = "reactsnippets";                version = "2.4.0";   sha256 = lib.fakeHash; })
    (buildExt { publisher = "dsznajder";      name = "es7-react-js-snippets";        version = "4.4.3";   sha256 = "sha256-QF950JhvVIathAygva3wwUOzBLjBm7HE3Sgcp7f20Pc="; })
    (buildExt { publisher = "burkeholland";   name = "simple-react-snippets";        version = "1.2.8";   sha256 = "sha256-zrRxJZHRqBMGVkd56Q+wDbCSFfl4X3Kta4sX8ecZmu8="; })
    (buildExt { publisher = "ms-vscode";      name = "vscode-typescript-next";       version = "5.8.20250207"; sha256 = "sha256-QEoajJsIlS2fDwxcwcoPMAJGVDchQ7IdqAB3X1MyO7A="; })
    (buildExt { publisher = "jasonnutter";    name = "search-node-modules";          version = "1.3.0";   sha256 = "sha256-X2CkCVF46McnXDlASlRHKixlAzR+hU4ys8A8JsbpfYI="; })
    (buildExt { publisher = "infeng";         name = "vscode-react-typescript";      version = "1.3.1";   sha256 = "sha256-eaKtnKqPkCm/xxCzUOhHd536n3Y9MZWrVerIO2u/tro="; })
    (buildExt { publisher = "msjsdiag";       name = "vscode-react-native";          version = "1.13.0";  sha256 = "sha256-zryzoO9sb1+Kszwup5EhnN/YDmAPz7TOQW9I/K28Fmg="; })
    (buildExt { publisher = "jawandarajbir";  name = "react-vscode-extension-pack";  version = "1.0.0";   sha256 = "sha256-7XzTLhhx2i+nDpmR1Cjgn6Ngv+5ictLXo+kfAgNhFeM="; })

    # Python
    (buildExt { publisher = "donjayamanne";   name = "python-environment-manager";   version = "1.2.7";   sha256 = "sha256-w3csu6rJm/Z6invC/TR7tx6Aq5DD77VM62nem8/QMlg="; })
    (buildExt { publisher = "kevinrose";      name = "vsc-python-indent";            version = "1.19.0";  sha256 = "sha256-gX0L416RXIQ9S4kFguEJJ7u4GSo7WbpifXmL/mWCU08="; })

    # Rust
    (buildExt { publisher = "dustypomerleau"; name = "rust-syntax";                  version = "0.6.1";   sha256 = "sha256-o9iXPhwkimxoJc1dLdaJ8nByLIaJSpGX/nKELC26jGU="; })
    (buildExt { publisher = "1yib";           name = "rust-bundle";                  version = "1.0.0";   sha256 = "sha256-G2vHX9LBKmUhd5K3oKAojcfVIWydjPS03xkBW+cepaU="; })
    (buildExt { publisher = "swellaby";       name = "rust-pack";                    version = "0.3.38";  sha256 = "sha256-ykAi5qDJQaDAiPY5CSy3zO52wMQEzuY62UeN1y2M96o="; })

    # Assembly
    (buildExt { publisher = "13xforever";     name = "language-x86-64-assembly";     version = "3.1.4";   sha256 = "sha256-FJRDm1H3GLBfSKBSFgVspCjByy9m+j9OStlU+/pMfs8="; })

    # SQL
    (buildExt { publisher = "mtxr";           name = "sqltools";                     version = "0.28.3";  sha256 = "sha256-bTrHAhj8uwzRIImziKsOizZf8+k3t+VrkOeZrFx7SH8="; })
    (buildExt { publisher = "mtxr";           name = "sqltools-driver-pg";           version = "0.5.2";   sha256 = "sha256-fBBh8WhCZBoj+SvK+5i8Q6DsiHZ6wi+KASVAXPVKA6E="; })

    # Mobile
    (buildExt { publisher = "fwcd";           name = "kotlin";                       version = "0.2.34";  sha256 = "sha256-03F6cHIA9Tx8IHbVswA8B58tB8aGd2iQi1i5+1e1p4k="; })
  ];

  # ── Shared settings.json ──────────────────────────────────────────────────
  sharedSettings = {

    # ── Theme ───────────────────────────────────────────────────────────────
    # Active theme — Decayce (your preference)
    "workbench.colorTheme" = "Decayce";
    #
    # HyDE-era themes — uncomment to switch:
    # "workbench.colorTheme" = "Tokyo Night";          # tokyonight.tokyonight
    # "workbench.colorTheme" = "Catppuccin Mocha";     # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Macchiato"; # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Frappé";    # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Latte";     # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Dracula";              # dracula-theme.theme-dracula
    # "workbench.colorTheme" = "One Dark Pro";         # zhuangtongfa.material-theme
    # "workbench.colorTheme" = "Gruvbox Dark Hard";    # jdinhlife.gruvbox
    # "workbench.colorTheme" = "Cyberpunk";            # max-ss.cyberpunk
    # "workbench.colorTheme" = "Nord";                 # arcticicestudio.nord-visual-studio-code

    # ── Font ────────────────────────────────────────────────────────────────
    "editor.fontFamily"    = "'Maple Mono', 'JetBrainsMono Nerd Font', 'monospace', monospace";
    "editor.fontSize"      = 12;
    "editor.fontLigatures" = true;

    # ── Editor Core ─────────────────────────────────────────────────────────
    "editor.formatOnSave"                    = true;
    "editor.formatOnPaste"                   = false;
    "editor.tabSize"                         = 2;
    "editor.detectIndentation"               = true;
    "editor.wordWrap"                        = "off";
    "editor.cursorBlinking"                  = "smooth";
    "editor.cursorSmoothCaretAnimation"      = "on";
    "editor.smoothScrolling"                 = true;
    "editor.linkedEditing"                   = true;
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs"             = "active";
    "editor.inlineSuggest.enabled"           = true;
    "editor.suggestSelection"                = "first";
    "editor.renderWhitespace"                = "boundary"; # show spaces at line boundaries
    "editor.rulers"                          = [ 80 100 ]; # soft column guides

    # ── Scrollbar ───────────────────────────────────────────────────────────
    "editor.scrollbar.vertical"              = "hidden";
    "editor.scrollbar.verticalScrollbarSize" = 0;
    "editor.scrollbar.horizontal"            = "auto";
    "editor.overviewRulerBorder"             = false;

    # ── Minimap ─────────────────────────────────────────────────────────────
    "editor.minimap.side"    = "left";
    "editor.minimap.enabled" = true;
    "editor.minimap.scale"   = 1;

    # ── Workbench ───────────────────────────────────────────────────────────
    "workbench.statusBar.visible"         = false;
    "workbench.activityBar.location"      = "top";
    "workbench.tree.indent"               = 16;
    "workbench.tree.renderIndentGuides"   = "always";
    "workbench.sideBar.location"          = "right";
    "window.menuBarVisibility"            = "toggle";
    "workbench.startupEditor"             = "none"; # no welcome tab on launch

    # ── Terminal ────────────────────────────────────────────────────────────
    "terminal.external.linuxExec"            = "kitty";
    "terminal.explorerKind"                  = "both";
    "terminal.sourceControlRepositoriesKind" = "both";
    "terminal.integrated.fontFamily"         = "'JetBrainsMono Nerd Font', monospace";
    "terminal.integrated.fontSize"           = 12;
    "terminal.integrated.cursorBlinking"     = true;
    "terminal.integrated.scrollback"         = 10000;
    "terminal.integrated.defaultProfile.linux" = "zsh";

    # ── File Handling ────────────────────────────────────────────────────────
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline"     = true;
    "files.trimFinalNewlines"      = true;
    "files.autoSave"               = "onFocusChange";
    "files.exclude" = {
      "**/.git"         = true;
      "**/node_modules" = true;
      "**/__pycache__"  = true;
      "**/.venv"        = true;
      "**/result"       = true;
      "**/.dart_tool"   = true;
      "**/.flutter-plugins" = true;
    };

    # ── Explorer ─────────────────────────────────────────────────────────────
    "explorer.confirmDelete"      = false;
    "explorer.confirmDragAndDrop" = false;
    "explorer.sortOrder"          = "type";

    # ── Git ──────────────────────────────────────────────────────────────────
    "git.autofetch"         = true;
    "git.confirmSync"       = false;
    "git.enableSmartCommit" = true;

    # ── Breadcrumbs ──────────────────────────────────────────────────────────
    "breadcrumbs.enabled" = true;

    # ── Language: Python ─────────────────────────────────────────────────────
    "[python]" = {
      "editor.defaultFormatter"    = "ms-python.python";
      "editor.tabSize"             = 4;
      "editor.formatOnSave"        = true;
    };
    "python.analysis.typeCheckingMode"      = "basic";
    "python.analysis.autoImportCompletions" = true;
    "python.terminal.activateEnvironment"   = true;

    # ── Language: JavaScript / TypeScript ────────────────────────────────────
    "[javascript]"      = { "editor.defaultFormatter" = "dbaeumer.vscode-eslint"; };
    "[javascriptreact]" = { "editor.defaultFormatter" = "dbaeumer.vscode-eslint"; };
    "[typescript]"      = { "editor.defaultFormatter" = "dbaeumer.vscode-eslint"; };
    "[typescriptreact]" = { "editor.defaultFormatter" = "dbaeumer.vscode-eslint"; };
    "eslint.validate"   = [ "javascript" "javascriptreact" "typescript" "typescriptreact" ];
    "eslint.run"        = "onSave";
    # TypeScript: use workspace version if available, fall back to bundled
    "typescript.tsdk"   = "node_modules/typescript/lib";
    "typescript.enablePromptUseWorkspaceTsdk" = true;

    # ── Language: JSON ───────────────────────────────────────────────────────
    "[json]"  = { "editor.defaultFormatter" = "vscode.json-language-features"; };
    "[jsonc]" = { "editor.defaultFormatter" = "vscode.json-language-features"; };

    # ── Language: HTML / CSS ─────────────────────────────────────────────────
    "[html]" = { "editor.defaultFormatter" = "vscode.html-language-features"; };
    "[css]"  = { "editor.defaultFormatter" = "vscode.css-language-features"; };
    "[scss]" = { "editor.defaultFormatter" = "vscode.css-language-features"; };

    # ── Language: Bash / Shell ───────────────────────────────────────────────
    "[shellscript]" = { "editor.defaultFormatter" = "mads-hartmann.bash-ide-vscode"; };
    "shellcheck.enable"               = true;
    "shellcheck.executablePath"       = "shellcheck"; # in PATH via home.packages
    "bashIde.shellcheckPath"          = "shellcheck";

    # ── Language: Lua ────────────────────────────────────────────────────────
    "[lua]" = { "editor.defaultFormatter" = "sumneko.lua"; };
    # Tell the Lua LSP about Neovim's global API so it doesn't flag vim.* as unknown
    "Lua.workspace.library" = [
      "\${3rd}/luv/library"       # luv (libuv bindings)
    ];
    "Lua.workspace.checkThirdParty" = false;
    "Lua.diagnostics.globals"       = [ "vim" ];  # suppress "undefined global vim"
    "Lua.runtime.version"           = "LuaJIT";   # Neovim uses LuaJIT

    # ── Language: Nix ────────────────────────────────────────────────────────
    "[nix]" = { "editor.defaultFormatter" = "jnoortheen.nix-ide"; "editor.tabSize" = 2; };
    "nix.enableLanguageServer" = true;
    "nix.serverPath"           = "nixd";   # nixd LSP — declared in home.packages
    "nix.serverSettings" = {
      nixd = {
        formatting.command = [ "nixfmt" ]; # nixfmt in home.packages
      };
    };

    # ── Language: Rust ───────────────────────────────────────────────────────
    "[rust]" = { "editor.defaultFormatter" = "rust-lang.rust-analyzer"; "editor.formatOnSave" = true; };
    "rust-analyzer.checkOnSave"        = true;
    "rust-analyzer.cargo.allFeatures"  = true;
    "rust-analyzer.procMacro.enable"   = true;

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
    #   which flutter | xargs dirname | xargs dirname
    # Alternatively leave unset and let the extension auto-detect.
    # "dart.flutterSdkPath" = "/path/to/flutter";  # set after first switch
    "dart.debugExternalPackageLibraries" = false;
    "dart.debugSdkLibraries"             = false;
    "dart.openDevTools"                  = "flutter";
    "[dart]" = {
      "editor.defaultFormatter"        = "Dart-Code.dart-code";
      "editor.formatOnSave"            = true;
      "editor.formatOnType"            = true;
      "editor.rulers"                  = [ 80 ];
      "editor.selectionHighlight"      = false;
      "editor.suggest.snippetsPreventQuickSuggestions" = false;
      "editor.tabCompletion"           = "onlySnippets";
      "editor.wordBasedSuggestions"    = "off";
    };

    # ── Language: Vue ────────────────────────────────────────────────────────
    "[vue]" = { "editor.defaultFormatter" = "vue.volar"; };

    # ── Language: Svelte ─────────────────────────────────────────────────────
    "[svelte]" = { "editor.defaultFormatter" = "svelte.svelte-vscode"; };

    # ── DevOps: Docker ───────────────────────────────────────────────────────
    "[dockerfile]"       = { "editor.defaultFormatter" = "ms-azuretools.vscode-docker"; };
    "docker.showStartPage" = false;

    # ── DevOps: Kubernetes ───────────────────────────────────────────────────
    "[yaml]" = { "editor.defaultFormatter" = "redhat.vscode-yaml"; };
    "vs-kubernetes" = {
      "vs-kubernetes.kubectl-path" = "kubectl"; # in PATH via home.packages
    };

    # ── Extension: Better Comments ───────────────────────────────────────────
    "better-comments.tags" = [
      { tag = "!";    color = "#FF2D00"; strikethrough = false; underline = false; backgroundColor = "transparent"; bold = false; italic = false; }
      { tag = "?";    color = "#3498DB"; strikethrough = false; underline = false; backgroundColor = "transparent"; bold = false; italic = false; }
      { tag = "//";   color = "#474747"; strikethrough = true;  underline = false; backgroundColor = "transparent"; bold = false; italic = false; }
      { tag = "todo"; color = "#FF8C00"; strikethrough = false; underline = false; backgroundColor = "transparent"; bold = false; italic = false; }
      { tag = "*";    color = "#98C379"; strikethrough = false; underline = false; backgroundColor = "transparent"; bold = false; italic = false; }
    ];

    # ── Extension: Color Highlight ───────────────────────────────────────────
    "color-highlight.enable" = true;

    # ── Security ─────────────────────────────────────────────────────────────
    "security.workspace.trust.enabled"        = false;
    "security.workspace.trust.untrustedFiles" = "newWindow";
    "security.workspace.trust.startupPrompt"  = "never";

    # ── Telemetry ────────────────────────────────────────────────────────────
    "telemetry.telemetryLevel"  = "off";
    "redhat.telemetry.enabled"  = false;

    # ── Extensions ───────────────────────────────────────────────────────────
    "extensions.autoUpdate"       = false;
    "extensions.autoCheckUpdates" = false;
  };

in
{
  # ── VSCode ──────────────────────────────────────────────────────────────────
  programs.vscode = {
    enable = true;

    # mutableExtensionsDir = false: prevents VSCode from writing to the
    # extensions directory at runtime. All extensions come from Nix.
    # Set to true if you want to install extensions manually alongside
    # the Nix-managed ones (useful while evaluating new extensions).
    mutableExtensionsDir = true;  # true during active configuration phase

    # userSettings: written to VSCode's settings.json.
    # Shared settings are merged here.
    profiles.defult.userSettings = sharedSettings;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      # ── Theme ────────────────────────────────────────────────────────────
      # Uncomment to install alongside (switch via workbench.colorTheme above):
      # enkia.tokyo-night
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

      # ── JavaScript / TypeScript ───────────────────────────────────────────
      dbaeumer.vscode-eslint
      
      # ── Vue / Svelte ──────────────────────────────────────────────────────
      vue.volar                    # Vue 3 official language support
      svelte.svelte-vscode         # Svelte language support

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
      mads-hartmann.bash-ide-vscode   # bash LSP (bash-language-server)
      timonwong.shellcheck            # ShellCheck linting integration

      # ── Lua ───────────────────────────────────────────────────────────────
      sumneko.lua                     # Lua LSP — essential for CypherIDE config editing

      # ── Nix ───────────────────────────────────────────────────────────────
      # jnoortheen.nix-ide is referenced in language settings above.
      # Adding it here makes the formatter actually available.      
      jnoortheen.nix-ide              # Nix language support + nixd LSP integration

      # ── Rust ─────────────────────────────────────────────────────────────
      rust-lang.rust-analyzer
      serayuzgur.crates               # Cargo.toml dependency helper
      tamasfe.even-better-toml        # TOML syntax + validation
      vadimcn.vscode-lldb             # LLDB debugger for Rust/C/C++

      # ── C / C++ ──────────────────────────────────────────────────────────
      ms-vscode.cpptools
      ms-vscode.cpptools-extension-pack
      ms-vscode.cmake-tools
      twxs.cmake

      # ── Vim keybindings ──────────────────────────────────────────────────
      vscodevim.vim

      # ── Flutter / Dart ────────────────────────────────────────────────────
      dart-code.flutter               # Flutter tooling, hot reload, device management
      dart-code.dart-code             # Dart language support (flutter depends on this)

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
      redhat.vscode-yaml              # YAML support — used by k8s manifests, GH Actions

      # ── DevOps: CI/CD ─────────────────────────────────────────────────────
      github.vscode-github-actions
    ] ++ marketplaceExtensions;
  };

  # ── Shared Settings Deployment ──────────────────────────────────────────────
  # Deploy the same settings.json to Cursor and Antigravity.
  # Both editors respect the XDG config path pattern.
  # The JSON is generated from sharedSettings (same source as VSCode above).
  xdg.configFile."Cursor/User/settings.json".text =
    builtins.toJSON sharedSettings;

  xdg.configFile."antigravity/User/settings.json".text =
    builtins.toJSON sharedSettings;
}
