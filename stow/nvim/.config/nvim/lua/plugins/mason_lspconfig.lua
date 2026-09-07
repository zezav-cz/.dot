-- Mason & LSPConfig bridge (mason-lspconfig.nvim)
-- Installs the language servers listed below and enables them automatically.
return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
    "saghen/blink.cmp",
  },
  config = function()
    -- Merge completion capabilities into the base config every server inherits.
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })

    require("mason-lspconfig").setup({
      ensure_installed = {
        "clangd",
        "gopls",
        "ts_ls",
        "puppet",
        "ruby_lsp",
        "ruff",
        "lua_ls",
        "jsonls",
        "ltex",
      },
      -- An explicit allow-list, NOT the default `true`. Left on its own,
      -- mason-lspconfig enables every mason package that happens to have an LSP
      -- config in the runtimepath -- which silently attached `stylua --lsp`
      -- (duplicating conform.nvim) and codebook-lsp to code buffers.
      --
      -- ltex is deliberately absent: it boots a JVM and is started per buffer by
      -- aggressive spell mode (<leader>sa, see lua/spell.lua).
      automatic_enable = {
        "clangd",
        "gopls",
        "ts_ls",
        "puppet",
        "ruby_lsp",
        "ruff",
        "lua_ls",
        "jsonls",
      },
    })
  end,
}
