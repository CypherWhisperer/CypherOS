return { 
    "catppuccin/nvim",   -- this is the URL
    name = "catppuccin", -- plugin/ color scheme name
    priority = 1000,      -- load before other plugins that might set colors
    
    -- This block below is responsible for applying the plugins
    -- it first `require`s tha package and then calls a setup function
    -- This is conventional in lua plugins;
    -- Plugins export a setup function you have to call. It imports all setup 
    -- functions and all functionalities for the given plugin/ package into the
    -- Neovim Lua runtime for Neovim to execute 
    config = function()
      require("catppuccin").setup({ style = "mocha" })
      vim.cmd.colorscheme("catppuccin-mocha")
    end
}
