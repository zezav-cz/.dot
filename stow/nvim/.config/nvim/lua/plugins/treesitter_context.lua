-- Sticky scope headers (nvim-treesitter-context).
--
-- Once the line that opens the function, class or block you are in scrolls
-- off the top, it is pinned there instead: the first lines of the window show
-- the chain of enclosing scopes, outermost first, so you always know where you
-- are. Like the scope guide in indent_blankline.lua it is treesitter-driven,
-- so it needs a parser for the filetype and does nothing without one.
--
-- `[x` jumps up to the pinned scope's real line; `<leader>tc` turns the whole
-- thing off and on.
return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    { "[x", function() require("treesitter-context").go_to_context(vim.v.count1) end, desc = "Jump to enclosing scope" },
    { "<leader>tc", "<cmd>TSContext toggle<cr>", desc = "Toggle sticky scope header" },
  },
  -- Plugin defaults otherwise.
  opts = {
    -- The header describes the first visible line, not the cursor: a function
    -- whose `def` has scrolled away while part of its body is still on screen
    -- stays pinned wherever the cursor happens to be.
    mode = "topline",
    -- Every window, not only the current one, so both panes of a diff review
    -- (diffview, fugitive) carry their own header.
    multiwindow = true,
  },
}
