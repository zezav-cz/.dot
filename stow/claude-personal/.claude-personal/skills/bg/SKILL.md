---
name: bg
description: Use when the user types /bg, asks for something to run in the background, in parallel, detached, or "while we keep going", says not to wait for it — or when a request would otherwise block the conversation for minutes on a sweep across many files, repositories, logs, dashboards or wiki pages.
allowed-tools: Agent, Read, Grep, Glob, Bash(git *)
argument-hint: "<task to run in the background>"
---

# Run a task in the background

Dispatch the task to a subagent and keep the conversation moving. The user's time is the scarce resource here, not the agent's: the point is that they get the terminal back immediately and the result arrives as a notification.

## What you produce

Three things, in this order.

**1. The dispatch.** An `Agent` call is the first tool call of the turn — before reading files, before searching, before planning the approach. The subagent does that work; doing it first in the main thread defeats the purpose.

**2. The acknowledgement.** One line naming what was dispatched and what will come back. Then continue with whatever else the user asked for, or hand the turn back.

**3. The report, when the result lands.** The conclusion, the paths or commands that back it up, and the next action. Not the transcript of what the subagent read.

## Writing the dispatch prompt

The subagent starts with no conversation history. Four slots, all filled:

| Slot | Content |
| ---- | ------- |
| Goal | The question to answer or the artifact to produce, in one sentence |
| Scope | Directories, repos, time ranges or hosts it may touch — and the boundary it must not cross |
| Deliverable | The shape of the answer: a verdict, a table, a file path, a patch |
| Starting points | Files, wiki pages, commands or ticket IDs already known to be relevant |

State the search breadth explicitly (`medium` for one area, `very thorough` when naming conventions vary or several locations are plausible) — a vague brief comes back vague.

## Picking the agent

| Situation | Agent |
| --------- | ----- |
| Locating code, configs or wiki pages across many paths | `Explore` |
| Multi-step research or a task that also runs commands | `general-purpose` |
| Work that needs this conversation's context | `fork` |
| Anything a listed specialised agent covers (review, docs, devops) | that agent |

Independent questions go out as separate `Agent` calls **in one message** so they run concurrently. A task that depends on another's answer waits for it — do not fan those out.

## Keep it in the main thread instead

- A targeted edit, or any work where the file is already identified.
- Anything needing the user's judgement partway through.
- A single lookup that one `grep` or one `Read` settles.

## Escalating past a subagent

| Need | Use |
| ---- | --- |
| The answer, this session | `Agent` (this skill) |
| The work, surviving this session | `claude --bg -n "<name>" -p "<task>"`, then `claude agents` / `claude logs <id>` / `claude attach <id>` |
| A branch of its own to work on | `claude -w <branch> --tmux`, worktree under `.claude/worktrees/` |

Detached sessions and worktrees are the user's call — offer, don't start one unasked.

## Common mistakes

| Mistake | Fix |
| ------- | --- |
| Investigating first, dispatching after | The `Agent` call comes first; that is the whole point |
| Waiting idly for the result | Dispatch, then do the parts that do not depend on it |
| Relaying the subagent's full output | It is not shown to the user, but only the conclusion belongs in the reply |
| Treating a subagent's finding as verified | It can be wrong; check anything load-bearing before acting on it |
| Fanning out dependent steps | Chain them; only independent work runs in parallel |
