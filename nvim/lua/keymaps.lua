-- Set leader key to space
vim.g.mapleader = " "

-- buffers
vim.keymap.set("n", "<leader>n", ":bn<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>p", ":bp<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>x", ":bd<cr>", { desc = "Close buffer" })
vim.keymap.set("n", "<leader>ml", ":b#<cr>", { desc = "Toggle last buffer" })

-- yanking
vim.keymap.set("x", "p", [["_dP]], { desc = "Paste without overwriting clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Center the screen after scrolling up/down with Ctrl-u/d
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })

-- Center the screen on the next/prev search result with n/N
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result and center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- search and replace the word under cursor in the file with <leader>s
vim.keymap.set("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = "Search and replace word under cursor in file" })

vim.keymap.set("n", "<leader>f", function()
        require('conform').format({ async = true, lsp_fallback = "fallback"})
    end,
    { desc = "Format file with conform.nvim" })

vim.keymap.set("n", "<leader>ff", ":Ex<cr>", { desc = "Open file browser" })
