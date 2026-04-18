local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf    = require("telescope.config").values
local actions = require("telescope.actions")
local state   = require("telescope.actions.state")

return function(opts)
  opts = opts or {}

  local tabs = {}
  for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
    local winnr  = vim.api.nvim_tabpage_get_win(tabnr)
    local bufnr  = vim.api.nvim_win_get_buf(winnr)
    local name   = vim.api.nvim_buf_get_name(bufnr)
    local tabidx = vim.api.nvim_tabpage_get_number(tabnr)
    table.insert(tabs, {
      tabnr  = tabnr,
      tabidx = tabidx,
      name   = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]",
    })
  end

  pickers.new(opts, {
    prompt_title = "Tabs",
    finder = finders.new_table({
      results = tabs,
      entry_maker = function(tab)
        return {
          value   = tab,
          display = tab.tabidx .. ": " .. tab.name,
          ordinal = tab.name,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(buf)
      actions.select_default:replace(function()
        local sel = state.get_selected_entry()
        actions.close(buf)
        vim.api.nvim_set_current_tabpage(sel.value.tabnr)
      end)
      return true
    end,
  }):find()
end
