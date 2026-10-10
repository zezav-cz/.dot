-- Indent guides (indent-blankline.nvim, `ibl`).
--
-- The companion to folding: folding hides a block, this one shows you where a
-- block begins and ends while it is still open. A thin vertical line per
-- indent level, and -- the part that actually answers "what belongs to what?"
-- -- the level the cursor is currently inside is drawn in a different colour
-- all the way from its opening line to its closing one.
--
-- `scope` is treesitter-driven, the same source the fold boundaries come from,
-- so the highlighted span and the fold you would get from `za` are the same
-- region. Indentation-based guides drift apart from that on a multi-line call
-- signature or a hanging closing bracket; this does not.
return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local hl = "IblScopeAccent"

    -- Tie the scope colour to the colorscheme instead of hardcoding a hex.
    -- gruvbox's orange reads on both its light and dark palettes, and
    -- re-running on ColorScheme keeps it right when `background` flips.
    local function set_hl()
      vim.api.nvim_set_hl(0, hl, { link = "GruvboxOrange" })
    end
    set_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("ibl_scope_hl", { clear = true }),
      callback = set_hl,
    })

    require("ibl").setup({
      indent = {
        char = "▏", -- a thin left-edge bar, not a full-height `│`
        tab_char = "▏",
      },
      -- The inactive levels stay quiet: without this every level is as loud as
      -- the one you are in and the accent stops meaning anything.
      whitespace = { remove_blankline_trail = false },
      scope = {
        enabled = true,
        highlight = hl,
        show_start = true, -- underline the line that opens the scope
        show_end = true,   -- and the one that closes it
        injected_languages = true, -- a fenced code block in markdown scopes too
      },
      exclude = {
        filetypes = {
          "help",
          "lazy",
          "mason",
          "NvimTree",
          "Trouble",
          "checkhealth",
          "man",
          "gitcommit",
          "markdown", -- prose indentation is not structure
          "text",
        },
      },
    })
  end,
}
