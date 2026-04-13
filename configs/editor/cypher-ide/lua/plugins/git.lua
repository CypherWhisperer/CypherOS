-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GIT.LUA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Two plugins, two complementary responsibilities:
--   gitsigns  → in-buffer: hunk markers, staging, blame, navigation
--   fugitive  → full git workflow: status, commit, push, log, diff
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ──────────────────────────────────────────────────────────────────────────
  -- GITSIGNS — in-buffer git hunk experience
  -- ──────────────────────────────────────────────────────────────────────────
  -- Shows a colored symbol in the sign column for every changed line:
  --   │  (green)  = added line
  --   │  (red)    = deleted line (shown as a marker at the deletion point)
  --   │  (yellow) = modified line
  --
  -- Beyond signs, it enables staging/unstaging individual hunks without
  -- leaving the buffer, inline blame, and hunk previews.
  {
    "lewis6991/gitsigns.nvim",

    -- Load when a file buffer opens — no point loading before a file exists
    event = { "BufReadPre", "BufNewFile" },

    opts = {
      signs = {
        -- These are the characters shown in the sign column
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },

      -- Show blame annotation at the end of the current line.
      -- Shows WHO changed this line and WHEN, inline. Off by default —
      -- toggle it with <leader>tb (defined in the keymaps below).
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text         = true,
        virt_text_pos     = "eol",   -- end of line
        delay             = 800,     -- wait 800ms after cursor stops moving
        ignore_whitespace = false,
      },

      -- on_attach: gitsigns fires this when attaching to a buffer,
      -- same pattern as LspAttach. All keymaps go here so they're
      -- buffer-local and only active in git-tracked files.
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer  = bufnr,
            noremap = true,
            silent  = true,
            desc    = desc,
          })
        end

        -- ── HUNK NAVIGATION ────────────────────────────────────────────
        -- Jump between changed hunks in the file.
        -- "Hunk" = a contiguous block of changed lines.
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.next_hunk()
          end
        end, "Git: next hunk")

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.prev_hunk()
          end
        end, "Git: previous hunk")

        -- ── STAGING ────────────────────────────────────────────────────
        -- Stage/unstage individual hunks without touching the terminal.
        -- Stage = add to git's index (the "staging area" before commit).
        map("n", "<leader>hs", gs.stage_hunk,   "Git: stage hunk")
        map("n", "<leader>hr", gs.reset_hunk,   "Git: reset hunk")
        map("n", "<leader>hu", gs.undo_stage_hunk, "Git: undo stage hunk")

        -- Visual mode: stage/reset only the selected lines within a hunk
        map("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: stage selected lines")
        map("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: reset selected lines")

        -- Stage or reset the entire file at once
        map("n", "<leader>hS", gs.stage_buffer,  "Git: stage entire buffer")
        map("n", "<leader>hR", gs.reset_buffer,  "Git: reset entire buffer")

        -- ── INSPECTION ─────────────────────────────────────────────────
        -- Preview the diff of the hunk under cursor in a floating window
        map("n", "<leader>hp", gs.preview_hunk,  "Git: preview hunk diff")
        -- Show full git blame for the current line in a floating window
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "Git: blame current line (full)")
        -- Toggle the inline EOL blame annotation on/off
        map("n", "<leader>tb", gs.toggle_current_line_blame, "Git: toggle inline blame")
        -- Show a diff of the buffer against the index (staged version)
        map("n", "<leader>hd", gs.diffthis,      "Git: diff buffer against index")
        -- Show a diff against HEAD (last commit)
        map("n", "<leader>hD", function()
          gs.diffthis("~")
        end, "Git: diff buffer against HEAD")
        -- Toggle showing deleted lines as virtual text above the deletion point
        map("n", "<leader>td", gs.toggle_deleted, "Git: toggle deleted lines display")

        -- ── TEXT OBJECT ────────────────────────────────────────────────
        -- "ih" = "inner hunk" — select the changed lines of a hunk.
        -- Use with operators: "vih" visually selects a hunk, "dih" deletes it.
        map({ "o", "x" }, "ih", ":<C-u>Gitsigns select_hunk<CR>", "Git: select hunk (text object)")
      end,
    },
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- FUGITIVE — full git workflow inside Neovim
  -- ──────────────────────────────────────────────────────────────────────────
  -- Fugitive turns Neovim into a complete git client. The core interface
  -- is :Git (or :G for short) which opens a status window from which you
  -- can stage, commit, push, pull, and more without leaving the editor.
  --
  -- Key fugitive concepts:
  --   :Git          → the status window (stage files with 's', commit with 'cc')
  --   :Git diff     → diff the working tree
  --   :Git log      → browsable commit log
  --   :Git blame    → blame view for the whole file (not just current line)
  --   :GBrowse      → open the current file/line on GitHub/GitLab in browser
  --   :Gread        → replace buffer with the git index version of the file
  --   :Gwrite       → stage the current file (equivalent to git add)
  {
    "tpope/vim-fugitive",

    -- Load when any git-related command is called, or when opening a file.
    -- cmd lazy-loads on the listed commands; event covers the status window.
    cmd   = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "GBrowse" },
    event = { "BufReadPre" },

    config = function()
      -- Fugitive doesn't need a setup() call — it works out of the box.
      -- We just add keymaps here.

      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, {
          noremap = true,
          silent  = true,
          desc    = desc,
        })
      end

      -- Open the git status window — the main fugitive interface.
      -- Inside it: press ? to see all available keymaps.
      -- Common ones: s=stage, u=unstage, cc=commit, P=push, p=pull
      map("<leader>gs", "<cmd>Git<cr>",                "Git: open status window (fugitive)")
      -- Quick commit (opens commit message buffer)
      map("<leader>gc", "<cmd>Git commit<cr>",          "Git: commit")
      -- Push to remote
      map("<leader>gp", "<cmd>Git push<cr>",            "Git: push")
      -- Pull from remote
      map("<leader>gl", "<cmd>Git pull<cr>",            "Git: pull")
      -- Browsable git log
      map("<leader>gL", "<cmd>Git log --oneline<cr>",   "Git: log (oneline)")
      -- Side-by-side diff split for current file
      map("<leader>gd", "<cmd>Gdiffsplit<cr>",          "Git: diff split current file")
      -- Blame view for the whole file (different from gitsigns line blame)
      map("<leader>gb", "<cmd>Git blame<cr>",           "Git: blame view (whole file)")
    end,
  },

}
