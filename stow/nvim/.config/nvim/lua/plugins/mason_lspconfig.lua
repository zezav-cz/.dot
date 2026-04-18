-- Mason & LSPConfig Bridge (mason-lspconfig.nvim)
-- Connects Mason (the package manager) with built-in lspconfig to automatically
-- setup and configure language servers once they are installed.
return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
  },
  config = function()
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
        "codebook",
        "ltex",
      },
      handlers = {
        function(server_name)
          local lspconfig = require("lspconfig")
          -- Try to get capabilities from blink.cmp
          local has_blink, blink = pcall(require, "blink.cmp")
          local capabilities = vim.lsp.protocol.make_client_capabilities()
          if has_blink then
            capabilities = blink.get_lsp_capabilities(capabilities)
          end
          
          local config = { capabilities = capabilities }
          
          lspconfig[server_name].setup(config)
        end,
      }
    })

    vim.lsp.enable("codebook")
  end,
}
