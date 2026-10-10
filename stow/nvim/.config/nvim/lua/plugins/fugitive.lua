-- vim-fugitive: `:Git` for anything git, plus the two things it does better
-- than lazygit -- blame as a real buffer you can move through, and an inline
-- vimdiff of the current file against the index.
--
-- Status (`<leader>gs`) is the interactive `git status`: `-` stages/unstages
-- the file under the cursor, `=` toggles its inline diff, `cc` commits, `dv`
-- opens a vimdiff, `g?` lists the rest. lazygit (`<leader>gg`) remains the
-- richer UI for that; this is for when you do not want to leave the editor.
--
-- Commits made through `:Git commit` here do NOT sign -- the working tree's
-- git config applies, and signing is off globally (doc/configs.md). Use
-- lazygit for signed commits.
return {
  "tpope/vim-fugitive",
  cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Gedit", "GBrowse", "GMove", "GDelete" },
  keys = {
    { "<leader>gs", "<cmd>Git<cr>", desc = "Git status (fugitive)" },
    { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
    { "<leader>gv", "<cmd>Gvdiffsplit<cr>", desc = "Vimdiff this file against the index" },
    { "<leader>gw", "<cmd>Gwrite<cr>", desc = "Stage this file (git add)" },
  },
}
