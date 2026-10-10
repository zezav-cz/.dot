---
name: pwd
description: Use when the user types /pwd, or asks where the code is, which directory or worktree this session works in, "kde to je", "kde pracuješ", "jaká je cesta" — they want the path so they can open it themselves.
allowed-tools: Bash(pwd), Bash(git *)
---

# Where is the work happening

The user juggles many worktrees and workspaces and has lost track of which one this session is editing. They want a path they can copy and open — nothing else.

## Steps

1. Run one command:

   ```bash
   pwd; git rev-parse --show-toplevel --abbrev-ref HEAD --git-dir --git-common-dir 2>/dev/null
   ```

   When `--git-dir` differs from `--git-common-dir`, the directory is a linked worktree; the main checkout is the parent of `--git-common-dir`.

2. Recall from this conversation whether files were edited somewhere else than the shell's current directory — after `EnterWorktree`, a `cd`, a subagent running with `isolation: "worktree"`, or edits by absolute path into another repo. If so, that location is the answer the user cares about; the shell's directory is secondary.

## Output

Keep it to this shape, in the user's language:

```
/absolute/path/to/where/the/code/is
```
Branch `feature-x` · worktree of `/home/user/dev/repo` (omit the worktree part for a main checkout, omit the line outside git)

If edits happened in more than one place, list each path in its own code block with one line saying what was done there. No other commentary, no suggestions — the user only wants to know where to look.
