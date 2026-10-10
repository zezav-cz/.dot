-- lazygit in a tab page of its own.
-- No plugin: lazygit is a binary (home.nix) and Neovim's terminal is enough.
-- lazygit.nvim was here before and only does floating windows; a tab shows up
-- in the tab bar by name, uses the whole screen, and stays open while you
-- `gt` away to look at something -- `<leader>gg` again jumps back to it.
--
-- `open(args, dir)` runs `lazygit <args>` with `dir` as the working directory;
-- lazygit finds the repository from there. When lazygit exits the tab closes
-- and the tab you came from is current again.
--
-- Commit signing, same rule as the `lg` shell function in ~/.zshrc: signing is
-- off globally (~/.config/git/core.gitconfig) so unattended agent sessions do
-- not block on a YubiKey touch, and it is forced back on per launch through
-- GIT_CONFIG_*, which git gives the same precedence as `git -c`. The variables
-- go in the job's own environment, so nothing leaks into this Neovim.
--
-- The decision itself is NOT duplicated here: ~/.local/bin/git-can-sign (the
-- my-scripts package) answers it for both callers, because that override
-- outranks even a repository's explicit `gpgsign = false` and would otherwise
-- produce Unverified commits under ~/dev/recombee, whose identity the signing
-- key carries no UID for.
local SIGN_VARS = {
  GIT_CONFIG_COUNT = "2",
  GIT_CONFIG_KEY_0 = "commit.gpgsign",
  GIT_CONFIG_VALUE_0 = "true",
  GIT_CONFIG_KEY_1 = "tag.gpgsign",
  GIT_CONFIG_VALUE_1 = "true",
}

local function signing_env(dir)
  if vim.fn.executable("git-can-sign") ~= 1 then
    return nil
  end
  vim.fn.system({ "git-can-sign", dir })
  return vim.v.shell_error == 0 and SIGN_VARS or nil
end

local M = {}

-- The one lazygit terminal buffer, if it is still running.
local running

local function focus_running()
  if not (running and vim.api.nvim_buf_is_valid(running)) then
    running = nil
    return false
  end
  for _, win in ipairs(vim.fn.win_findbuf(running)) do
    vim.api.nvim_set_current_win(win)
    vim.cmd("startinsert")
    return true
  end
  return false
end

-- Line numbers, the sign column and listchars are for code; the terminal
-- gets the bare window so lazygit has every column.
local function bare_window()
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.statuscolumn = ""
  vim.wo.list = false
end

---@param args string[] extra lazygit arguments
---@param dir string working directory for lazygit (and the signing check)
function M.open(args, dir)
  if focus_running() then
    return
  end
  local origin = vim.api.nvim_get_current_tabpage()
  local root = vim.fs.root(dir, ".git")
  vim.cmd("tabnew")
  vim.t.tabname = "lazygit: " .. vim.fs.basename(root or dir)
  bare_window()
  local buf = vim.api.nvim_get_current_buf()
  local job = vim.fn.jobstart(vim.list_extend({ "lazygit" }, args), {
    term = true,
    cwd = dir,
    env = signing_env(dir),
    on_exit = function()
      if running == buf then
        running = nil
      end
      if vim.api.nvim_tabpage_is_valid(origin) then
        vim.api.nvim_set_current_tabpage(origin)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
  })
  if job <= 0 then
    vim.cmd("tabclose")
    vim.notify("lazygit: could not start (is it installed?)", vim.log.levels.ERROR)
    return
  end
  running = buf
  -- Coming back to this tab (`<A-h>`, `2gt`, ...) lands in normal mode;
  -- lazygit is only useful in terminal mode, so re-enter it every time.
  vim.api.nvim_create_autocmd("BufEnter", { buffer = buf, command = "startinsert" })
  vim.cmd("startinsert")
end

-- Unnamed and scratch buffers have no path to derive a repo from.
local function buffer_dir()
  local path = vim.api.nvim_buf_get_name(0)
  return path ~= "" and vim.fn.fnamemodify(path, ":h") or vim.fn.getcwd()
end

function M.cwd()
  M.open({}, vim.fn.getcwd())
end

function M.current_file_repo()
  M.open({}, buffer_dir())
end

-- Log filtered to the commits touching this buffer (`lazygit -f`); lazygit
-- wants the path relative to the repository.
function M.current_file_log()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("lazygit: this buffer has no file", vim.log.levels.WARN)
    return
  end
  local dir = vim.fs.dirname(path)
  local root = vim.fs.root(dir, ".git")
  M.open({ "-f", root and vim.fs.relpath(root, path) or path }, dir)
end

return M
