-- Automated Tool Installer (mason-tool-installer.nvim)
-- Ensures essential LSPs, formatters, and linters specified in the config
-- are automatically downloaded and installed via Mason when Neovim starts.
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "mason-org/mason.nvim" },
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = {
        -- Formatters
        "stylua",
        "black",
        "isort",
        "goimports",
        "prettier",
        "clang-format",

        -- Linters
        "golangci-lint",
        "eslint_d",
        "mypy",
        "rubocop",
      },
      auto_update = false,
      run_on_start = true,
    })
  end,
}
