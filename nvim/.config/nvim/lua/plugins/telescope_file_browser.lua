local M = {}

local keys = {
  { "<space>fb", "<cmd>Telescope file_browser<cr>", desc = "File browser" },
}

function M.spec()
  return {
    "nvim-telescope/telescope-file-browser.nvim",
    keys = keys,
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  }
end

function M.setup()
end

return M
