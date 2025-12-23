local M = {}

function M.spec()
  return {
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = { { "mason-org/mason.nvim", opts = {} }, "neovim/nvim-lspconfig", },
  }
end

function M.setup()
  local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not ok then return end

  mason_lspconfig.setup {
    automatic_enable = true,
    ensure_installed = {
      "clangd",
      "gopls",
      "ts_ls",
      "puppet",
      "ruby_lsp",
      "ruff",
      "lua_ls",
      "jsonls",
    },
  }
end

return M
