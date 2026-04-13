-- ─────────────────────────────────────────────────────────────────────────
-- PACKAGE MANAGER: LAZY.NVIM
-- ─────────────────────────────────────────────────────────────────────────
-- Installs lazy.nvim into XDG_DATA_HOME/cypher-ide/lazy/lazy.nvim
-- on first launch if it isn't present. Subsequent launches use the cached copy.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { result,                         "WarningMsg" },
      { "\nPress any key to exit...",    "Normal"},
    }, true, {})
    vim.fn.getchar()
    os.exit(1)

    -- prev
    -- error("Failed to clone lazy.nvim:\n" .. result)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ─────────────────────────────────────────────────────────────────────────
-- LAZY.NVIM SETUP
-- ───────────────────────────────────────────────────────────────────────── 
-- Lazy.nvim setup function. This is what loads lazy.
-- The function takes in two tuples; one for the plugins and 
-- another for options/ settings. 
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
