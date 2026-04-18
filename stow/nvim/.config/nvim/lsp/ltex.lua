---@type vim.lsp.Config
return {
  cmd = { 'ltex-ls' },
  filetypes = { 'markdown', 'tex', 'gitcommit', 'pandoc' },
  root_markers = { '.git', 'ltex.json' },
  settings = {
    ltex = {
      language = "auto",
      additionalRules = {
        enablePickyRules = true,
        motherTongue = "cs-CZ",
      },
    },
  },
}
