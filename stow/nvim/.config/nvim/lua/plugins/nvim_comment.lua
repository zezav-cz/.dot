-- Code commenting utility (nvim-comment)
-- Allows quickly toggling line or block comments using standard shortcuts
-- (like `gcc` for lines or `gc` for visual selections) based on the active filetype.
return {
  'terrortylor/nvim-comment',
  dependencies = 'JoosepAlviste/nvim-ts-context-commentstring',
  keys = {
    { "<leader>c", "<cmd>CommentToggle<cr>", desc = "Toggle comment", mode = { "n", "v" } },
  },
  config = function()
    require("nvim_comment").setup({
      create_mappings = false,
      hook = function()
        if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
          vim.api.nvim_buf_set_option(0, "commentstring", "<!-- %s -->")
        end
      end,
    })
  end,
}
