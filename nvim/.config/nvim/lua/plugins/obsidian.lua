local M = {}

local keys = {
    {
        "<leader>ot",
        "<cmd>Obsidian template<cr>",
        desc = "Insert Obsidian template",
    },
    {
        "<leader>ol",
        "<cmd>Obsidian link<cr>",
        desc = "Link to Obsidian note",
        mode = "v",
    },
    {
        "<leader>ol",
        "viw:Obsidian link<cr>",
        desc = "Link word to Obsidian note",
        mode = "n",
    },
}

function M.spec()
    return {
        "obsidian-nvim/obsidian.nvim",
        version = "*", -- recommended, use latest release instead of latest commit
        ft = "markdown",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = keys,
        config = function()
            M.setup()
        end,
    }
end

function M.setup()
    vim.opt_local.conceallevel = 2

    require("obsidian").setup({
        workspaces = {
            {
                name = "vnotes",
                path = vim.fn.expand("~/vnotes/"),
            },
        },
        templates = {
            folder = "99_templates",
            date_format = "%Y-%m-%d",
            time_format = "%H:%M",
        },
        frontmatter = {
            enabled = false,
        },
        legacy_commands = false,
    })
end

return M
