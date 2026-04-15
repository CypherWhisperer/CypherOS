-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/lazy_bootstrap.lua
-- PACKAGE MANAGER: LAZY.NVIM
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Bootstraps lazy.nvim on first launch, then sets it up.
-- lazy.nvim is installed into XDG_DATA_HOME/nvim/lazy/lazy.nvim
-- (resolves to ~/.local/share/nvim/lazy/lazy.nvim, which respects NVIM_APPNAME).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─────────────────────────────────────────────────────────────────────────
-- LAZY.NVIM BOOTSTRAP
-- ─────────────────────────────────────────────────────────────────────────
-- Clone lazy.nvim if it isn't present. On subsequent launches, this block
-- does nothing — the fs_stat check is essentially free. 
--
-- On NixOS, lazy.nvim is installed via Nix (pkgs.vimPlugins.lazy-nvim)
-- and injected into Neovim's rtp automatically by the wrapper.
-- We do NOT clone it from GitHub — Nix owns that dependency.
--
-- For non-NixOS fallback (e.g. if someone runs this config on a plain Linux
-- machine), we keep the clone logic as a fallback below.
-- ─────────────────────────────────────────────────────────────────────────

-- Check if lazy.nvim is already on rtp (Nix-provided path)
local lazy_ok = pcall(require, "lazy")

if not lazy_ok then
  --fallback: not on rtp yet, try standard data path (non-NixOS usage)
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    -- Not installed at all — clone it (non-NixOS first launch)
    vim.notify("Bootstrapping lazy.nvim...", vim.log.levels.INFO)

    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local result = vim.fn.system({ 
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=stable", 
      lazyrepo, 
      lazypath 
    })

    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg"},
        { result,                         "WarningMsg" },
        { "\nPress any key to exit...",   "Normal"},
      }, true, {})
      vim.fn.getchar()
      os.exit(1)

      -- prev
      -- error("Failed to clone lazy.nvim:\n" .. result)
    end
  end
  -- prepend to rtp so require("lazy") finds it.
  vim.opt.rtp:prepend(lazypath)
end

-- ─────────────────────────────────────────────────────────────────────────
-- LAZY.NVIM SETUP
-- ─────────────────────────────────────────────────────────────────────────
-- lazy.setup() takes two arguments (tuples):
--   1. Plugin source: a string → scans lua/<string>/ for plugin spec files
--                    or a table → an inline plugin spec list.
--   2. Options table: global lazy.nvim configuration.
--
-- IMPORTANT: the string MUST match the actual directory name under lua/.
-- lua/plugins/ exists → "plugins" is correct.
require("lazy").setup("plugins", {

  -- ── INSTALL ──────────────────────────────────────────────────────────
  install = {
    -- Colorscheme to use while plugins are being installed on first launch.
    -- If this scheme isn't installed yet, lazy falls back to default.
    colorscheme = { "catppuccin", "habamax" }, 
  },

  -- ── UPDATE CHECKER ───────────────────────────────────────────────────
  checker = {
    enabled = true,       -- check for plugin updates in the background

     -- don't pop a notification every launch saying updates exist.
     -- You'll see it in :Lazy instead. With notify=true it becomes
     -- noise you ignore — defeating the purpose. 
    notify  = false,    
    frequency = 3600,     -- check at most once per hour (in seconds)
  },

  -- ── CHANGE DETECTION ─────────────────────────────────────────────────
  change_detection = {
    -- Watch your plugin spec files for changes and reload automatically.
    enabled = true,
    
    -- same reasoning as checker.notify — suppress the popup,
    -- let lazy handle it silently
    notify  = false, 

  },

  -- ── UI ───────────────────────────────────────────────────────────────
  ui = {
    border = "rounded",
    -- Size of the lazy window as a fraction of the editor
    size = { width = 0.85, height = 0.85 },
    -- Icons used in the lazy UI (requires a Nerd Font)
    icons = {
      cmd        = " ",
      config     = "",
      event      = "",
      ft         = " ",
      init       = " ",
      import     = " ",
      keys       = " ",
      lazy       = "󰒲 ",
      loaded     = "●",
      not_loaded = "○",
      plugin     = " ",
      runtime    = " ",
      require    = "󰢱 ",
      source     = " ",
      start      = "",
      task       = "✔ ",
      list = { "●", "➜", "★", "‒" },
    },
  },

  -- ── PERFORMANCE ──────────────────────────────────────────────────────
  performance = {
    cache = {
      enabled = true,   -- cache the Lua module loader — measurably faster startup
    },
    reset_packpath = true,   -- reset packpath to only include lazy-managed paths,
                             -- preventing accidental loading of system-installed plugins
    rtp = {
      reset = true,          -- reset rtp to a clean minimal set
                             -- prevents system/distro plugins from leaking in —
                             -- important on NixOS where system Neovim plugins could
                             -- otherwise interfere with your managed setup
      disabled_plugins = {
        -- Built-in plugins you never use. Disabling them shaves startup time.
        -- These are safe to disable in a lazy.nvim-managed config.
        "gzip",
        "matchit",        -- extended % matching (treesitter does this better)
        "matchparen",     -- highlight matching parens (plugins do this better)
        "netrwPlugin",    -- built-in file browser (w're using oil.nvim + neo-tree)
        "tarPlugin",
        "tohtml",         -- :TOhtml command (never used)
        "tutor",          -- :Tutor command
        "zipPlugin",
      },
    },
  },

  -- ── DIFF TOOL ────────────────────────────────────────────────────────
  -- How lazy displays diffs when you press 'd' on a plugin in :Lazy
  diff = {
    -- "browser" opens GitHub. "terminal_git" uses git in a terminal split.
    -- "diffview" uses diffview.nvim if you have it installed.
    cmd = "terminal_git",
  },

  -- ── HEADLESS / CI BEHAVIOUR ──────────────────────────────────────────
  -- When running Neovim headlessly (e.g. in a script or CI pipeline),
  -- you generally want to skip the interactive UI.
  headless = {
    -- Don't show the lazy progress bar during headless installs
    process = true,
    log     = true,
    task    = true,
  },
})
