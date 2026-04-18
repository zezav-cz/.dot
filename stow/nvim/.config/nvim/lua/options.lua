vim.opt.nu = true -- enable line numbers
vim.opt.relativenumber = true -- relative line numbers
vim.o.signcolumn = "yes"
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
-- vim.o.background = "dark"
vim.opt.termguicolors = true
-- vim.cmd([[colorscheme gruvbox]])

vim.diagnostic.config({
  -- <<< THIS is the "on the right in the line" part
  virtual_text = {
    prefix = "●",     -- symbol shown before the message
    spacing = 2,      -- space between code and message
    -- you can also filter by severity if you want:
    -- severity = { min = vim.diagnostic.severity.WARN },
  },

  signs = true,        -- show icons in the sign column
  underline = true,    -- underline problematic code
  update_in_insert = true, -- don't spam while typing
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
})

-- Set cwd based on launch argument:
--   nvim ~/vnotes      → cd ~/vnotes
--   nvim ~/vnotes/f.md → cd ~/vnotes
--   nvim               → stay in pwd
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

-- Enable list mode (to show whitespace)
vim.opt.list = true

-- Configure how whitespace looks
-- space: · (middle dot)
-- tab:   → (arrow) followed by a space
vim.opt.listchars = {
    space = '·',
    tab = '→ ',
    trail = '·', -- Optional: show trailing spaces as dots as well
    nbsp = '␣',  -- Optional: non-breaking space
}

-- Auto spell check for markdown
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "tex" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en,cs"
  end,
})
