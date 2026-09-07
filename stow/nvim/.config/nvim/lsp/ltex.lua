---@type vim.lsp.Config
-- ltex-ls (LanguageTool): grammar and style checking for English prose.
--
-- This server is NOT enabled automatically (see the automatic_enable allow-list
-- in lua/plugins/mason_lspconfig.lua). It boots a JVM and is only started for
-- the current buffer by aggressive spell mode -- <leader>sa, in lua/spell.lua.
--
-- ENGLISH ONLY, and that is a limitation of the server, not a choice here.
-- Both mason builds -- ltex-ls 16.0.0 and ltex-ls-plus 18.7.0 -- answer any
-- Czech request with:
--
--   SEVERE: 'cs-CZ' is not a recognized language.
--           Leaving LanguageTool uninitialized, checking disabled.
--
-- Setting `language` or `additionalRules.motherTongue` to "cs-CZ" therefore does
-- not degrade to English -- it silently disables all checking, in every
-- language. Czech is covered by the built-in spell checker instead (<leader>ss,
-- spell/cs.utf-8.spl), which does spelling but not grammar. Real Czech grammar
-- would mean pointing `ltex.languageToolHttpServerUri` at a self-hosted
-- LanguageTool instance that has the Czech module.
return {
  cmd = { 'ltex-ls' },
  filetypes = { 'markdown', 'tex', 'gitcommit', 'text', 'pandoc' },
  root_markers = { '.git', 'ltex.json' },
  -- Java 17+'s default XML entity-size limit is too small for LanguageTool's
  -- bundled grammar.xml, so ltex-ls otherwise crashes on startup every time.
  cmd_env = { JAVA_OPTS = "-Djdk.xml.totalEntitySizeLimit=0" },
  settings = {
    ltex = {
      language = "en-US",
      additionalRules = {
        enablePickyRules = true,
      },
    },
  },
  -- ltex-ls doesn't persist "Add to dictionary" / "Disable rule" code actions on
  -- its own; it expects the client to store and re-send them. ltex_extra.nvim
  -- implements that handshake.
  on_attach = function(_, _)
    require("ltex_extra").setup({
      load_langs = { "en-US" },
      path = vim.fn.stdpath("config") .. "/ltex-dictionary",
      log_level = "none",
    })
  end,
}
