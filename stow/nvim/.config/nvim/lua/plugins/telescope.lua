-- Fuzzy finder (telescope.nvim)
-- Files, recent files, buffers, live grep. Ignore patterns are kept short on
-- purpose — ripgrep already honours .gitignore for everything else.
return {
  'nvim-telescope/telescope.nvim',
  tag = 'v0.1.9',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>",   desc = "Recent files" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Search buffers" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live grep" },
  },
  config = function()
    local telescope = require('telescope')
    local actions   = require('telescope.actions')

    telescope.setup({
      defaults = {
        layout_strategy = 'horizontal',
        layout_config = {
          horizontal = { preview_width = 0.55 },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        file_ignore_patterns = {
          "%.git/",
          "node_modules/",
          "/vendor/",
          "__pycache__/",
          "%.venv/",
          "/dist/",
          "/build/",
          "%-lock%.json$",
        },
        vimgrep_arguments = {
          'rg', '--color=never', '--no-heading', '--with-filename',
          '--line-number', '--column', '--smart-case', '--hidden', '--glob=!.git/',
        },
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<esc>"] = actions.close,
          },
          n = {
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
      pickers = {
        find_files = { hidden = true, follow = true },
        live_grep  = { additional_args = function() return { "--hidden" } end },
        buffers    = {
          sort_lastused = true,
          mappings      = { i = { ["<c-d>"] = actions.delete_buffer } },
        },
      },
      extensions = {
        fzf = {
          fuzzy                   = true,
          override_generic_sorter = true,
          override_file_sorter    = true,
          case_mode               = "smart_case",
        },
      },
    })

    pcall(telescope.load_extension, 'fzf')
  end,
}
