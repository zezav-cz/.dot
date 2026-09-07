---@type vim.lsp.Config
-- Without this, lua_ls flags `vim` as an undefined global on nearly every line
-- of this config and cannot see the Neovim runtime for completion.
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.stylua.toml', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.stdpath('config') .. '/lua',
        },
      },
      telemetry = { enable = false },
    },
  },
}
