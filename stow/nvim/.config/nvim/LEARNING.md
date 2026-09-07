# Learning This Config

A self-paced, one-feature-a-day plan for actually using what's set up here.
Each day: read the short "what/why", try the exercise in a real file, then move
on — don't binge multiple days at once, the point is muscle memory.

Full keybinding reference: [README.md](README.md). Leader key = `Space`.

If you forget a key, press `<Space>` and wait — which-key lists everything.

---

## Day 1 — Find files & search text (Telescope)

- `<leader>ff` — find files
- `<leader>fr` — recent files
- `<leader>fg` — live grep (search text across the project)
- `<leader>fb` — search open buffers
- Inside any Telescope window: `<C-j>`/`<C-k>` move, `<Enter>` opens, `<Esc>` closes

**Exercise:** open this repo, `<leader>ff` and jump to `init.lua`. Then
`<leader>fg` and search for `"lazy"` — see every file that mentions it.

---

## Day 2 — File tree (nvim-tree)

Nothing opens a tree for you; it is there when you ask.

- `<leader>e` — toggle the file tree sidebar
- `<leader>E` — reveal the current file in the tree (useful after `<leader>ff`)
- Inside the tree: `<Enter>` opens, `a` creates, `d` deletes, `r` renames

**Exercise:** start `nvim` with no arguments — you get an empty buffer, nothing
restored. Now `<leader>e`, navigate to `lua/plugins/`, open `telescope.lua`,
then `<leader>E` to see it highlighted back in the tree.

---

## Day 3 — Buffers

Every open file is a "buffer". There is no tab bar; you move between them by
key or by picker.

- `<leader>n` / `<leader>N` — next / previous buffer
- `<leader>x` — close current buffer
- `<leader>ml` — jump back to the last buffer you were on
- `<leader>fb` — pick from a list (and `<C-d>` in the list closes one)

**Exercise:** open 3-4 files via Telescope, cycle with `<leader>n`, then use
`<leader>fb` to jump straight to the one you want.

---

## Day 4 — LSP navigation

Works in any file with a language server attached — the statusline `L:` segment
names it, and `<leader>li` explains what happened when it says `L:∅`.

- `gd` — go to definition
- `<leader>gr` — go to references (who calls this?)
- `<leader>gi` — go to implementation
- `K` — hover documentation (types, docstrings)
- `<leader>rn` — rename symbol everywhere
- `<C-o>` — jump back where you came from

**Exercise:** in any code file, put the cursor on a function call, `gd` to jump
to its definition, `K` to see its docs, `<leader>gr` to see every place it's
used, then `<C-o>` twice to get home.

---

## Day 5 — Living with diagnostics

Errors and warnings are deliberately quiet: the message text shows up inline
**only on the line your cursor is on**. Elsewhere you get a sign in the gutter
and an underline, nothing more.

- `]d` / `[d` — jump to next / previous problem
- `<leader>de` — full message in a float
- `<leader>ca` — code action (this is where "fix it for me" lives)
- `<leader>td` — turn diagnostics off entirely for a while

**Exercise:** break something on purpose in a code file. Notice how little the
rest of the file changes. `]d` onto it, read it with `<leader>de`, then see if
`<leader>ca` offers a fix.

---

## Day 6 — Completion (blink.cmp)

Pops up automatically as you type in insert mode. `<CR>` and `<Tab>` are *not*
hijacked — they still insert a newline and a tab.

- `<C-Space>` — force-show the menu
- `<C-n>` / `<C-p>` — move through suggestions
- `<C-y>` — accept the selected suggestion
- `<C-e>` — dismiss the menu

**Exercise:** start typing a function name you've used before and accept it with
`<C-y>` instead of typing it out.

---

## Day 7 — Editing helpers

- `<leader>f` — format the current file (conform.nvim: stylua/prettier/black/...)
- `<leader>c` — toggle comment (normal: current line, visual: selection)
- `<leader>sr` — search & replace the word under the cursor, file-wide
- `<leader>y` / `<leader>Y` — yank (to system clipboard) selection / line
- `<leader>d` — delete without overwriting your yank register

**Exercise:** write a messy line of code, `<leader>f` to format it, `<leader>c`
to comment it out, then `<leader>sr` to rename a variable everywhere.

---

## Day 8 — Git signs

Gutter symbols while editing a tracked file: `+` added, `~` changed, `_` deleted.
Glance at the left column to see what you've touched since the last commit; the
statusline shows the branch and a diff summary.

**Exercise:** edit a tracked file and watch the `~` appear next to the changed
line.

---

## Day 9 — Spelling, level one

`<leader>ss` toggles Neovim's own spell checker for the current buffer, English
and Czech at once. It turns itself on in markdown, text and commit messages; in
code you ask for it, and it only ever looks inside comments and strings.

- `<leader>ss` — toggle it
- `]s` / `[s` — jump to next / previous misspelled word
- `z=` — suggestions for the word under the cursor
- `zg` — add the word to your dictionary (stored in this repo — commit it)

**Exercise:** open a `.md` file, type a typo on purpose, `]s` to find it, `z=` to
fix it. Then open a `.go` or `.py` file, `<leader>ss`, and check that a typo in a
comment gets flagged while the code around it does not.

---

## Day 10 — Spelling, level two

`<leader>sa` adds ltex-ls (LanguageTool) on top: real grammar and style, not just
misspelled words. It boots a JVM, so give it a few seconds — and it stays off
until you ask, which is the point. Press `<leader>sa` again to stop it.

This level is **English only** — the available ltex-ls builds simply do not carry
a Czech module. Czech prose gets level one: spelling, no grammar.

- `<leader>sa` — toggle aggressive checking for this buffer
- `]d` / `[d` — walk the grammar findings like any other diagnostic
- `<leader>ca` — apply a suggestion, add to dictionary, or disable that rule for good

**Exercise:** write an English paragraph with a deliberately clumsy sentence,
`<leader>sa`, wait for the squiggles, then `]d` → `<leader>ca` and take a
suggestion.

---

## After day 10

You've now touched every plugin in this config at least once. From here, just use
it for real work — `<Space>` plus a pause brings up which-key whenever you forget
something.
