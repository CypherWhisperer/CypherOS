-- ─────────────────────────────────────────────────────────────────────────
-- CYPHER IDE KEY MAPS
-- ─────────────────────────────────────────────────────────────────────────
--
-- ── Basic Keymaps ────────────────────────────────────────────────────────
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>",  { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>",  { desc = "Quit" })
vim.keymap.set("n", "<C-d>",     "<C-d>zz",     { desc = "Scroll down centered" })
vim.keymap.set("n", "<C-u>",     "<C-u>zz",     { desc = "Scroll up centered" })
