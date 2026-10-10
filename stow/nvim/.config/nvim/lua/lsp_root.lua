-- Keep every LSP root inside the git checkout the buffer lives in.
--
-- Since Neovim 0.11.3 a flat `root_markers` list is a PRIORITY list, not a set.
-- nvim-lspconfig's basedpyright entry, `{ 'pyrightconfig.json', 'pyproject.toml',
-- ..., '.git' }`, therefore means "the nearest ancestor with a pyrightconfig.json
-- anywhere up the tree, and only if there is none, the nearest with the next
-- marker". Fine in a plain checkout, wrong in a git worktree that lives under
-- the main one (`repo/.claude/worktrees/<name>/`, what Claude Code creates): a
-- gitignored marker that exists only in the main checkout -- pyrightconfig.json,
-- .venv, compile_commands.json, .luarc.json -- sits in an ancestor of the
-- worktree, outranks the worktree's own `.git`, and the server gets rooted in
-- the main checkout. basedpyright then loads the main pyrightconfig.json, its
-- extraPaths point at the main `modules/`, and every `gd` from the worktree
-- lands in the main branch's copy of the file. Reproduced in
-- ~/dev/isee/agents/repo/beyond: root_dir came out as the main checkout even
-- with the buffer three levels inside `.claude/worktrees/mtls-cli/`.
--
-- The fix keeps the server's own markers and their priority order, but stops
-- the walk at the enclosing `.git` -- a directory in a normal checkout, a file
-- in a worktree; vim.fs.find matches both. Servers that ship their own
-- root_dir function (gopls, ts_ls) are left alone.
local M = {}

--- Same semantics as vim.fs.root(): each entry is one priority level, a nested
--- list is one level whose members have equal priority. Unlike vim.fs.root()
--- the search never climbs above `top`; when no marker is found, `top` is the
--- root.
local function root_below(path, markers, top)
  local dir = vim.fs.dirname(path)
  local stop = vim.fs.dirname(top)
  for _, level in ipairs(markers) do
    local hit = vim.fs.find(level, { path = dir, upward = true, stop = stop, limit = 1 })[1]
    if hit then
      return vim.fs.dirname(hit)
    end
  end
  return top
end

--- Replace the resolved config's `root_markers` for `name` with a `root_dir`
--- function that evaluates those same markers but never above the nearest
--- `.git`. Must be called through vim.lsp.config(): a `root_dir` set in
--- lsp/<name>.lua would be overridden by nvim-lspconfig's file of the same
--- name, which comes later on the runtimepath and wins the merge.
function M.clamp(name)
  local cfg = vim.lsp.config[name]
  if not cfg or cfg.root_dir or not cfg.root_markers then
    return
  end
  local markers = cfg.root_markers
  if type(markers) ~= "table" then
    markers = { markers }
  end

  vim.lsp.config(name, {
    root_dir = function(bufnr, on_dir)
      local git = vim.fs.root(bufnr, ".git")
      if not git then
        on_dir(vim.fs.root(bufnr, markers))
        return
      end
      on_dir(root_below(vim.fs.abspath(vim.api.nvim_buf_get_name(bufnr)), markers, git))
    end,
  })
end

return M
