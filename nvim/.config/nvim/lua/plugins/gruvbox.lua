local M = {}

function M.spec()
  return { "ellisonleao/gruvbox.nvim", priority = 1000 }
end

function M.setup()
  vim.o.background = "dark"
  vim.opt.termguicolors = true
  vim.cmd([[colorscheme gruvbox]])
end

return M

