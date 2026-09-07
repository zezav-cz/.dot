-- Notes vault integration (obsidian.nvim)
-- Markdown link following, note linking and templates for ~/ops/vnotes.
return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ot", "<cmd>Obsidian template<cr>", desc = "Insert Obsidian template" },
    { "<leader>ol", "<cmd>Obsidian link<cr>",     desc = "Link to Obsidian note", mode = "v" },
    { "<leader>ol", "viw:Obsidian link<cr>",      desc = "Link word to Obsidian note" },
  },
  opts = {
    workspaces = {
      { name = "vnotes", path = vim.fn.expand("~/ops/vnotes/") },
    },
    templates = {
      folder      = "99_templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },
    frontmatter     = { enabled = false },
    legacy_commands = false,
  },
}
