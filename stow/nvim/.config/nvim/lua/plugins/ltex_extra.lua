-- Companion for ltex-ls (see lsp/ltex.lua): persists dictionary additions and
-- disabled-rule choices made via LSP code actions to disk between sessions.
-- Loaded on demand when the ltex client attaches in aggressive spell mode.
return {
  "barreiroleo/ltex_extra.nvim",
  lazy = true,
}
