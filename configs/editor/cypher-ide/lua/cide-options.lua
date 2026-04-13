-- ─────────────────────────────────────────────────────────────────────────
-- NEOVIM OPTIONS
-- ─────────────────────────────────────────────────────────────────────────
-- set before plugins so they take effect immediately) 
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
vim.opt.swapfile       = false

-- ─────────────────────────────────────────────────────────────────────────
-- NEOVIM COMMANDS
-- ─────────────────────────────────────────────────────────────────────────
--The block below simply tells Nevim to:
--    1. Use spaces instead of tabs for indentation
--    2. Use 2 spaces by default for indentation
--
-- Adjust accordingly
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- ─────────────────────────────────────────────────────────────────────────
-- NEOVIM KEYMAPS
-- ─────────────────────────────────────────────────────────────────────────
-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
-- conflicts with my DE navigation (TODO: find alternative or another strategy)
-- vim.keymap.set('n', '<c-h>', ':wincmd h<CR>') 
-- vim.keymap.set('n', '<c-l>', ':wincmd l<CR>') 

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')

-- ─────────────────────────────────────────────────────────────────────────
-- LEADER KEY
-- ─────────────────────────────────────────────────────────────────────────
--
-- `mapleader` and `maplocalleader` should be set up before
-- loading lazy.nvim so that mappings are correct and plugins
-- see the correct leader.
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"
