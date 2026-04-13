-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LSP.LUA — Language Server Protocol Configuration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- This file manages the full LSP stack:
--   1. mason.nvim        — installs LSP servers, formatters, linters as binaries
--   2. mason-lspconfig   — bridges Mason with nvim-lspconfig; auto-enables servers
--   3. nvim-lspconfig    — provides default configs for each server
--
-- The flow is: Mason installs the binary → mason-lspconfig enables it via
-- vim.lsp.enable() → nvim-lspconfig supplies its launch command and settings →
-- Neovim's built-in LSP client connects to the running server process.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ──────────────────────────────────────────────────────────────────────────
  -- 1. MASON
  -- Package manager for LSP servers, DAP adapters, linters, and formatters.
  -- Opens with :Mason — lets you browse, install, and update tools.
  -- ──────────────────────────────────────────────────────────────────────────
  {
    "mason-org/mason.nvim",
    -- `opts` is a lazy.nvim shorthand: it calls require("mason").setup(opts)
    -- automatically. You don't need a separate `config` function for simple setups.
    opts = {
      ui = {
        -- Rounded borders on the Mason popup window
        border = "rounded",
        icons = {
          package_installed   = "✓",
          package_pending     = "➜",
          package_uninstalled = "✗",
        },
      },
      -- How many tools Mason is allowed to install simultaneously
      max_concurrent_installers = 4,
    },
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- 2. MASON-LSPCONFIG
  -- The bridge between Mason and nvim-lspconfig.
  -- Responsibilities:
  --   • Ensures listed servers are installed via Mason (ensure_installed)
  --   • Automatically calls vim.lsp.enable() for every Mason-installed server
  --     (automatic_enable = true, which is the default)
  -- ──────────────────────────────────────────────────────────────────────────
  {
    "mason-org/mason-lspconfig.nvim",
    -- Dependencies must be loaded BEFORE this plugin initializes.
    -- lazy.nvim respects this order automatically.
    dependencies = {
      { "mason-org/mason.nvim" },
      "neovim/nvim-lspconfig",
    },
    opts = {
      -- Servers to auto-install if not already present on the system.
      -- Trim this list to only languages you actually use;
      -- Installing 40 servers on first launch will be slow. 
      -- Add more as your work requires them.
      ensure_installed = {
        -- Extend when needed
        --
        -- "arduino_language_server", "clojure_lsp", "elixirls","julials",
        -- "kotlin_language_server",  "ocamllsp", "intelephense", "powershell_es",
        -- "solargraph", "solidity_ls", "perlpls", 
        --
        --  These Need a non-trivial extra configuration to get 'em working
        -- "jdtls",   -- download a full JDT runtime
        -- "metals",  -- bootstraps an entire Scala toolchain 
        --
        -- Only add if you install the Swift toolchain on your machine, and note it won't
        -- be Mason-managed; you'd enable it via vim.lsp.enable('sourcekit') manually.
        -- "sourcekit", 

        -- Web / JS ecosystem
        "ts_ls",          -- TS & JS (NOTE: "tsserver" name was deprecated)
        "html",           -- HTML
        "cssls",          -- CSS / SCSS / Less
        "jsonls",         -- JSON with schema support
        "eslint",         -- ESLint as an LSP (diagnostics + fix-on-save)
        "astro",          -- Astro framework
        "angularls",      -- Angular framework
        "svelte",         -- Svelte framework
        "graphql",        -- GraphQL
        "prismals",       -- Prisma ORM schemas
        "lemminx",        -- XML

        -- Systems / compiled languages
        "lua_ls",         -- Lua
        "clangd",         -- C and C++
        "cmake",
        "rust_analyzer",  -- Rust (large binary)
        "gopls",          -- Go
        "zls",            -- Zig

        -- Scripting / interpreted
        "pyright",        -- Python (static type checker + LSP)
        "bashls",         -- Bash / shell scripts

        -- Config & markup
        "yamlls",         -- YAML (with schema support)
        "taplo",          -- TOML
        "dockerls",       -- Dockerfile
        "marksman",       -- Markdown (link checking, references)

        -- Extras
        "volar",          -- Vue 3
        "helm_ls",        -- Helm chart templates
        "nixd",           -- Nix expressions
        "sqlls",          -- SQL
        "vimls",
      },

      -- automatic_enable: mason-lspconfig will call vim.lsp.enable() for every
      -- server it installed. This is the default (true). You can exclude specific
      -- servers here if you want to manage their enable/disable manually.
      -- Example: automatic_enable = { exclude = { "rust_analyzer" } }
      automatic_enable = true,
    },
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- 3. NVIM-LSPCONFIG
  -- Provides pre-written default configs (cmd, filetypes, root detection)
  -- for hundreds of language servers so you don't have to write them yourself.
  -- Also exposes the lspconfig.server_name.setup() API for per-server overrides.
  -- ────────────────────────────────────────────────────────────────────────── 
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()

      -- ── DIAGNOSTIC DISPLAY ───────────────────────────────────────────────
      -- This controls how Neovim shows LSP errors/warnings in your buffer.
      -- This is separate from keymaps — it's global visual configuration.
      vim.diagnostic.config({
        -- Show error messages as virtual text at the end of each line
        virtual_text = {
          spacing = 4,          -- spaces between code and the message
          prefix  = "●",        -- symbol before each diagnostic message
        },
        -- Show diagnostics as a separate "virtual line" below the offending line
        -- (Neovim 0.11+ feature — comment out if you're on an older version)
        virtual_lines = { current_line = true },
        -- Show signs (symbols) in the left gutter column
        signs = true,
        -- Update diagnostics as you type (not just on save)
        update_in_insert = false,
        -- Sort diagnostics: errors first, then warnings, hints, info
        severity_sort = true,
        -- Style the floating diagnostic window (triggered by <leader>e)
        float = {
          border = "rounded",
          source = true,   -- show which LSP server produced this diagnostic
        },
      })

      -- ── DIAGNOSTIC SIGNS (gutter icons) ──────────────────────────────────
      -- These are the icons shown in the sign column (the thin column left of
      -- line numbers) to indicate errors, warnings, hints, and info.
      local signs = {
        Error = " ",
        Warn  = " ",
        Hint  = "󰠠 ",
        Info  = " ",
      }
      for type, icon in pairs(signs) do
        -- "DiagnosticSign" .. "Error" → "DiagnosticSignError", etc.
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- ── PER-SERVER SETTINGS ───────────────────────────────────────────────
      -- For most servers, mason-lspconfig + nvim-lspconfig's built-in defaults
      -- are sufficient — you don't need to call lspconfig.server.setup({}) at all.
      --
      -- Only use this section when you need to override something specific,
      -- like passing extra settings, disabling a feature, or customizing root
      -- detection for a particular server.

      local lspconfig = require("lspconfig")

      -- lua_ls: Tell the Lua language server that "vim" is a valid global.
      -- Without this, every reference to `vim` in your Neovim config would
      -- show a "undefined global 'vim'" warning.
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT", -- Neovim uses LuaJIT, not standard Lua
            },
            diagnostics = {
              -- Recognize these globals so lua_ls doesn't warn about them
              globals = { "vim", "require" },
            },
            workspace = {
              -- Make lua_ls aware of Neovim's built-in Lua API and plugin APIs.
              -- This enables autocomplete for vim.* functions.
              library = vim.api.nvim_get_runtime_file("", true),
              -- Suppress the "Do you want to configure your work environment?"
              -- prompt that lua_ls shows on first launch
              checkThirdParty = false,
            },
            telemetry = {
              enable = false, -- Don't send usage data to the lua_ls team
            },
          },
        },
      })

      -- jsonls: Enable JSON schema validation.
      -- Schemas tell the server what keys are valid in specific JSON files
      -- (e.g. package.json, tsconfig.json, .eslintrc.json).
      lspconfig.jsonls.setup({
        settings = {
          json = {
            -- schemastore.nvim (optional plugin) auto-populates this list.
            -- Without that plugin, you can hardcode schemas like below:
            -- schemas = {
            --   { fileMatch = { "package.json" }, url = "https://json.schemastore.org/package.json" },
            -- },
            validate = { enable = true },
          },
        },
      })

      -- yamlls: Enable YAML schema validation (similar to jsonls).
      lspconfig.yamlls.setup({
        settings = {
          yaml = {
            schemaStore = {
              enable  = true,       -- use the built-in schemastore
              url     = "",         -- required when enable = true
            },
            validate = true,
            format   = { enable = true },
          },
        },
      })

      -- ts_ls: TypeScript / JavaScript LSP.
      -- The name changed from "tsserver" to "ts_ls" — using the old name errors.
      -- Adding `init_options` enables support for TypeScript plugins if needed.
      lspconfig.ts_ls.setup({
        -- Uncomment if you use Angular or Vue and need TS plugin support:
        -- init_options = {
        --   plugins = { ... }
        -- }
      })

      -- ── LSPATTACH AUTOCMD ─────────────────────────────────────────────────
      -- This is the CORE of the modern LSP keymap setup.
      --
      -- WHY use LspAttach instead of global keymaps?
      --   Global keymaps (vim.keymap.set outside this autocmd) are set once
      --   when your config loads — they exist in EVERY buffer, even plain text
      --   files where no LSP is running. That means pressing "gd" in a .txt
      --   file would try to call vim.lsp.buf.definition() and fail silently.
      --
      --   LspAttach fires ONLY when a language server successfully connects to
      --   a specific buffer. By passing `buffer = ev.buf`, the keymaps are
      --   BUFFER-LOCAL — they only exist in that buffer and are automatically
      --   cleaned up when you close it.
      --
      -- WHY wrap it in an augroup?
      --   If you re-source this file (:source %), Neovim would register the
      --   autocmd again — so one LspAttach event would trigger it twice,
      --   setting every keymap twice. `clear = true` removes old autocmds in
      --   the group before registering new ones, preventing duplication.

      local lsp_augroup = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = lsp_augroup,
        desc  = "Set LSP keymaps when a language server attaches to a buffer",
        callback = function(ev)
          -- ev.buf    → the buffer number the server just attached to
          -- ev.data.client_id → the ID of the LSP client (server instance)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end -- safety guard: abort if client not found

          -- Shared options for all keymaps in this buffer:
          --   buffer  = ev.buf  → makes the keymap LOCAL to this buffer only
          --   noremap = true    → prevents this mapping from being re-mapped by other plugins
          --   silent  = true    → suppresses "Press ENTER" prompts
          local opts = function(description)
            return {
              buffer  = ev.buf,
              noremap = true,
              silent  = true,
              desc    = description, -- shown in :map output and which-key popups
            }
          end

          -- ── NAVIGATION ─────────────────────────────────────────────────
          -- Jump to where a symbol is DEFINED (where it was written/declared)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition,      opts("LSP: Go to definition"))
          -- Jump to the DECLARATION (e.g. the header in C, or interface in TS)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration,     opts("LSP: Go to declaration"))
          -- Jump to the TYPE DEFINITION (e.g. hover on a variable → jump to its type)
          vim.keymap.set("n", "go", vim.lsp.buf.type_definition,  opts("LSP: Go to type definition"))
          -- Show all IMPLEMENTATIONS of an interface or abstract method
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation,   opts("LSP: Go to implementation"))
          -- List all REFERENCES to the symbol under cursor across the project
          vim.keymap.set("n", "gr", vim.lsp.buf.references,       opts("LSP: Show references"))

          -- ── INFORMATION ────────────────────────────────────────────────
          -- Show documentation popup for the symbol under cursor (type, description)
          -- Press K again while the popup is open to enter it and scroll
          vim.keymap.set("n", "K",     vim.lsp.buf.hover,         opts("LSP: Hover documentation"))
          -- Show SIGNATURE HELP — the parameters of the function you're calling.
          -- Very useful when you're inside function parentheses and forget the args.
          vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts("LSP: Signature help"))
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts("LSP: Signature help"))

          -- ── EDITING ────────────────────────────────────────────────────
          -- Rename the symbol under cursor across ALL files in the project.
          -- Much safer than a search-and-replace because it understands scope.
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,   opts("LSP: Rename symbol"))
          -- Open a list of CODE ACTIONS: quick fixes, imports, refactors, etc.
          -- Works in both normal mode and visual mode (for range actions)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("LSP: Code actions"))
          -- Format the current file using the LSP server's formatter.
          -- async=true means Neovim won't freeze while the formatter runs.
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts("LSP: Format file"))

          -- ── DIAGNOSTICS ────────────────────────────────────────────────
          -- Open a floating window showing the full diagnostic message at cursor.
          -- Useful when the virtual text is truncated or hard to read.
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts("LSP: Show diagnostic float"))
          -- Jump to the PREVIOUS diagnostic (error/warning) in this file
          vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, opts("LSP: Previous diagnostic"))
          -- Jump to the NEXT diagnostic (error/warning) in this file
          vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, opts("LSP: Next diagnostic"))
          -- Jump specifically to the next ERROR (skipping warnings/hints)
          vim.keymap.set("n", "]e", function()
            vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR })
          end, opts("LSP: Next error"))
          vim.keymap.set("n", "[e", function()
            vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR })
          end, opts("LSP: Previous error"))

          -- ── WORKSPACE ──────────────────────────────────────────────────
          -- Show all symbols (functions, classes, variables) in the current file.
          -- Pairs well with Telescope for fuzzy searching.
          vim.keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol,  opts("LSP: Document symbols"))
          -- Same but across the whole project workspace
          vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts("LSP: Workspace symbols"))

          -- ── INLAY HINTS (Neovim 0.10+) ────────────────────────────────
          -- Inlay hints are subtle inline annotations showing inferred types,
          -- parameter names, etc. Example: add(/*x=*/1, /*y=*/2)
          -- Only enable the toggle if this server actually supports inlay hints
          if client.supports_method("textDocument/inlayHint") then
            vim.keymap.set("n", "<leader>ih", function()
              -- Toggle: if hints are on, turn off; if off, turn on
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }))
            end, opts("LSP: Toggle inlay hints"))
          end

          -- ── FORMAT ON SAVE (opt-in) ────────────────────────────────────
          -- Uncomment the block below if you want the file to auto-format
          -- every time you save. The supports_method guard ensures we only
          -- set this up for servers that actually provide a formatter.
          --
          -- if client.supports_method("textDocument/formatting") then
          --   vim.api.nvim_create_autocmd("BufWritePre", {
          --     buffer = ev.buf,
          --     group  = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = false }),
          --     callback = function()
          --       vim.lsp.buf.format({ bufnr = ev.buf, async = false })
          --     end,
          --   })
          -- end

        end, -- end of LspAttach callback
      })

    end, -- end of nvim-lspconfig config function
  },

  {
    -- ──────────────────────────────────────────────────────────────────────────
    -- 4. MASON TOOL INSTALLER
    -- ────────────────────────────────────────────────────────────────────────── 
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      -- Everything Mason can install goes here — LSP servers, formatters, linters.
      -- This is the single source of truth for our entire toolchain.
      -- Use Mason package names here (which differ slightly from lspconfig names
      -- in some cases — e.g. lspconfig uses "ts_ls" but Mason calls it "typescript-language-server").
      ensure_installed = {

        -- ── LSP SERVERS ──────────────────────────────────────────────────
        -- These overlap with mason-lspconfig's ensure_installed intentionally.
        -- mason-tool-installer handles the installation; mason-lspconfig handles
        -- the enabling. Having both listed in both places is the correct pattern.
        "typescript-language-server",  -- ts_ls
        "lua-language-server",         -- lua_ls
        "html-lsp",
        "css-lsp",
        "json-lsp",
        "eslint-lsp",
        "pyright",
        "bash-language-server",
        "yaml-language-server",
        "dockerfile-language-server",
        "taplo",                       -- TOML
        "marksman",                    -- Markdown
        "nixd",                        -- Nix

        -- ── FORMATTERS (used by conform.nvim) ────────────────────────────
        "prettier",                    -- JS/TS/CSS/HTML/JSON/YAML/Markdown
        "stylua",                      -- Lua
        "black",                       -- Python
        "isort",                       -- Python import sorting
        "shfmt",                       -- Shell scripts
        "goimports",                   -- Go

        -- ── LINTERS (used by nvim-lint) ───────────────────────────────────
        "eslint_d",                    -- JS/TS (daemon, much faster than eslint)
        "pylint",                      -- Python
        "luacheck",                    -- Lua
        "shellcheck",                  -- Shell scripts
        "markdownlint",                -- Markdown
        "hadolint",                    -- Dockerfile
      },

      -- Check for tool updates automatically on startup.
      -- false = only install missing tools, don't update existing ones.
      -- Set to true if you want Mason to keep everything current on every launch
      -- (slightly slower startup, but you're always on latest versions).
      auto_update = false,
    },
  },

}
