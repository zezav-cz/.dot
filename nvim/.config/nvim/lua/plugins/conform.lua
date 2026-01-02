local M = {}

function M.spec()
  return { "stevearc/conform.nvim", dependencies = { "mason.nvim" }, lazy = true }
end

function M.setup()
  local ok, conform = pcall(require, "conform")
  if not ok then
    return
  end
  conform.setup({
    formatters_by_ft = {
      lua = { "stylua" },
      -- Conform will run multiple formatters sequentially
      python = { "isort", "black" },
      -- You can customize some of the format options for the filetype (:help conform.format)
      rust = { "rustfmt", lsp_format = "fallback" },
      -- Conform will run the first available formatter
      javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  })
end

return M
