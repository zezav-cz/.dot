local M = {}

function M.spec()
  return { 'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons' }
end

function M.setup()
  local ok, bufferline = pcall(require, "bufferline")
  if not ok then return end
  bufferline.setup {}
end

return M
