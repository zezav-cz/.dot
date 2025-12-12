local M = {}

function M.spec()
  return { 'terrortylor/nvim-comment', dependencies = 'JoosepAlviste/nvim-ts-context-commentstring' }
end

function M.setup()
  local ok, nvim_comment = pcall(require, "nvim_comment")
  if not ok then return end

  nvim_comment.setup({
    create_mappings = false,
    hook = function()
      if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
        vim.api.nvim_buf_set_option(0, "commentstring", "<!-- %s -->")
      end
    end,
  })
end

return M
