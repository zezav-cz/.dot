-- Peek LSP locations in a floating window (VSCode-style "Peek Definition")
-- Complements the go-to keymaps in lsp_keymaps.lua.
return {
  "rmagatti/goto-preview",
  keys = {
    {
      "<leader>pd",
      function() require("goto-preview").goto_preview_definition() end,
      desc = "Peek definition",
    },
    {
      "<leader>pi",
      function() require("goto-preview").goto_preview_implementation() end,
      desc = "Peek implementation",
    },
    {
      "<leader>pr",
      function() require("goto-preview").goto_preview_references() end,
      desc = "Peek references",
    },
    {
      "<leader>pt",
      function() require("goto-preview").goto_preview_type_definition() end,
      desc = "Peek type definition",
    },
    {
      "<leader>px",
      function() require("goto-preview").close_all_win() end,
      desc = "Close all peek windows",
    },
  },
  opts = {
    default_mappings = false,
  },
}
