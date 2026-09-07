-- Keybindings for built-in LSP features.
-- Server setup itself happens in mason_lspconfig.lua; this only maps keys once
-- a server actually attaches to a buffer.
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
      desc = "Toggle diagnostics",
    },
    {
      "<leader>li",
      "<cmd>checkhealth vim.lsp<cr>",
      desc = "LSP status (what attached, and why not)",
    },
  },
  config = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("<leader>gd", vim.lsp.buf.definition, "Go to definition")
        map("<leader>gi", vim.lsp.buf.implementation, "Go to implementation")
        map("<leader>gr", vim.lsp.buf.references, "Go to references")
        map("<leader>gt", vim.lsp.buf.type_definition, "Go to type definition")
        map("<leader>gD", vim.lsp.buf.declaration, "Go to declaration")
        map("K", vim.lsp.buf.hover, "Hover documentation")
        map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("[d", function() vim.diagnostic.jump({ count = -1, float = false }) end, "Previous diagnostic")
        map("]d", function() vim.diagnostic.jump({ count = 1, float = false }) end, "Next diagnostic")
        map("<leader>de", vim.diagnostic.open_float, "Show diagnostic float")
      end,
    })
  end,
}
