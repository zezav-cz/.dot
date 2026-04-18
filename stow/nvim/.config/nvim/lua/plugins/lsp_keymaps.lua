-- Keybindings for built-in LSP features
-- Defines the keyboard shortcuts for LSP actions such as Go To Definition,
-- Rename symbol, Show References, and displaying floating hover documentation.
return {
  "neovim/nvim-lspconfig",
  lazy = false,
  dependencies = { "mason-org/mason-lspconfig.nvim" },
  keys = {
    {
      "<leader>td",
      function()
        vim.diagnostic.enable(not vim.diagnostic.is_enabled())
      end,
      desc = "Toggle Diagnostics",
    },
  },
  opts = { servers = {} },
  config = function(_, opts)
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gr", vim.lsp.buf.references, "Go to references")
        map("gi", vim.lsp.buf.implementation, "Go to implementation")
        map("K", vim.lsp.buf.hover, "Hover documentation")
        map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
        map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
        map("]d", vim.diagnostic.goto_next, "Next diagnostic")
        map("<leader>de", vim.diagnostic.open_float, "Show diagnostic float")
        map("<leader>ll", function() require("lint").try_lint() end, "Run linters")
      end,
    })
    
    -- Note: Server setup is now handled in mason_lspconfig.lua via handlers
  end,
}
