-- Spell checking in two levels, both toggled per buffer.
--
--   <leader>ss  simple      Neovim's built-in spell checker (en + cs). In code
--                           files treesitter limits it to comments and strings,
--                           so identifiers are never flagged. Auto-on for prose.
--   <leader>sa  aggressive  Simple, plus ltex-ls (LanguageTool) for grammar and
--                           style. Heavy (JVM), so it never starts on its own.
--
-- Words added with `zg` land in spell/{en,cs}.utf-8.add inside this config
-- directory — which is a stow symlink into the dotfiles repo, so commit them to
-- carry your dictionary to another machine.

local SPELLLANG = "en,cs"
local PROSE_FILETYPES = { "markdown", "text", "gitcommit", "tex", "pandoc" }

vim.opt.spellsuggest = "best,9" -- cap the z= list, keep it fast

local function set_spell(on)
  vim.opt_local.spell = on
  if on then
    vim.opt_local.spelllang = SPELLLANG
  end
end

local function ltex_clients(bufnr)
  return vim.lsp.get_clients({ bufnr = bufnr, name = "ltex" })
end

-- `vim.lsp.enable()` is deliberately not used for ltex (see the automatic_enable
-- exclusion in plugins/mason_lspconfig.lua), so starting it by hand means
-- resolving root_dir from root_markers ourselves — that is the part enable()
-- would normally do.
local function start_ltex(bufnr)
  local config = vim.lsp.config.ltex
  if not config then
    vim.notify("ltex-ls is not configured (lsp/ltex.lua missing?)", vim.log.levels.ERROR)
    return false
  end
  config.name = config.name or "ltex"
  config.root_dir = vim.fs.root(bufnr, config.root_markers or { ".git" }) or vim.fn.getcwd()
  return vim.lsp.start(config, { bufnr = bufnr }) ~= nil
end

local function stop_ltex(bufnr)
  for _, client in ipairs(ltex_clients(bufnr)) do
    vim.lsp.buf_detach_client(bufnr, client.id)
    -- Another buffer may still be in aggressive mode; only shut the JVM down
    -- once nothing is using it.
    if vim.tbl_isempty(client.attached_buffers or {}) then
      client:stop()
    end
  end
end

local function toggle_simple()
  local on = not vim.wo.spell
  set_spell(on)
  vim.notify("spell: " .. (on and "on (en+cs)" or "off"), vim.log.levels.INFO)
end

local function toggle_aggressive()
  local bufnr = vim.api.nvim_get_current_buf()
  if #ltex_clients(bufnr) > 0 then
    stop_ltex(bufnr)
    set_spell(false)
    vim.notify("spell: aggressive off", vim.log.levels.INFO)
  else
    set_spell(true)
    if start_ltex(bufnr) then
      vim.notify("spell: aggressive on — ltex-ls starting, grammar takes a moment", vim.log.levels.INFO)
    end
  end
end

vim.keymap.set("n", "<leader>ss", toggle_simple, { desc = "Spell: simple (native, en+cs)" })
vim.keymap.set("n", "<leader>sa", toggle_aggressive, { desc = "Spell: aggressive (+ ltex grammar)" })

-- Prose filetypes get the simple checker without asking; aggressive never does.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("spell-prose", { clear = true }),
  pattern = PROSE_FILETYPES,
  callback = function()
    set_spell(true)
  end,
})
