-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FORMATTING AND LINTING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Handles two separate concerns:
--   1. FORMATTING  → conform.nvim  (runs Prettier, Stylua, Black, etc.)
--   2. LINTING     → nvim-lint     (runs ESLint, Pylint, etc.)
--
-- WHY NOT none-ls?
--   none-ls (null-ls successor) works by pretending to be an LSP server and
--   piping formatter/linter output through the LSP protocol. It works, but
--   it's architectural overhead — a fake server process running inside Neovim
--   just to relay CLI tool output. conform.nvim and nvim-lint do the same jobs
--   directly with no indirection, less memory, and better behavior
--   (conform preserves cursor position and folds; none-ls replaces the whole buffer).
--   The entire community (LazyVim, kickstart.nvim) has migrated to this pair.
--
-- WHY TWO PLUGINS instead of one?
--   Formatting and linting are fundamentally different operations:
--     • Formatting: "rewrite this file to match a style" — runs on save, produces
--       a new version of the file.
--     • Linting: "analyze this file for problems" — runs as you type/save, produces
--       diagnostics (the red/yellow underlines you already see from LSP).
--   Keeping them separate means you can disable one without touching the other.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ──────────────────────────────────────────────────────────────────────────
  -- CONFORM.NVIM — Formatter
  -- ──────────────────────────────────────────────────────────────────────────
  -- conform runs external formatter binaries (Prettier, Stylua, Black, etc.)
  -- and applies their output to your buffer. Unlike none-ls, it computes a
  -- minimal diff — only the changed lines are replaced — so your cursor
  -- position, folds, and undo history are preserved after formatting.
  {
    "stevearc/conform.nvim",

    -- lazy-load: only activate when a real file buffer is opened.
    -- BufReadPre = before reading an existing file into a buffer.
    -- BufNewFile  = when creating a brand-new file.
    -- This means conform doesn't load at all if you open Neovim with no file.
    event = { "BufReadPre", "BufNewFile" },

    config = function()
      local conform = require("conform")

      conform.setup({
        -- ── FORMATTERS BY FILETYPE ──────────────────────────────────────
        -- Maps a filetype → list of formatters to run, in order.
        -- If a formatter isn't installed, conform skips it gracefully.
        -- You can list multiple formatters per type; they run sequentially
        -- (e.g. isort sorts imports first, then black formats the rest).
        formatters_by_ft = {
          -- Web
          javascript      = { "prettier" },
          typescript      = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          svelte          = { "prettier" },
          vue             = { "prettier" },
          astro           = { "prettier" },
          css             = { "prettier" },
          scss            = { "prettier" },
          html            = { "prettier" },
          json            = { "prettier" },
          jsonc           = { "prettier" },
          yaml            = { "prettier" },
          markdown        = { "prettier" },
          graphql         = { "prettier" },

          -- Lua (this very config file!)
          -- stylua is the standard Lua formatter; install via Mason: :MasonInstall stylua
          lua             = { "stylua" },

          -- Python: isort fixes import order first, then black formats everything.
          -- Install via Mason: :MasonInstall isort black
          python          = { "isort", "black" },

          -- Shell scripts
          -- Install via Mason: :MasonInstall shfmt
          sh              = { "shfmt" },
          bash            = { "shfmt" },
          zsh             = { "shfmt" },

          -- Go has gofmt built into the language toolchain, but goimports also
          -- auto-manages import statements. Install: :MasonInstall goimports
          go              = { "goimports", "gofmt" },

          -- Rust: rustfmt is the official formatter, ships with the Rust toolchain.
          -- conform can find it automatically if cargo is on your PATH.
          rust            = { "rustfmt" },

          -- SQL
          -- Install via Mason: :MasonInstall sql-formatter
          sql             = { "sql_formatter" },

          -- Nix (relevant to your CypherOS / NixOS work)
          -- Install via Mason: :MasonInstall nixfmt
          nix             = { "nixfmt" },

          -- Fallback: if no filetype-specific formatter is configured,
          -- try to use any formatter the attached LSP server provides.
          -- The "*" key means "all filetypes".
          -- ["*"] = { "inject" },   -- uncomment to use LSP formatter as last resort

          -- "_" means "filetypes with no formatters configured".
          -- trim_whitespace removes trailing spaces — safe for any file.
          ["_"]           = { "trim_whitespace" },
        },

        -- ── FORMAT ON SAVE ──────────────────────────────────────────────
        -- This is the "auto-format when you hit :w" behavior.
        -- lsp_fallback = true: if no conform formatter is found for this filetype,
        -- fall back to the LSP server's built-in formatter (if it has one).
        format_on_save = {
          timeout_ms   = 1000,   -- abort if formatter takes longer than 1 second
          lsp_fallback = true,   -- use LSP formatter if no conform formatter configured
        },

        -- ── FORMATTER-SPECIFIC OPTIONS ──────────────────────────────────
        -- Override settings for individual formatters here.
        -- These are passed directly to the formatter binary.
        formatters = {
          -- prettier: don't let conform set the --tab-width flag;
          -- let your project's .prettierrc file control that instead.
          prettier = {
            prepend_args = { "--prose-wrap", "always" },
          },
          -- shfmt: use 2-space indentation for shell scripts
          shfmt = {
            prepend_args = { "-i", "2" },
          },
        },
      })

      -- ── MANUAL FORMAT KEYMAP ──────────────────────────────────────────
      -- <leader>mp = "manual prettier" (or think of it as "format")
      -- This triggers formatting on demand, without waiting for a save.
      -- async = true so Neovim doesn't freeze on slow formatters.
      vim.keymap.set({ "n", "v" }, "<leader>mp", function()
        conform.format({
          lsp_fallback = true,
          async        = true,
          timeout_ms   = 1000,
        })
      end, { desc = "Format: run conform on current buffer/selection", noremap = true, silent = true })

    end,
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- NVIM-LINT — Linter
  -- ──────────────────────────────────────────────────────────────────────────
  -- nvim-lint runs external linter binaries (ESLint, Pylint, Luacheck, etc.)
  -- and feeds their output into Neovim's diagnostic system — the same system
  -- that LSP uses for errors and warnings. This means lint results appear with
  -- the same signs, virtual text, and keymaps you already configured in lsp.lua.
  --
  -- Note: your LSP servers (ts_ls, pyright, lua_ls) already provide SOME
  -- diagnostics. nvim-lint adds the linter's perspective on top — for example,
  -- ts_ls handles TypeScript type errors, while ESLint handles style/rule violations.
  -- They complement each other rather than conflict.
  {
    "mfussenegger/nvim-lint",

    -- Same lazy-load strategy as conform: only load when a buffer is opened.
    event = { "BufReadPre", "BufNewFile" },

    config = function()
      local lint = require("lint")

      -- ── LINTERS BY FILETYPE ───────────────────────────────────────────
      -- Maps filetype → list of linters to run.
      -- Install all of these via Mason before they'll work.
      -- :MasonInstall eslint_d pylint luacheck shellcheck markdownlint
      lint.linters_by_ft = {
        -- JavaScript / TypeScript
        -- eslint_d is the daemon version of ESLint — starts once, stays running.
        -- Much faster than cold-starting ESLint on every lint trigger.
        javascript      = { "eslint_d" },
        typescript      = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte          = { "eslint_d" },
        vue             = { "eslint_d" },

        -- Python
        python          = { "pylint" },

        -- Lua
        -- luacheck checks for undefined globals, unused variables, etc.
        lua             = { "luacheck" },

        -- Shell
        -- shellcheck is the gold standard for bash/sh linting.
        sh              = { "shellcheck" },
        bash            = { "shellcheck" },

        -- Markdown
        markdownlint    = { "markdownlint" },

        -- Docker
        dockerfile      = { "hadolint" },

        -- Nix
        nix             = { "nix" },
      }

      -- ── LINT TRIGGER AUTOCMD ──────────────────────────────────────────
      -- nvim-lint doesn't lint automatically — you have to tell it when to run.
      -- This autocmd runs the linter on these events:
      --
      --   BufEnter     → when you switch to a buffer (catches files already open)
      --   BufWritePost → after saving (catches changes you just wrote)
      --   InsertLeave  → when you leave insert mode (near-realtime feedback)
      --
      -- We intentionally don't use TextChanged (fires on every keystroke) because
      -- that would spawn a new linter process on every single character you type.
      local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group    = lint_augroup,
        callback = function()
          -- try_lint() checks if a linter is configured for the current filetype
          -- and runs it. If no linter is configured, it does nothing silently.
          lint.try_lint()
        end,
      })

      -- ── MANUAL LINT KEYMAP ────────────────────────────────────────────
      -- Trigger linting on demand. Useful if you want to check a file without
      -- waiting for a save or a mode change.
      vim.keymap.set("n", "<leader>ml", function()
        lint.try_lint()
      end, { desc = "Lint: trigger linter on current buffer", noremap = true, silent = true })

    end,
  },

}
