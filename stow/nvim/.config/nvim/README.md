# Neovim Keybindings

> **Leader key = `Space`**

---

## Spelling & Diagnostics

| Key            | Action                                          |
| -------------- | ----------------------------------------------- |
| `]d`           | Jump to next diagnostic / misspelling           |
| `[d`           | Jump to previous diagnostic / misspelling       |
| `<leader>de`   | Show full diagnostic message in float           |
| `<leader>ca`   | Code actions: fix spelling / add to dictionary  |
| `<leader>td`   | Toggle all diagnostics on/off                   |
| `<leader>ll`   | Force re-run linters now                        |

> **Spell fix workflow:** `]d` → land on word → `<leader>ca` → pick suggestion or "Add to dictionary"
> Personal dictionary: `~/.config/cspell/words.txt`

---

## LSP

| Key            | Action                  |
| -------------- | ----------------------- |
| `gd`           | Go to definition        |
| `gD`           | Go to declaration       |
| `gr`           | Go to references        |
| `gi`           | Go to implementation    |
| `K`            | Hover documentation     |
| `<leader>rn`   | Rename symbol           |
| `<leader>D`    | Type definition         |

---

## Files & Search (Telescope)

| Key            | Action                                 |
| -------------- | -------------------------------------- |
| `<leader>ff`   | Find files (frecency / recent first)   |
| `<leader>fb`   | Search open buffers                    |
| `<leader>fg`   | Live grep (ripgrep)                    |
| `<leader>ft`   | Search tabs                            |

> **Inside Telescope:** `<C-j>/<C-k>` move selection, `<C-q>` send to quickfix, `<Esc>` close

---

## File Tree (nvim-tree)

| Key            | Action                        |
| -------------- | ----------------------------- |
| `<leader>e`    | Toggle file tree              |
| `<leader>E`    | Reveal current file in tree   |

---

## Buffers

| Key            | Action                  |
| -------------- | ----------------------- |
| `<leader>n`    | Next buffer             |
| `<leader>p`    | Previous buffer         |
| `<leader>x`    | Close buffer            |
| `<leader>ml`   | Toggle last buffer      |

---

## Editing

| Key            | Mode     | Action                              |
| -------------- | -------- | ----------------------------------- |
| `<leader>f`    | Normal   | Format file (conform.nvim)          |
| `<leader>sr`   | Normal   | Search & replace word under cursor  |
| `<leader>y`    | N/Visual | Yank to system clipboard            |
| `<leader>Y`    | Normal   | Yank line to system clipboard       |
| `<leader>d`    | N/Visual | Delete without yanking              |
| `p`            | Visual   | Paste without overwriting clipboard |

---

## Navigation

| Key          | Action                              |
| ------------ | ----------------------------------- |
| `<C-u>`      | Scroll up and center                |
| `<C-d>`      | Scroll down and center              |
| `n` / `N`    | Next/prev search result and center  |
| `<Esc>`      | Clear search highlight              |

---

## Completion (blink.cmp)

| Key          | Action                        |
| ------------ | ----------------------------- |
| `<C-Space>`  | Show / hide completion        |
| `<C-e>`      | Hide completion               |
| `<CR>`       | Accept suggestion             |
| `<Tab>`      | Next item / expand snippet    |
| `<S-Tab>`    | Prev item / shrink snippet    |
| `<C-b>`      | Scroll docs up                |
| `<C-f>`      | Scroll docs down              |
