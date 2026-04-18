-- Code formatting plugin (conform.nvim)
-- Automatically formats code (e.g., on save) using external tools
-- like prettier, stylua, clang-format, and black across different languages.
return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        lua        = { "stylua" },
        python     = { "isort", "black" },
        go         = { "goimports", "gofmt" },
        ruby       = { "rubocop" },
        puppet     = { "puppet-lint" },
        typescript = { "prettier" },
        javascript = { "prettier" },
        typescriptreact = { "prettier" },
        javascriptreact = { "prettier" },
        json       = { "prettier" },
        yaml       = { "prettier" },
        c          = { "clang-format" },
        cpp        = { "clang-format" },
      },
      -- format_on_save = {
      --   timeout_ms = 2000,
      --   lsp_format = "fallback",
      -- },
    })
  end,
}
