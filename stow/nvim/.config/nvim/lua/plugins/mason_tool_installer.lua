-- Formatter installer (mason-tool-installer.nvim)
-- Keeps the external binaries conform.nvim shells out to present. Linters live
-- in the language servers themselves, so nothing here duplicates diagnostics.
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "mason-org/mason.nvim" },
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = {
        "stylua",
        "black",
        "isort",
        "goimports",
        "prettier",
        "clang-format",
      },
      auto_update = false,
      run_on_start = true,
    })
  end,
}
