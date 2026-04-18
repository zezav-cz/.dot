-- Colorscheme configuration (gruvbox)
-- Sets the primary visual theme and color palette for the Neovim editor UI
-- and syntax highlighting.
return {
  "ellisonleao/gruvbox.nvim",
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      contrast = "medium",
      transparent_mode = true,
    })
    vim.cmd([[colorscheme gruvbox]])
  end,
}

