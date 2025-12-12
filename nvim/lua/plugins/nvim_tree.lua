local M = {}

function M.spec()
  return { "nvim-tree/nvim-tree.lua", version = "*", lazy = false, requires = { "nvim-tree/nvim-web-devicons" } }
end

function M.setup()
  local ok, nvim_tree = pcall(require, "nvim-tree")
  if not ok then return end

  nvim_tree.setup {
    sort = {
      sorter = "case_sensitive",
    },
    view = {
      width = 30,
      adaptive_size = true,
    },
    renderer = {
      group_empty = true,
    },
    filters = {
      dotfiles = false,
    },
  }
end

return M
