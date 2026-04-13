return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- for this one, install and configure a nerd font 4 your terminal
    "nvim-tree/nvim-web-devicons", -- optional, but recommended  
  },
  lazy = false, -- neo-tree will lazily load itself
  
  config = function ()
    vim.kemap.set('n','<C-b>',
      ':Neotree filesystem reveal right<CR>', -- ensure to have the carriage return
      {}
    )
  end
}
