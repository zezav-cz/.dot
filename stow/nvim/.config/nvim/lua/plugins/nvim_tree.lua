-- File explorer sidebar (nvim-tree.lua)
-- <leader>e toggles it; nothing opens a tree on startup.
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>",   desc = "Toggle file tree" },
    { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal file in tree" },
  },
  init = function()
    -- disable netrw (recommended by nvim-tree)
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  opts = {
    view = { width = 30, adaptive_size = true },
    renderer = { group_empty = true },
    filters = { dotfiles = false },
    git = { enable = true, ignore = false },
  },
}
