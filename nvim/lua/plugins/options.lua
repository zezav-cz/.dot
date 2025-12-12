-- === Gruvebox
vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])
vim.opt.termguicolors = true

-- === Bufferline
do
  local bufferline = require("bufferline")
  bufferline.setup {}
end

-- nvim-tree
do
  local nvim_tree = require("nvim-tree")
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

-- nvim-comment (with ts-context hook for .vue files)
do
  local nvim_comment = require("nvim_comment")
  nvim_comment.setup({
    create_mappings = false,
    hook = function()
      if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
        vim.api.nvim_buf_set_option(0, "commentstring", "<!-- %s -->")
        -- If ts_context_commentstring is available we could call it here.
      end
    end,
  })
end

-- Global editor options (non-plugin specific)
-- Plugin-specific configuration has been moved to per-plugin modules under `lua/plugins/`.

vim.opt.termguicolors = true
