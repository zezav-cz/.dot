-- Install lazy.nvim if not already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo(
      { { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" }, { "\nPress any key to exit..." } }, true,
      {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
local plugins = {
  gruvbox = require("plugins.gruvbox"),
  telescope = require("plugins.telescope"),
  nvim_treesitter = require("plugins.nvim_treesitter"),
  -- nvim_tree = require("plugins.nvim_tree"),
  undotree = require("plugins.undotree"),
  nvim_comment = require("plugins.nvim_comment"),
  gitsigns = require("plugins.gitsigns"),
  mason_lspconfig = require("plugins.mason_lspconfig"),
  conform = require("plugins.conform"),
  slueth_vim = require("plugins.slueth_vim"),
  window = require("plugins.windows"),
  barbar = require("plugins.barbar"),
}

require("lazy").setup({
  plugins.gruvbox.spec(),
  plugins.telescope.spec(),
  plugins.nvim_treesitter.spec(),
  -- plugins.nvim_tree.spec(),
  plugins.undotree.spec(),
  plugins.nvim_comment.spec(),
  plugins.gitsigns.spec(),
  plugins.mason_lspconfig.spec(),
  plugins.conform.spec(),
  plugins.slueth_vim.spec(),
  plugins.window.spec(),
  plugins.barbar.spec(),
})

plugins.gruvbox.setup()
plugins.telescope.setup()
plugins.nvim_treesitter.setup()
-- plugins.nvim_tree.setup()
plugins.undotree.setup()
plugins.nvim_comment.setup()
plugins.gitsigns.setup()
plugins.mason_lspconfig.setup()
plugins.conform.setup()
plugins.slueth_vim.setup()
plugins.window.setup()
plugins.barbar.setup()
