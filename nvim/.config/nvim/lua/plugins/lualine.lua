local M = {}

function M.spec()
  return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  }
end

function M.setup()
  -- Function to get active TreeSitter parsers
  local function treesitter_status()
    local bufnr = vim.api.nvim_get_current_buf()
    local parsers = require('nvim-treesitter.parsers')

    if parsers.has_parser() then
      local lang = parsers.get_buf_lang(bufnr)
      return 'T:' .. lang
    else
      return 'T: ∅'
    end
  end

  -- Function to get active LSP servers
  local function lsp_status()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if next(clients) == nil then
      return 'L:∅'
    end

    local names = {}
    for _, client in ipairs(clients) do
      table.insert(names, client.name)
    end
    return 'L:' .. table.concat(names, ',')
  end

  -- Function to get indentation info
  local function indent_status()
    local expandtab = vim.bo.expandtab
    local size = vim.bo.shiftwidth
    local type = expandtab and 's' or 't'
    return 'I:' .. size .. type
  end

  -- Function to get file format (line endings)
  local function fileformat_status()
    local format = vim.bo.fileformat
    if format == 'unix' then
      return 'LF'
    elseif format == 'dos' then
      return 'CRLF'
    elseif format == 'mac' then
      return 'CR'
    else
      return format
    end
  end

  require('lualine').setup({
    options = {
      icons_enabled = true,
      theme = 'gruvbox',
      component_separators = { left = '', right = ''},
      section_separators = { left = '', right = ''},
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      ignore_focus = {},
      always_divide_middle = true,
      globalstatus = false,
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
      }
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff', 'diagnostics'},
      lualine_c = {'filename'},
      lualine_x = {treesitter_status, lsp_status, indent_status, 'encoding', fileformat_status, 'filetype'},
      lualine_y = {'progress'},
      lualine_z = {'location'}
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {'filename'},
      lualine_x = {'location'},
      lualine_y = {},
      lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {}
  })
end

return M
