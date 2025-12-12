local M = {}

function M.spec()
  return { 'nvim-telescope/telescope.nvim', tag = 'v0.1.9', dependencies = { 'nvim-lua/plenary.nvim' } }
end

function M.setup()
  -- No default configuration here; keymaps are defined in plugins/keymaps.lua
end

return M
