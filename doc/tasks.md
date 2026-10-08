# Personal tasks

Personal (non-work) tasks live as Markdown files in the Obsidian vault, so the same data is usable from the phone (Obsidian mobile), from the desktop Obsidian app and from the terminal (`life`, in the `my-scripts` package). Work stays in Jira (`jql`); `life` is its personal-life twin and copies its keys where it can.

## Vault layout

The vault (`~/ops/vnotes`) has three top-level folders: `notes/` for knowledge (the Zettelkasten/PARA folders, `notes/00_START_HERE.md`), `tasks/` for the files described here, and `docs/` for scanned documents and PDFs. `docs/` is gitignored, so personal documents reach the phone through remotely-save only and never go to GitHub; `notes/` and `tasks/` are synced by both git and remotely-save.

## Format

One flat folder (`$LIFE_DIR`, default `~/ops/vnotes/tasks/`), one file per task. There are no epics or projects: a bigger piece of work is one task with subtasks, and tags do the grouping.

```markdown
---
status: doing          # todo | doing | waiting | done
due: 2026-10-10        # optional, real deadlines only
tags: [school]         # optional, what you filter by
created: 2026-10-01    # set by `life`
done:                  # set by `life` when finished
---
Seminar paper for NI-XYZ, upload to the course page.

- [x] outline
- [x] draft
- [ ] proofread
- [ ] upload PDF

## Log
- 2026-10-05 draft finished, sent to Petr for feedback
```

Rules:

- **Title** is the filename (`Submit paper.md`). Rename the file to rename the task. `/` is not allowed in a title.
- **status** is one of four values. `doing` is what you're focused on now (there is no priority field), `waiting` means blocked on someone else (the log says who), `done` hides the task from the default views. A missing `status`, or no frontmatter at all, counts as `todo`, so a note written quickly on the phone is a valid task.
- **due** is `YYYY-MM-DD` or empty. Only real deadlines; `life` shows it red when overdue and yellow within 3 days.
- **tags** is a YAML list, either `[a, b]` or one `- a` per line (Obsidian's property editor writes the latter). Use short lowercase words: `school`, `home`, `bank`, `admin`, `family`.
- **created / done** are dates set by `life`; editing by hand is fine.
- **Subtasks** are `- [ ]` / `- [x]` lines anywhere in the body; the list shows them as `[done/total]`.
- **Log** is the `## Log` section, one `- YYYY-MM-DD text` line per entry, newest last.
- Files whose name starts with `_` (e.g. `_README.md`) and non-`.md` files are not tasks.
- Done tasks stay in the folder. Clean them out (delete or move to an archive folder) whenever the folder feels crowded; nothing depends on them.

Everything is plain frontmatter plus standard Markdown checkboxes, so the Obsidian Tasks plugin, Bases, search and the tag pane all work on it without extra plugins.

## Terminal: `life`

```
life                     open tasks: doing, waiting, todo; each by due date
life school              same, pre-filtered to "school" (title or #tag)
life --all               include done tasks
life add 'Title' tag…    create a task without opening the browser
life --plain             print a table (also when the output is piped)
```

In the browser: `enter` edits the file in `$EDITOR`, `alt-n` creates a task, `alt-m` changes status, `alt-d` marks done, `alt-c` adds a log line, `alt-s` adds a subtask, `alt-t` ticks or unticks one, `ctrl-a` switches between open and all, `ctrl-r` reloads, `?` shows help. The right pane renders the file with `bat`.

Parsing is a single `gawk` pass over the folder, with no `yq` and no index file, so the folder is the only state and anything Obsidian writes is picked up on the next reload.

## Obsidian (desktop and phone)

A Bases view gives the same list on the phone. Save it as `tasks/_Tasks.base` (Bases is a core plugin, Obsidian 1.9+):

```yaml
filters:
  and:
    - file.inFolder("tasks")
    - file.ext == "md"
    - '!file.name.startsWith("_")'
views:
  - type: table
    name: Open
    filters:
      and:
        - status != "done"
    groupBy:
      property: note.status
      direction: ASC
    order:
      - file.name
      - due
      - tags
    sort:
      - property: due
        direction: ASC
  - type: table
    name: Done
    filters:
      and:
        - status == "done"
    order:
      - file.name
      - done
      - tags
    sort:
      - property: done
        direction: DESC
```

To add a task on the phone, create a note in `tasks/` from this template (`notes/99_templates/tpl_task.md`); `{{date}}` is filled by the core Templates plugin:

```markdown
---
status: todo
due:
tags: []
created: {{date:YYYY-MM-DD}}
done:
---
```
