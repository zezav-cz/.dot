-- Personal Knowledge Management (obsidian.nvim)
-- Connects Neovim to local Obsidian vaults, enabling markdown link following,
-- tag autocompletion, bidirectional links, and daily note creation.
return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ot", "<cmd>Obsidian template<cr>",  desc = "Insert Obsidian template" },
    { "<leader>ol", "<cmd>Obsidian link<cr>",       desc = "Link to Obsidian note",   mode = "v" },
    { "<leader>ol", "viw:Obsidian link<cr>",        desc = "Link word to Obsidian note" },
  },
  config = function()
    vim.opt_local.conceallevel = 2
    require("obsidian").setup({
      workspaces = {
        { name = "vnotes", path = vim.fn.expand("~/vnotes/") },
      },
      templates = {
        folder      = "99_templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },
      frontmatter    = { enabled = false },
      legacy_commands = false,
    })
  end,
}
