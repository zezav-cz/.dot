-- Statusline (lualine.nvim)
-- Mostly defaults; the one custom piece is the LSP indicator, which is the
-- quickest answer to "is a language server actually attached to this buffer?"
return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local function lsp_status()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if next(clients) == nil then
        return 'L:∅'
      end
      local names = vim.tbl_map(function(client) return client.name end, clients)
      return 'L:' .. table.concat(names, ',')
    end

    require('lualine').setup({
      options = {
        theme                = 'gruvbox',
        component_separators = { left = '', right = '' },
        section_separators   = { left = '', right = '' },
        globalstatus         = true,
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { lsp_status, 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    })
  end,
}
