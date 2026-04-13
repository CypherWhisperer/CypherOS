return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate', -- build command. TSUpdate updates tree-sitter itself
  
  config = function()
    local config = require('nvim-treesitter')
    
    config.setup({
      -- Directory to install parsers and queries to 
      -- (prepended to `runtimepath` to have priority)
      install_dir = vim.fn.stdpath('data') .. '/site',
      hightlight = {enable = true},
      indent = {enable = true},
      ensure_installed = {
       "angular", "arduino", "asm", "astro", "bash", "c", "clojure", "cmake",
       "cpp", "css", "csv", "cuda", "dart", "diff", "dockerfile", "elixir",
       "fish", "git_config", "gitattributes", "gitcommit", "gitignore", 
       "glimmer", "glimmer_javascript", "glimmer_typescript", "go", "gpg",
       "helm", "html", "http", "java", "javascript", "jq", "json", "julia",
       "kitty", "kotlin", "lua", "make", "markdown", "markdown_inline",
       "mermaid", "nix", "ocaml", "php", "perl", "pascal", "powershell",
       "printf", "prisma", "python", "regex", "ruby", "rust", "scala", "scss",
       "solidity", "sql", "ssh_config", "svelte", "swift", "tmux", "toml", "tsx",
       "typescript", "udev", "vim", "vue", "xml", "yaml", "zig", "zsh"
      }
    })

    config.install({
      "angular", "arduino", "asm", "astro", "bash", "c", "clojure", "cmake",
      "cpp", "css", "csv", "cuda", "dart", "diff", "dockerfile", "elixir",
      "fish", "git_config", "gitattributes", "gitcommit", "gitignore", 
      "glimmer", "glimmer_javascript", "glimmer_typescript", "go", "gpg",
      "helm", "html", "http", "java", "javascript", "jq", "json", "julia",
      "kitty", "kotlin", "lua", "make", "markdown", "markdown_inline",
      "mermaid", "nix", "ocaml", "php", "perl", "pascal", "powershell",
      "printf", "prisma", "python", "regex", "ruby", "rust", "scala", "scss",
      "solidity", "sql", "ssh_config", "svelte", "swift", "tmux", "toml", "tsx",
      "typescript", "udev", "vim", "vue", "xml", "yaml", "zig", "zsh"
    }) --:wait(300000) --if you wish for synchronous installation behavior
  end
}
