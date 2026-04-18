-- File explorer sidebar (nvim-tree.lua)
-- Adds a toggleable directory tree on the side of the screen for browsing,
-- creating, deleting, and renaming files and folders within the project.
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>",   desc = "Toggle file tree" },
    { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal file in tree" },
  },
  config = function()
    -- disable netrw (recommended by nvim-tree)
    vim.g.loaded_netrw       = 1
    vim.g.loaded_netrwPlugin = 1

    require("nvim-tree").setup({
      sort = { sorter = "case_sensitive" },
      view = {
        width        = 30,
        adaptive_size = true,
      },
      renderer = {
        group_empty = true,
        icons = {
          show = { git = true, file = true, folder = true },
        },
      },
      filters = { dotfiles = false },
      git     = { enable = true, ignore = false },
    })
  end,
}
