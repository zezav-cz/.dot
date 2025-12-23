local M = {}

function M.spec()
  return { "nvim-treesitter/nvim-treesitter", branch = 'master', lazy = false, build = ":TSUpdate" }
end

function M.setup()
  local ok, configs = pcall(require, 'nvim-treesitter.configs')
  if not ok then
    return
  end

  configs.setup {
    ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
    sync_install = false,
    auto_install = true,
    ignore_install = {},
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
  }
end

return M
