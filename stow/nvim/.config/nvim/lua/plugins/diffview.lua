-- Side-by-side diffs and file history (diffview.nvim).
-- `<leader>g` is the git prefix; lazygit.lua and fugitive.lua share it.
--
-- `<leader>gd` is the everyday one: every file the working tree changed, in a
-- file panel on the left and a two-pane diff on the right. `<leader>gm` is the
-- pull-request view: everything this branch changed since it forked from the
-- default branch, committed or not; `<leader>gM` is the same against a branch
-- picked from a list. `<leader>gh` walks the history of one file
-- (or, in visual mode, of the selected lines), `<leader>gH` the whole branch.

-- The branch the repository merges into: origin/HEAD when the clone recorded
-- it (`git remote set-head origin -a` fixes a clone that did not), otherwise
-- the first of main/master that exists locally.
local function default_branch()
  local head = vim.fn.systemlist({ "git", "symbolic-ref", "-q", "--short", "refs/remotes/origin/HEAD" })
  if vim.v.shell_error == 0 and head[1] then
    return head[1]
  end
  for _, name in ipairs({ "main", "master" }) do
    vim.fn.system({ "git", "rev-parse", "-q", "--verify", name })
    if vim.v.shell_error == 0 then
      return name
    end
  end
end

-- Working tree against the merge-base with `branch`, so uncommitted work and
-- untracked files show up too. (`DiffviewOpen main...HEAD` would compare
-- commits only, and `--imply-local` only swaps the right side's contents; a
-- file that exists in no commit yet stays invisible.)
local function merge_base(branch)
  local base = vim.fn.systemlist({ "git", "merge-base", branch, "HEAD" })[1]
  if vim.v.shell_error ~= 0 or not base then
    vim.notify("diffview: no merge-base with " .. branch, vim.log.levels.WARN)
    return nil
  end
  return base
end

local function diff_against(branch)
  local base = merge_base(branch)
  if base then
    vim.cmd("DiffviewOpen " .. base)
  end
end

local function with_default_branch(fn)
  return function()
    local branch = default_branch()
    if not branch then
      vim.notify("diffview: no main/master branch found", vim.log.levels.WARN)
      return
    end
    fn(branch)
  end
end

local diff_against_default_branch = with_default_branch(diff_against)

-- The same branch, one commit at a time: a history view limited to the
-- commits since the merge-base, newest first. `<Tab>` walks through every file
-- of every commit in order; `<CR>` on a commit jumps straight to it.
local branch_commits = with_default_branch(function(branch)
  local base = merge_base(branch)
  if base then
    vim.cmd("DiffviewFileHistory --range=" .. base .. "..HEAD")
  end
end)

-- Same diff, but the base is picked from a Telescope list of local and remote
-- branches (`develop`, a colleague's feature branch, ...). Enter takes the
-- one under the cursor; the default action, checking the branch out, is
-- deliberately not reachable from here.
local function pick_branch_and_diff()
  require("telescope.builtin").git_branches({
    prompt_title = "Diff branch against",
    attach_mappings = function(prompt_bufnr, _)
      local actions = require("telescope.actions")
      local state = require("telescope.actions.state")
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          diff_against(entry.value)
        end
      end)
      return true
    end,
  })
end

-- Unchanged lines in a diff pane are folded away, keeping `diffopt`'s
-- `context:` lines (default 6) around each change. `zo` opens one fold
-- entirely and `zi` disables folding; this is the in-between -- widen or
-- narrow the context by a few lines for every fold at once. The option is
-- global, so the new width sticks for later diffs too.
local CONTEXT_STEP = 5

local function adjust_context(delta)
  return function()
    local current = tonumber(vim.o.diffopt:match("context:(%d+)")) or 6
    local new = math.max(0, current + delta)
    vim.o.diffopt = vim.o.diffopt:gsub(",?context:%d+", "") .. ",context:" .. new
    vim.cmd("diffupdate")
    vim.notify("diff context: " .. new .. " lines")
  end
end

-- The file panel's status column, redrawn in the alphabet the rest of this
-- setup already speaks (gitsigns' gutter, nvim-tree's git column, delta in
-- lazygit): `+` added, `~` modified, `_` deleted, `>` renamed. Untracked `?`
-- and unmerged `U` are the same in both and stay. diffview hardcodes the
-- letters in its renderer, so this paints over them with overlay extmarks --
-- the letter keeps its highlight group, and the marks are redone every time
-- the panel re-renders, which is what the buffer attachment is for.
local STATUS_GLYPH = { A = "+", M = "~", D = "_", R = ">" }
local glyph_ns = vim.api.nvim_create_namespace("diffview_status_glyphs")

local function restyle_status(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, glyph_ns, 0, -1)
  local git_hl = require("diffview.hl").get_git_hl
  for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    -- The status is the first non-blank character and is always followed by a
    -- space; headers ("Changes (3)") and paths fail one of the two tests.
    local col, letter = line:match("^(%s*)([AMDR]) ")
    if letter then
      vim.api.nvim_buf_set_extmark(buf, glyph_ns, row - 1, #col, {
        virt_text = { { STATUS_GLYPH[letter], git_hl(letter) } },
        virt_text_pos = "overlay",
      })
    end
  end
end

local function attach_status_glyphs(buf)
  restyle_status(buf)
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      vim.schedule(function()
        restyle_status(buf)
      end)
    end,
  })
end

-- The diff panes are marked the way gitsigns marks a buffer: a glyph in the
-- sign column next to each changed line -- `+` a line only this side has, `~`
-- a line that differs, and on the old (left) side `-` for a line the new side
-- no longer has -- backed by a line tint: green
-- for added, red for removed, blue for changed. gruvbox's own diff groups
-- are solid blocks with a dark foreground, which wipe out syntax colours and
-- read badly across a whole rewritten comment; these are only a background
-- (see `diff_tint`), so the syntax highlight shows through. DiffText, the
-- changed characters *within* a `~` line, gets a slightly stronger blue so
-- it still stands out from the rest of the line.
--
-- Vim has no diff signs of its own; `diff_hlID()` tells which diff group a
-- line would be painted with, and that is turned into an extmark sign. The
-- signs are redone on every `DiffUpdated`, which the internal diff fires
-- after each edit. gitsigns keeps drawing its own signs in the right-hand
-- (working tree) pane; these win where the two overlap, and for the plain
-- working-tree diff (`<leader>gd`) they agree anyway.
local sign_ns = vim.api.nvim_create_namespace("diffview_hunk_signs")
local SIGN_PRIORITY = 20 -- gitsigns places its signs at 6

-- Buffers that carry these signs, cleared when the view closes: the
-- working-tree buffers outlive diffview and must not keep the marks.
local signed_bufs = {}

-- `a` mixed into `b` at ratio `t`, both "#rrggbb".
local function blend(a, b, t)
  local out = "#"
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(x * t + y * (1 - t) + 0.5))
  end
  return out
end

-- A gruvbox colour (`green`, `red`, `blue`) mixed at ratio `t` over its
-- page colour, per background, and no foreground of its own. transparent_mode
-- leaves Normal without a bg to blend with, so the page colour comes from the
-- palette (foot uses the same one).
local function diff_tint(colour, t)
  local p = require("gruvbox").palette
  if vim.o.background == "light" then
    return { bg = blend(p["faded_" .. colour], p.light0, t) }
  end
  return { bg = blend(p["bright_" .. colour], p.dark0, t) }
end

local function flatten_diff_hl()
  vim.api.nvim_set_hl(0, "DiffviewDiffAdd", diff_tint("green", 0.3))
  vim.api.nvim_set_hl(0, "DiffviewDiffAddAsDelete", diff_tint("red", 0.3))
  vim.api.nvim_set_hl(0, "DiffviewDiffChange", diff_tint("blue", 0.3))
  vim.api.nvim_set_hl(0, "DiffviewDiffText", diff_tint("blue", 0.55))
  -- A closed fold (the unchanged stretch between hunks) is gruvbox's Folded:
  -- a full-width block of background that competes with the tints above.
  -- In the diff panes it is plain grey text instead, like a comment.
  vim.api.nvim_set_hl(0, "DiffviewFolded", { link = "Comment" })
end

local function place_diff_signs(win)
  if not vim.api.nvim_win_is_valid(win) or not vim.wo[win].diff then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  -- Coloured like gitsigns' gutter (green, orange, red): gruvbox defines the
  -- GitSigns* groups itself, so they exist whether or not gitsigns is loaded.
  -- diffview's own status groups link to diffAdded/diffRemoved, which in
  -- gruvbox carry a background and no foreground -- useless for a glyph.
  -- On the old side a line the other pane lacks is a deletion, not an addition.
  local only_here = vim.w[win].diffview_old_side and { "-", "GitSignsDelete" } or { "+", "GitSignsAdd" }
  local changed = { "~", "GitSignsChange" }
  local glyph = {
    [vim.fn.hlID("DiffAdd")] = only_here,
    [vim.fn.hlID("DiffChange")] = changed,
    [vim.fn.hlID("DiffText")] = changed,
  }
  vim.api.nvim_buf_clear_namespace(buf, sign_ns, 0, -1)
  signed_bufs[buf] = true
  vim.api.nvim_win_call(win, function()
    for lnum = 1, vim.api.nvim_buf_line_count(buf) do
      local sign = glyph[vim.fn.diff_hlID(lnum, 1)]
      if sign then
        vim.api.nvim_buf_set_extmark(buf, sign_ns, lnum - 1, 0, {
          sign_text = sign[1],
          sign_hl_group = sign[2],
          priority = SIGN_PRIORITY,
        })
      end
    end
  end)
end

local function refresh_diff_signs()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[win].diffview_old_side ~= nil then
      place_diff_signs(win)
    end
  end
end

local function clear_diff_signs()
  for buf in pairs(signed_bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, sign_ns, 0, -1)
    end
  end
  signed_bufs = {}
end

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff working tree" },
    { "<leader>gm", diff_against_default_branch, desc = "Diff branch against main/master" },
    { "<leader>gM", pick_branch_and_diff, desc = "Diff branch against a picked branch" },
    { "<leader>gc", branch_commits, desc = "Commits of this branch, one by one" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "History of this file" },
    { "<leader>gh", ":DiffviewFileHistory<cr>", mode = "v", desc = "History of the selected lines" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "History of the branch" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
  },
  opts = function()
    local actions = require("diffview.actions")
    -- `gF` (as opposed to diffview's own `gf`, which reuses the previous tab)
    -- opens the file in a tab of its own, cursor on the same line, with
    -- diffview left open underneath: `gt`/`gT` or `:tabclose` bring it back.
    local open_in_tab = { "n", "gF", actions.goto_file_tab, { desc = "Open the file in a new tab, full size" } }
    local close = { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } }
    -- A history view shows commits only. `W` in its panel opens what is not
    -- committed yet -- the working tree's "Changes" (unstaged) and "Staged
    -- changes" -- in a tab of its own; `q` there closes it and lands back on
    -- the history. Panel only: in the diff panes `W` stays the WORD motion.
    local working_tree = { "n", "W", "<cmd>DiffviewOpen<cr>", { desc = "Uncommitted changes (staged + unstaged)" } }
    return {
      -- The default hunk/file/tree icons need a Nerd Font; the rest of this
      -- config (gitsigns, nvim-tree) draws plain ASCII, so stay consistent.
      use_icons = false,
      signs = { fold_closed = ">", fold_open = "v", done = "x" },
      -- Tells the two panes apart: lines missing on the right get their own
      -- group on the left (DiffviewDiffAddAsDelete, tinted red above) instead
      -- of DiffAdd, and the filler rows that pad the panes to equal height are
      -- dimmed instead of painted red.
      enhanced_diff_hl = true,
      hooks = {
        diff_buf_win_enter = function(_, winid, ctx)
          -- In the two-pane layouts `a` is the old revision on the left.
          vim.w[winid].diffview_old_side = ctx.layout_name:match("^diff2") ~= nil and ctx.symbol == "a"
          -- diffview sets the pane's winhighlight before this hook runs, so
          -- the Folded remap (see `flatten_diff_hl`) is added on top of it.
          local winhl = vim.wo[winid].winhighlight
          if not winhl:find("Folded:DiffviewFolded", 1, true) then
            vim.wo[winid].winhighlight = winhl == "" and "Folded:DiffviewFolded" or winhl .. ",Folded:DiffviewFolded"
          end
          vim.schedule(function()
            place_diff_signs(winid)
          end)
        end,
        view_closed = clear_diff_signs,
      },
      view = {
        -- Merge conflicts: ours | result | theirs, base in a row underneath.
        merge_tool = { layout = "diff4_mixed" },
      },
      -- diffview has no close key of its own (only `:DiffviewClose`); `q` is what
      -- lazygit, fugitive and nvim-tree all use, so it closes here as well.
      keymaps = {
        view = {
          close,
          open_in_tab,
          { "n", "z>", adjust_context(CONTEXT_STEP), { desc = "Show more unchanged lines around each change" } },
          { "n", "z<", adjust_context(-CONTEXT_STEP), { desc = "Show fewer unchanged lines around each change" } },
        },
        file_panel = { close, open_in_tab },
        file_history_panel = { close, open_in_tab, working_tree },
      },
    }
  end,
  config = function(_, opts)
    require("diffview").setup(opts)
    local group = vim.api.nvim_create_augroup("diffview_local", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = { "DiffviewFiles", "DiffviewFileHistory" },
      callback = function(event)
        attach_status_glyphs(event.buf)
      end,
    })
    -- diffview rebuilds DiffviewDiffAddAsDelete from DiffDelete in its own
    -- ColorScheme autocmd (registered above, so it runs first); flatten again
    -- after it.
    flatten_diff_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = flatten_diff_hl })
    vim.api.nvim_create_autocmd("DiffUpdated", { group = group, callback = refresh_diff_signs })
  end,
}
