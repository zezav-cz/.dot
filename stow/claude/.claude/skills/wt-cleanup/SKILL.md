---
name: wt-cleanup
description: Clean up finished git worktrees across every repo under a directory, and report what unfinished work is left. Use when the user wants to tidy up worktrees, asks "what can I delete", "uklidit worktrees", "co mám rozdělaného", or after finishing a batch of tasks. Reports first, removes only after explicit confirmation.
allowed-tools: Bash(wt-inventory*), Bash(git *), Bash(glab *), Bash(gh *), Read
argument-hint: "[optional repo name — limits the sweep to one repo]"
---

# Worktree Cleanup

Sweeps every git checkout under the workspace root, classifies each worktree, removes the ones that are provably finished, and reports what is still in flight.

**The contract with the user: report first, remove only after they say yes.** Never remove anything in the same turn as the first report.

## Step 1 — Inventory

```bash
wt-inventory --root <workspace> --json          # e.g. --root ~/dev, or the current directory
wt-inventory --root <workspace> --repo <name> --json   # when $ARGUMENTS names one repo
```

`wt-inventory` lives in `~/.local/bin` (the `my-scripts` stow package). The workspace root is the directory holding the checkouts: the current directory when it contains repos, otherwise ask. The script is read-only — it never removes a worktree or deletes a branch. It fetches by default; add `--no-fetch` when `git fetch` fails (offline, remote unreachable) and say so in the report, because merge state is then stale.

It returns one entry per repo (`base`, `stash_count`, `fetch_ok`) and one per worktree with a `classification` and human-readable `reasons`:

| Classification | Meaning | Action |
| --- | --- | --- |
| `removable` | clean tree, merged into base | propose for removal |
| `waiting` | clean, pushed, not merged | leave; check the MR/PR |
| `wip-dirty` | uncommitted or untracked files present | leave; report *what* it is |
| `wip-unpushed` | commits exist only locally | leave; report; suggest pushing |
| `unknown` | detached HEAD, or merge state undeterminable | **never propose for removal** |
| `locked` | `git worktree lock`, often a live Claude session | skip entirely |
| `main-checkout` | the repo's own checkout | never touched |

Merge detection combines an ancestor test with a squash-merge probe, because squash merges (GitLab and GitHub alike) make a merged branch look unmerged. A branch marked `squash-merged` has had its content verified as already present in base.

## Step 2 — Confirm the ambiguous ones with the forge

For `waiting` and `unknown` entries only, check the MR/PR state. Pick the CLI by the remote host (`git -C <repo> remote get-url origin`):

```bash
# GitLab
cd <repo> && glab mr list --all --source-branch=<branch> -F json
# GitHub
cd <repo> && gh pr list --state all --head <branch> --json state,url
```

For `glab`, `--all` means "including closed and merged" — there is no `--state` flag (verified on glab 1.114.0). Read `state` from the JSON: `merged`, `opened` or `closed`. **`closed` is not `merged`** — a closed MR/PR means the work was rejected or superseded and its content is *not* in base, so the worktree stays.

This needs network access to the forge. If the CLI fails with a DNS or auth error, **say so in the report and skip it** — do not guess an MR/PR state. A `waiting` branch whose MR/PR is merged can be re-classified as removable; an `unknown` one cannot be promoted on MR/PR state alone.

Run this only for the handful of branches that need it, not for every worktree.

## Step 3 — Report

Group by urgency, not by repo. Every item ends in one concrete next action.

- 🔴 **Rozdělaná práce** — `wip-dirty` and `wip-unpushed`. For each: branch, age of last commit, and *what* the unfinished work actually is (read `diff_stat` and `dirty_sample`; open the diff when it is small and non-obvious). "18 uncommitted files" is not a report — say what they change.
- 🟡 **Čeká na review** — `waiting`, with MR/PR state when Step 2 got one.
- ⚫ **Nejasné** — `unknown` and `locked`, with why.
- 🟢 **Ke smazání** — `removable`, as an explicit numbered list of paths.

Call out two things that are easy to lose:
- A worktree that is **merged but dirty** — the branch is done, only local files stand in the way. Say which files, so the user can decide to discard or keep them. These are usually the biggest win of the whole sweep.
- Any repo with `stash_count > 0` — stashes are repo-wide and survive worktree removal, so they get silently orphaned.

Then ask for one confirmation covering the whole 🟢 batch.

## Step 4 — Remove, after the user confirms

For each confirmed worktree, in its repo:

```bash
git -C <repo> worktree remove <path>      # no --force, ever
git -C <repo> branch -d <branch>          # lowercase -d, never -D
git -C <repo> worktree prune
```

Both commands fail closed by design and are the last safety net:

- `worktree remove` without `--force` refuses if the tree is dirty.
- `branch -d` refuses if the branch is not merged.

**If either refuses, stop and report it. Never reach for `--force` or `-D` to get past a refusal** — a refusal means the classification was wrong, and forcing it destroys exactly the work this skill exists to protect. Report the refusal, re-run the inventory for that worktree, and let the user decide.

### The `branch -d` refusal you will hit on almost every run

`git branch -d` does **not** measure against `origin/<base>`. It measures against the repo's **local HEAD** (or the branch's upstream, when one is set). A local `main`/`develop` is routinely dozens of commits behind its remote, and a main checkout may be sitting on some unrelated branch entirely — so `-d` refuses branches that are genuinely merged.

When `-d` refuses, diagnose before doing anything:

```bash
git -C <repo> rev-parse --abbrev-ref HEAD                          # what -d compares against
git -C <repo> rev-list --count HEAD..origin/<base>                 # how stale that is
git -C <repo> merge-base --is-ancestor <branch> origin/<base>      # the real question
```

Two legitimate outcomes, and no third:

- **Ancestor of `origin/<base>` is YES, or the inventory proved a squash merge** — the classification was right and the refusal is only local staleness. The content is safe in the remote. `-D` is correct here, but it needs a **separate explicit yes from the user**, quoting this evidence. Never bundle it into the earlier removal confirmation.
- **Ancestor is NO and no squash was proven** — the classification was wrong. Stop. Report it. Do not delete the branch at all.

The alternative to `-D` is fast-forwarding the local base branch so `-d` passes on its own. That rewrites the user's checkout, so only do it if they ask.

Removing the worktree and deleting the branch are separate steps: the worktree removal above having succeeded does not oblige you to get the branch deleted in the same run. Leaving a branch behind is harmless.

## Step 5 — Close out

Report what was removed and what stayed, then re-run the inventory to confirm the end state matches.

## Never

- Remove or modify a `main-checkout`, or any worktree outside `.claude/worktrees/`.
- Delete a remote branch. This skill only touches local state.
- Drop, apply or clear a stash.
- Propose removal for `unknown` or `locked`.
- Remove anything in the same turn as the first report.
