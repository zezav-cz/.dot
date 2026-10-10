-- In-buffer Markdown preview: renders headings, code blocks, tables, lists,
-- callouts and links as decorations over the real text, so the buffer stays
-- editable instead of opening a browser. Toggle with `:RenderMarkdown toggle`.
--
-- Driven by the `markdown` and `markdown_inline` parsers, both of which are
-- in ENSURE_INSTALLED in nvim_treesitter.lua.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    -- Render everything except the line under the cursor, which stays raw
    -- so it can be edited without the decorations shifting around.
    render_modes = { "n", "c", "t" },
    anti_conceal = { enabled = true },
    heading = { sign = false, position = "inline" },
    code = { sign = false, width = "block", left_pad = 2, right_pad = 2 },
    checkbox = { enabled = true },
  },
}
