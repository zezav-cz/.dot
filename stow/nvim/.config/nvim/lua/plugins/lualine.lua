-- Statusline replacement (lualine.nvim)
-- Adds a customized status bar at the bottom of the editor showing the current
-- editor mode, file name, git branch, active LSP servers, and file encoding.
return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local function treesitter_status()
      local parsers = require('nvim-treesitter.parsers')
      if parsers.has_parser() then
        return 'T:' .. parsers.get_buf_lang(vim.api.nvim_get_current_buf())
      end
      return 'T:∅'
    end

    local function lsp_status()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if next(clients) == nil then return 'L:∅' end
      local names = {}
      local spell_tools = {}

      for _, client in ipairs(clients) do 
        if client.name == 'codebook' then
          table.insert(spell_tools, 'Codebook')
        elseif client.name == 'ltex' then
          table.insert(spell_tools, 'LT(CZ/EN)')
        else
          table.insert(names, client.name)
        end
      end
      
      local status = 'L:' .. table.concat(names, ',')
      if #spell_tools > 0 then
        status = status .. ' | ' .. table.concat(spell_tools, '+')
      end
      return status
    end

    local function indent_status()
      return 'I:' .. vim.bo.shiftwidth .. (vim.bo.expandtab and 's' or 't')
    end

    local function fileformat_status()
      local map = { unix = 'LF', dos = 'CRLF', mac = 'CR' }
      return map[vim.bo.fileformat] or vim.bo.fileformat
    end

    require('lualine').setup({
      options = {
        icons_enabled        = true,
        theme                = 'gruvbox',
        component_separators = { left = '', right = '' },
        section_separators   = { left = '', right = '' },
        always_divide_middle = true,
        globalstatus         = false,
        refresh              = { statusline = 1000, tabline = 1000, winbar = 1000 },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { treesitter_status, lsp_status, indent_status, 'encoding', fileformat_status, 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
      inactive_sections = {
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
      },
    })
  end,
}
