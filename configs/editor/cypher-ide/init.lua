-- configs/editor/cypher-ide/init.lua
--
-- CypherIDE — Neovim configuration
-- NVIM_APPNAME=cypher-ide
--
-- This is the seed file. It bootstraps lazy.nvim and provides a clean
-- foundation.
-- TODO:  Add plugins and configuration while building CypherIDE.
--
-- Managed by Home Manager (modules/apps/neovim.nix).
-- Edit this file in the CypherOS repo, not in the deployed location.
-- Run `home-manager switch` to redeploy changes.

-- ── Options (set before plugins so they take effect immediately) ────────────
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.mouse          = "a"
vim.opt.showmode       = false      -- statusline plugin will show mode
vim.opt.clipboard      = "unnamedplus"
vim.opt.breakindent    = true
vim.opt.undofile       = true
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.signcolumn     = "yes"
vim.opt.updatetime     = 250
vim.opt.timeoutlen     = 500
vim.opt.splitright     = true
vim.opt.splitbelow     = true
vim.opt.scrolloff      = 8
vim.opt.termguicolors  = true
vim.opt.tabstop        = 2
vim.opt.shiftwidth     = 2
vim.opt.expandtab      = true

-- ── Leader Key ──────────────────────────────────────────────────────────────
-- Set before lazy.nvim loads so plugins see the correct leader
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- ── Bootstrap lazy.nvim ─────────────────────────────────────────────────────
-- Installs lazy.nvim into XDG_DATA_HOME/cypher-ide/lazy/lazy.nvim
-- on first launch if it isn't present. Subsequent launches use the cached copy.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local result = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim:\n" .. result)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ─────────────────────────────────────────────────────────────────
-- Start here. Add plugins as you evaluate distros and decide what you need.
-- Each plugin entry is a table: { "owner/repo", config = function() ... end }
require("lazy").setup({

  -- Colorscheme: Tokyo Night (matches kitty and ghostty)
  {
    "folke/tokyonight.nvim",
    priority = 1000,   -- load before other plugins that might set colors
    config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  -- Add plugins here as you build CypherIDE.
  -- Examples to evaluate from the distros:
  --   "nvim-telescope/telescope.nvim"  -- fuzzy finder
  --   "nvim-treesitter/nvim-treesitter" -- syntax and text objects
  --   "neovim/nvim-lspconfig"          -- LSP client configuration
  --   "hrsh7th/nvim-cmp"               -- completion engine
  --   "lewis6991/gitsigns.nvim"        -- git decorations

}, {
  -- lazy.nvim options
  ui = { border = "rounded" },
  performance = {
    rtp = {
      -- Disable built-in plugins you never use (speeds up startup slightly)
      disabled_plugins = {
        "gzip", "matchit", "matchparen",
        "netrwPlugin", "tarPlugin", "tohtml",
        "tutor", "zipPlugin",
      },
    },
  },
})

-- ── Basic Keymaps ────────────────────────────────────────────────────────────
-- Add keymaps here as you build. Keep them in this file until you have enough
-- to warrant splitting into lua/cypher-ide/keymaps.lua
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>",  { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>",  { desc = "Quit" })
vim.keymap.set("n", "<C-d>",     "<C-d>zz",     { desc = "Scroll down centered" })
vim.keymap.set("n", "<C-u>",     "<C-u>zz",     { desc = "Scroll up centered" })