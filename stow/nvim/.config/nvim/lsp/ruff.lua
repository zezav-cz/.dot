---@type vim.lsp.Config
-- ruff and basedpyright are both attached to every Python buffer, so each
-- request has to have exactly one owner. ruff keeps what it is good at --
-- lint diagnostics and the `source.fixAll` / `source.organizeImports` code
-- actions -- and gives up hover, which it answers with a bare summary of the
-- symbol that would otherwise race basedpyright's real type information.
return {
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end,
}
