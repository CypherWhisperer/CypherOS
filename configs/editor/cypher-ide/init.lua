
-- ───────────────────────────────────────────────────────────────────────── 
-- configs/editor/cypher-ide/init.lua
--
-- CypherIDE — Neovim configuration
-- NVIM_APPNAME=cypher-ide
--
-- Part of  (submodule) of CypherOS setup.
--
-- Managed by Home Manager (modules/apps/neovim.nix).
-- Edit this file in the CypherOS repo, not in the deployed location.
-- Run:
--     `home-manager switch` # OR
--     `sudo nixos-rebuild [option] --flake /path/to/repo#[host-name]`
-- to redeploy changes.
--
-- ───────────────────────────────────────────────────────────────────────── 
require("cide-options")
require("cide-keymaps")
-- previous `require("config.lazy")` for lua/config/lazy.lua was 'buggy'
--   Neovim tries to find config/lazy.lua on the Lua module path (package.path) 
--   before lazy.nvim has had any chance to run or modify rtp. 
--
--   At the point require("config.lazy") executes, the only paths Lua searches 
--   are the standard ones — none of which contain your lua/ directory yet 
--   because nothing has set it up.
--
--   lua/config/ isn't on the path at the moment init.lua runs. You can fix this
--   by explicitly prepending your config's lua/ directory to rtp before the 
--   require, right at the top of init.lua:
--
--     `vim.opt.rtp:prepend(vim.fn.stdpath("config"))`
--     `require("config.lazy")` -- now resolvable: lua/config/lazy.lua
--
--     But the cleaer option is to simply drop the file into lua/
require("lazy_bootstrap") 

