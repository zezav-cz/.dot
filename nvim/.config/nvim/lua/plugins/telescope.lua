local M = {}

local keys = {
  { "<leader>fs", "<cmd>Telescope frecency workspace=CWD<cr>", desc = "Find files (Smart)" },
  { "<leader>fp", "<cmd>Telescope git_files<cr>",              desc = "Git files" },
  { "<leader>fz", "<cmd>Telescope live_grep<cr>",              desc = "Live grep" },
  { "<leader>fo", "<cmd>Telescope oldfiles<cr>",               desc = "Old files" },
  { "<leader>fb", "<cmd>Telescope buffers<cr>",                desc = "Buffers" },
  { "<leader>fh", "<cmd>Telescope help_tags<cr>",              desc = "Help tags" },
}

function M.spec()
  return {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.1.9',
    keys = keys,
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      'nvim-telescope/telescope-frecency.nvim',
    }
  }
end

function M.setup()
  local telescope = require('telescope')
  local actions = require('telescope.actions')

  telescope.setup({
    defaults = {
      -- Enable preview by default
      preview = {
        enable = true,
        treesitter = true,
      },
      -- Layout configuration with preview
      layout_strategy = 'horizontal',
      layout_config = {
        horizontal = {
          preview_width = 0.55,
          results_width = 0.8,
        },
        vertical = {
          mirror = false,
        },
        width = 0.87,
        height = 0.80,
        preview_cutoff = 120,
      },
      -- File ignore patterns
      file_ignore_patterns = {
        "node_modules",
        ".git/",
        "%.lock",
      },
      -- Search in hidden files but not in .git
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--hidden',
        '--glob=!.git/',
      },
      -- Mappings
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
      find_files = {
        hidden = true,
        -- Follow symbolic links
        follow = true,
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
      buffers = {
        show_all_buffers = true,
        sort_lastused = true,
        mappings = {
          i = {
            ["<c-d>"] = actions.delete_buffer,
          },
        },
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
      frecency = {
        db_safe_mode = false,
        auto_validate = true,
        show_scores = true, -- Optional: hides the frecency score
        show_unindexed = true,
        ignore_patterns = { "*.git/*" },
        workspaces = {
          ["vnotes"] = "/home/jan/vnotes", -- Use absolute path here
        }
      },
    },
  })

  -- Load fzf extension for better performance
  pcall(telescope.load_extension, 'fzf')
  pcall(telescope.load_extension, 'frecency')
end

return M
