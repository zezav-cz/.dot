-- Completion engine (menu shows automatically while typing).
-- keymap preset "default": <C-space> show/docs, <C-n>/<C-p> select, <C-y> accept,
-- <C-e> hide, <C-b>/<C-f> scroll docs -- see README for the full table.
-- Chosen over "super-tab" so <CR>/<Tab> keep their normal meaning while writing prose.
return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "ribru17/blink-cmp-spell" },
  opts = {
    keymap = { preset = "default" },
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "spell" },
      providers = {
        spell = {
          name = "Spell",
          module = "blink-cmp-spell",
          opts = {
            max_entries = 5,
            -- Only offer spelling completions where 'spell' is on (toggled by
            -- <leader>ss / <leader>sa, see lua/spell.lua) so code stays untouched.
            enable_in_context = function()
              return vim.wo.spell
            end,
          },
        },
      },
    },
  },
}
