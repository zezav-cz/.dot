-- Fuzzy finder interface (telescope.nvim)
-- A highly extensible popup list interface for rapidly finding finding files,
-- searching text (live grep), switching buffers, and exploring vim commands.
return {
  'nvim-telescope/telescope.nvim',
  tag = 'v0.1.9',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    'nvim-telescope/telescope-frecency.nvim',
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope frecency workspace=CWD<cr>", desc = "Find files (frecency)" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>",                desc = "Search buffers" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>",              desc = "Live grep" },
    { "<leader>ft", function() require("telescope_tabs")() end, desc = "Search tabs" },
  },
  config = function()
    local telescope = require('telescope')
    local actions   = require('telescope.actions')

    telescope.setup({
      defaults = {
        preview = { enable = true, treesitter = true },
        layout_strategy = 'horizontal',
        layout_config = {
          horizontal = { preview_width = 0.55, results_width = 0.8 },
          vertical   = { mirror = false },
          width          = 0.87,
          height         = 0.80,
          preview_cutoff = 120,
        },
        file_ignore_patterns = {
          -- version control
          "%.git/",
          -- Obsidian / Syncthing
          "%.obsidian/",
          "%.obsidian%-mobile/",
          "%.stfolder",
          "%.trash/",
          -- build / deps
          "node_modules/",
          "%.bundle/",
          "/vendor/",
          "__pycache__/",
          "%.venv/",
          "/venv/",
          "/dist/",
          "/build/",
          "/target/",
          "%.next/",
          "%.nuxt/",
          -- lockfiles & minified
          "%.lock$",
          "%-lock%.json$",
          "%.min%.js$",
          "%.min%.css$",
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
          show_all_buffers = true,
          sort_lastused    = true,
          mappings         = { i = { ["<c-d>"] = actions.delete_buffer } },
        },
      },
      extensions = {
        fzf = {
          fuzzy                   = true,
          override_generic_sorter = true,
          override_file_sorter    = true,
          case_mode               = "smart_case",
        },
        frecency = {
          db_safe_mode   = false,
          auto_validate  = true,
          show_scores    = true,
          show_unindexed = true,
          ignore_patterns = {
            -- version control
            "*/.git/*",
            -- Obsidian / Syncthing
            "*/.obsidian/*",
            "*/.obsidian-mobile/*",
            "*/.stfolder*",
            "*/.trash/*",
            -- build / deps
            "*/node_modules/*",
            "*/.bundle/*",
            "*/vendor/*",
            "*/__pycache__/*",
            "*/.venv/*",
            "*/venv/*",
            "*/dist/*",
            "*/build/*",
            "*/target/*",
            "*/.next/*",
            "*/.nuxt/*",
            -- lockfiles & minified
            "*.lock",
            "*-lock.json",
            "*.min.js",
            "*.min.css",
          },
        },
      },
    })

    pcall(telescope.load_extension, 'fzf')
    pcall(telescope.load_extension, 'frecency')
  end,
}
