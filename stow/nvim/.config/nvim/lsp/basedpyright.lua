---@type vim.lsp.Config
-- The actual Python language server: goto-definition, hover, completion,
-- references, types. `ruff` alone cannot answer any of those -- it is a linter
-- that happens to speak LSP -- so a Python buffer without this one replies
-- `method "textDocument/definition" is not supported by any server`.
--
-- basedpyright rather than pyright: same engine, but the parts pyright keeps
-- closed (inlay hints, call hierarchy, semantic tokens) are open here, and it
-- ships as a single mason package with no Node dependency of its own.

-- Only basedpyright's *errors* reach the buffer. Everything softer is dropped
-- before it becomes a squiggle.
--
-- basedpyright's default type-checking mode is `recommended`, which is far
-- stricter than pyright's `standard`: it adds reportAny, reportUnknownMemberType,
-- reportUnknownVariableType, reportImplicitStringConcatenation and friends. On a
-- real untyped-ish codebase that is not a handful of warnings, it is a carpet --
-- measured on one 650-line file in ~/dev/isee/.../beyond: 121 diagnostics across
-- 84 lines at `recommended` versus 20 at `standard`. Underlined end to end, the
-- file stops being readable.
--
-- The obvious fix -- asking for `standard` in `settings` below -- does not work
-- in that repo, and this is the part worth remembering: it ships a
-- `pyrightconfig.json`, and when pyright finds one it takes precedence over the
-- language server settings the editor sends. The client's typeCheckingMode is
-- simply ignored, and since that file does not name a mode either, the server
-- falls back to its own default of `recommended`. No amount of configuring
-- Neovim changes it.
--
-- So the filtering happens on this side of the wire, where no project file can
-- override it, and it is done by severity rather than by rule: a real type
-- error still shows up, the style opinions never do. Lint is ruff's job anyway
-- (see lsp/ruff.lua), so nothing is lost -- the two servers now own strictly
-- different halves of the buffer's feedback.
--
-- Both handlers are needed. A server may push diagnostics at the client
-- (`textDocument/publishDiagnostics`) or the client may pull them
-- (`textDocument/diagnostic`, which Neovim 0.11+ prefers whenever the server
-- advertises `diagnosticProvider`, as basedpyright does). Filtering only the
-- push path silently does nothing.
local function errors_only(diagnostics)
  return vim.tbl_filter(function(d)
    return d.severity == vim.lsp.protocol.DiagnosticSeverity.Error
  end, diagnostics or {})
end

return {
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result then
        result.diagnostics = errors_only(result.diagnostics)
      end
      return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
    end,

    ["textDocument/diagnostic"] = function(err, result, ctx, config)
      if result then
        result.items = errors_only(result.items)
      end
      return vim.lsp.handlers["textDocument/diagnostic"](err, result, ctx, config)
    end,
  },

  settings = {
    basedpyright = {
      -- Import order is ruff's job (see lsp/ruff.lua). Leaving it on here means
      -- two servers offering the same code action with different results.
      disableOrganizeImports = true,

      analysis = {
        -- Honoured only in projects *without* a pyrightconfig.json; where one
        -- exists it wins, which is what the filtering above is for. Worth
        -- setting anyway: it makes every other repo quieter at the source
        -- rather than after the fact.
        typeCheckingMode = 'standard',

        useLibraryCodeForTypes = true,
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly', -- 'workspace' re-checks every file on
                                          -- every keystroke; too slow on a big repo
      },
    },
  },
}
