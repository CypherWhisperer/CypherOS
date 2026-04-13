return {
  "alexghergh/nvim-tmux-navigation",
  config = function()
    require('nvim-tmux-navigation').setup({})
    -- Conflicts with my DE navigation. TODO: find better alternative
    --vim.keymap.set("n", "<C-h>", "<Cmd>NvimTmuxNavigateLeft<CR>", {})
    --vim.keymap.set("n", "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", {})
    vim.keymap.set("n", "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", {})
    vim.keymap.set("n", "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", {})
    
  end,
}
