# Neovim Keybindings

> **Leader key = `Space`**

Press `<Space>` and wait half a second — which-key pops up and shows every
mapping that starts with it. That popup, not this file, is the fastest way to
remember a key you half-know.

---

## Starting up

`nvim` with no argument opens an empty buffer. Nothing is restored, no tree is
opened, no previous directory comes back — press `<leader>e` when you want the
file tree.

`nvim <path>` changes the working directory to that path (or to the file's
directory), so Telescope and grep are scoped where you expect.

---

## Files & Search (Telescope)

| Key            | Action                     |
| -------------- | -------------------------- |
| `<leader>ff`   | Find files                 |
| `<leader>fr`   | Recent files               |
| `<leader>fb`   | Search open buffers        |
| `<leader>fg`   | Live grep (ripgrep)        |

> **Inside Telescope:** `<C-j>`/`<C-k>` move selection, `<C-q>` send to quickfix, `<Esc>` close.
> In the buffer picker, `<C-d>` closes the buffer under the cursor.

---

## File Tree (nvim-tree)

| Key            | Action                      |
| -------------- | --------------------------- |
| `<leader>e`    | Toggle file tree            |
| `<leader>E`    | Reveal current file in tree |

Inside the tree: `<Enter>` opens, `a` creates, `d` deletes, `r` renames.

---

## Buffers

There is no tab bar. Buffers are switched by key, and `<leader>fb` lists them.

| Key            | Action              |
| -------------- | ------------------- |
| `<leader>n`    | Next buffer         |
| `<leader>N`    | Previous buffer     |
| `<leader>x`    | Close buffer        |
| `<leader>ml`   | Toggle last buffer  |

---

## LSP

| Key                 | Action                              |
| ------------------- | ----------------------------------- |
| `gd` / `<leader>gd` | Go to definition                    |
| `<leader>gD`        | Go to declaration                   |
| `<leader>gr`        | Go to references                    |
| `<leader>gi`        | Go to implementation                |
| `<leader>gt`        | Go to type definition               |
| `K`                 | Hover documentation                 |
| `<leader>rn`        | Rename symbol                       |
| `<leader>ca`        | Code action                         |
| `]d` / `[d`         | Next / previous diagnostic          |
| `<leader>de`        | Show full diagnostic in a float     |
| `<leader>td`        | Toggle diagnostics on/off           |
| `<leader>li`        | LSP status — what attached, and why not |

Servers are installed and enabled from an explicit list in
`lua/plugins/mason_lspconfig.lua`. If a language feels dead, `<leader>li` is the
first thing to check; the statusline's `L:` segment names whatever is attached
to the current buffer.

### How quiet the diagnostics are

The message text appears inline **only on the line the cursor is on**. Every
other problem in the file is just a sign in the left gutter and an underline —
so a file with thirty warnings still reads like code. `<leader>de` for the full
text of the one under the cursor, `]d`/`[d` to walk them.

Nothing is re-checked while you are still typing a line; diagnostics refresh
when you leave insert mode or save.

---

## Spelling & grammar

Two levels, both **per buffer** and both **toggles**.

| Key          | Level        | What it does                                                     |
| ------------ | ------------ | ---------------------------------------------------------------- |
| `<leader>ss` | *simple*     | Neovim's own spell checker, `en` + `cs`, offline and instant      |
| `<leader>sa` | *aggressive* | Simple, **plus** ltex-ls (LanguageTool) for grammar and style     |

**Simple** turns itself on for `markdown`, `text`, `gitcommit`, `tex` and
`pandoc`. Everywhere else — including code — you ask for it with `<leader>ss`.
In code it stays out of the way: treesitter limits it to comments and strings,
so identifiers are never flagged.

**Aggressive never starts on its own.** ltex-ls boots a JVM and takes a few
seconds before the first grammar squiggle appears, so it is meant for the moment
you sit down to write a document, not for every file you open. Press
`<leader>sa` again to shut it down.

**Aggressive is English-only**, and that is the server's limit, not a setting.
Both mason builds — `ltex-ls` and `ltex-ls-plus` — answer any Czech request with
`'cs-CZ' is not a recognized language. Leaving LanguageTool uninitialized,
checking disabled.` Asking for Czech does not fall back to English; it turns all
checking off. So Czech is handled by *simple* mode, which spell-checks `cs`
perfectly well but says nothing about grammar. Real Czech grammar would mean
running a self-hosted LanguageTool with the Czech module and pointing
`ltex.languageToolHttpServerUri` at it — not set up here.

| Key          | Action                                                    |
| ------------ | --------------------------------------------------------- |
| `]s` / `[s`  | Jump to next / previous misspelled word                   |
| `z=`         | Suggestions for the word under the cursor                 |
| `zg`         | Add word to the personal dictionary                       |
| `zw`         | Mark word as wrong (undo a bad `zg`)                      |
| `zug`/`zuw`  | Undo the last `zg` / `zw`                                 |
| `<leader>ca` | On a grammar diagnostic: apply suggestion / add to dictionary / disable rule |

Words added with `zg` land in `spell/en.utf-8.add` / `spell/cs.utf-8.add` inside
this config directory — which is a stow symlink into the dotfiles repo, so
commit them and your dictionary follows you to the next machine. ltex's own
"add to dictionary" and "disable rule" choices are persisted separately by
`ltex_extra.nvim` into `ltex-dictionary/`.

---

## Editing

| Key            | Mode     | Action                               |
| -------------- | -------- | ------------------------------------ |
| `<leader>f`    | Normal   | Format file (conform.nvim)           |
| `<leader>c`    | N/Visual | Toggle comment (built-in `gc`/`gcc`) |
| `<leader>sr`   | Normal   | Search & replace word under cursor   |
| `<leader>y`    | N/Visual | Yank to system clipboard             |
| `<leader>Y`    | Normal   | Yank line to system clipboard        |
| `<leader>d`    | N/Visual | Delete without yanking               |
| `p`            | Visual   | Paste without overwriting clipboard  |

---

## Navigation

| Key          | Action                             |
| ------------ | ---------------------------------- |
| `<C-u>`      | Scroll up and center               |
| `<C-d>`      | Scroll down and center             |
| `n` / `N`    | Next/prev search result and center |
| `<Esc>`      | Clear search highlight             |

---

## Completion (blink.cmp)

The menu appears on its own while typing. `<CR>` and `<Tab>` keep their normal
meaning, so prose typing is never hijacked.

| Key               | Action                       |
| ----------------- | ---------------------------- |
| `<C-Space>`       | Show / hide completion       |
| `<C-n>` / `<C-p>` | Next / previous item         |
| `<C-y>`           | Accept suggestion            |
| `<C-e>`           | Hide completion              |
| `<Tab>`/`<S-Tab>` | Jump through snippet fields  |
| `<C-b>` / `<C-f>` | Scroll docs up / down        |

Sources: LSP, paths, snippets, buffer words, and spelling suggestions — the
spell source only offers anything where spell checking is actually on.

---

## Notes (obsidian.nvim, markdown only)

| Key            | Action                     |
| -------------- | -------------------------- |
| `<leader>ot`   | Insert template            |
| `<leader>ol`   | Link word / selection to a note |

Vault: `~/ops/vnotes`.

---

## Git

Gitsigns marks changed lines in the gutter: `+` added, `~` changed, `_` deleted.
The statusline shows the branch and a summary of the diff.
