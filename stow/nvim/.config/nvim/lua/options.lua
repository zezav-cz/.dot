vim.opt.nu = true -- enable line numbers
vim.opt.relativenumber = true -- relative line numbers
vim.o.signcolumn = "yes"
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true

-- Give the focused split more room, shrink inactive ones
vim.o.winwidth = 10
vim.o.winminwidth = 10

-- Quiet diagnostics: the message is spelled out only on the line the cursor is
-- on; everywhere else a sign in the gutter is enough. <leader>de for the full
-- text, K for hover. Swap `virtual_text` for `virtual_lines = { current_line =
-- true }` if you'd rather have long messages wrapped below the line.
vim.diagnostic.config({
  virtual_text = { current_line = true, prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false, -- don't re-lint on every keystroke while typing
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
})

-- Set cwd based on launch argument:
--   nvim ~/ops/vnotes      → cd ~/ops/vnotes
--   nvim ~/ops/vnotes/f.md → cd ~/ops/vnotes
--   nvim                   → stay in pwd (empty buffer, nothing is restored)
local arg = vim.fn.argv(0)
if arg and arg ~= "" then
  local stat = vim.uv.fs_stat(vim.fn.expand(arg))
  if stat then
    local dir = stat.type == "directory"
      and vim.fn.expand(arg)
      or vim.fn.fnamemodify(vim.fn.expand(arg), ":h")
    vim.cmd("cd " .. vim.fn.fnameescape(dir))
  end
end

-- Show only the whitespace that is usually a mistake — a dot behind every
-- single space is noise.
vim.opt.list = true
vim.opt.listchars = {
  tab = '→ ',
  trail = '·',
  nbsp = '␣',
}
