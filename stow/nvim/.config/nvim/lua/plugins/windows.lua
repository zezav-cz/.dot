-- Window layout manager (windows.nvim)
-- Animates window resizing events and provides layout management commands,
-- such as automatically maximizing the active split window gracefully.
return {
  "anuvyklack/windows.nvim",
  dependencies = {
    "anuvyklack/middleclass",
    "anuvyklack/animation.nvim",
  },
  config = function()
    vim.o.winwidth    = 10
    vim.o.winminwidth = 10
    vim.o.equalalways = false
    require("windows").setup()
  end,
}
