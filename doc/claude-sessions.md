# Claude Code sessions

How to keep Claude Code sessions organised: what a session is and how it gets named.

## The idea in three rules

**A session is one task, not one day.** Sessions are cheap and disposable. When the topic changes, start a new one (`/clear`) instead of stretching the old one — a session that spans five topics cannot be found again by any name.

**Every session gets a name.** Claude Code names nothing by itself; an unnamed session shows up in `/resume` as its first prompt and a timestamp, which is why a hundred of them become unsearchable. `ccs` derives `<repo>:<branch>` for you, so the default costs nothing.

**Anything that must outlive the session does not live in the session.** Knowledge goes to the wiki, state of work goes to the branch and the MR description, preferences go to `MEMORY.md`. Get that right and you rarely need to resume at all — which is the real fix for session sprawl.

## Naming

`ccs` (`~/.local/bin/ccs`, from `stow/my-scripts`) is a thin wrapper around `claude`. It forwards every flag untouched and adds `--name <repo>:<branch>` when you did not pass `--name` yourself. Skipped for `-p`, for the resume flags (the stored name wins) and for subcommands like `claude agents`.

`iclaude` and `pclaude` are aliased to it, so the work and personal instances both get naming. `cc` stays as the raw binary for when you want none of this.

```sh
iclaude                        # new session named e.g. "agents:feat/alerting-tooling"
iclaude -n "routing dump"      # explicit name wins
iclaude -r alerting            # resume picker, pre-filtered by "alerting"
/rename                        # rename mid-session, from inside Claude
```

Naming convention worth keeping: **the name is the branch**, optionally narrowed to the sub-task (`feat/alerting-tooling: routing dump`). It lines up with Conventional Commits and with the MR, so one string finds the session, the branch and the review.

## Command reference

In-session slash commands and their command-line equivalents. `—` means there is no equivalent on that side.

| What you want | In session | From the shell |
|---|---|---|
| Start a named session | — | `ccs -n "<name>"` (`-n` derived when omitted) |
| Rename the current session | `/rename` | — |
| Start a fresh session, same terminal | `/clear` | — |
| Continue the most recent session here | — | `ccs -c` / `claude --continue` |
| Pick an old session | `/resume` | `ccs -r [query]` / `claude --resume [query]` |
| Resume a specific session | — | `claude --resume <session-id>` |
| Resume without overwriting the original | — | `claude --resume <id> --fork-session` |
| Resume the session behind a PR | — | `claude --from-pr [number\|url]` |
| Pin a session to a known id | — | `claude --session-id <uuid>` |
| Shrink the context, keep the thread | `/compact` | `claude --autocompact <auto\|tokens>` |
| Undo to an earlier point (code + chat) | `/rewind` (Esc-Esc) | — |
| New git worktree + session for it | — | `claude -w <name>` (add `--tmux` for a tmux session) |
| Run a session in the background | — | `claude --bg -n "<name>" -p "<task>"` |
| List background sessions | — | `claude agents` (`--json`, `--cwd <path>`) |
| Open a background session here | — | `claude attach <id>` |
| Tail a background session's output | — | `claude logs <id>` |
| Stop / delete a background session | — | `claude stop <id>` / `claude rm <id>` |
| Delete all state for a project | — | `claude project purge [path]` |

## Where sessions live

Transcripts are per working directory, under `~/.claude/projects/<slugified-path>/<session-uuid>.jsonl` (and `~/.claude-personal/projects/…` for `pclaude`). Two consequences worth exploiting:

- A **git worktree is its own project**, so it gets its own session pool. Feature work started with `claude -w <name>` never mixes its history into the main checkout's `/resume` list. This is the cheapest partitioning available — use it before reaching for any naming scheme.
- Cleanup is just file deletion. Once an MR is merged, its sessions are dead weight: `rm ~/.claude/projects/<slug>/<uuid>.jsonl`, or `claude project purge <path>` to drop a project's state wholesale.

```sh
# biggest transcripts in the current project, newest first
ls -lSh ~/.claude/projects/"${PWD//\//-}"/*.jsonl | head
```

## Orchestrating instead of waiting

Three levels, cheapest first.

**Subagents inside a session.** Ask for the work to be dispatched to a subagent and it runs in the background while you keep talking in the same session; you get a notification when it lands. Good for anything whose *output* you need but whose *process* you do not want to read — searches across many files, independent reviews, parallel investigations. The `superpowers:dispatching-parallel-agents` and `superpowers:subagent-driven-development` skills cover the multi-task case.

**Background Claude sessions.** `claude --bg -n "<name>" -p "<task>"` starts a full, independent session detached from your terminal and prints its id. `claude agents` lists them, `claude logs <id>` tails one, `claude attach <id>` pulls it into the current window when it needs you. Unlike a subagent this survives your session ending, has its own permissions and its own transcript — the right tool for a long build, a migration, or a task you want to check on tomorrow.

**Worktree sessions.** `claude -w <branch> --tmux` gives a task its own checkout, its own session pool and its own tmux window in one command. Use it whenever two tasks would otherwise fight over the same working tree.

Rule of thumb: subagent when you want the answer, background session when you want the work, worktree when you want the branch.

## Always-on Remote Control servers

`claude-rc@<instance>.service` (systemd stow package) keeps a `claude remote-control` server running per instance, so a new session can be started from the phone or claude.ai/code without touching the laptop. The instance table lives in `~/.local/bin/claude-rc`:

| Instance | Config | Directory |
|---|---|---|
| `i-dot` | work (`~/.claude`) | `~/.dot` |
| `p-dot` | personal (`~/.claude-personal`) | `~/.dot` |
| `i-agents` | work | `~/dev/isee/agents` |
| `p-hub` | personal | `~/dev/zezav/hub` |

Every session started from a device gets its own git worktree (`--spawn worktree`). Adding an instance means a new `case` line in `claude-rc` plus a `default.target.wants/claude-rc@<instance>.service` symlink; the directory must already be trusted by that config, since the trust prompt would block an unattended start.

```sh
systemctl --user status 'claude-rc@*'      # all servers
journalctl --user -u claude-rc@i-dot        # start/stop history
tmux -L claude-rc-i-dot attach              # the server TUI (space = QR code, w = spawn mode); detach with C-b d
systemctl --user restart claude-rc@p-hub    # e.g. after `claude update` or a re-login
```

The servers run whenever the user session does: they start at login (no lingering) and stay reachable with the lid closed when docked or on external power. On battery the lid still suspends the laptop. The on-power part comes from `/etc/systemd/logind.conf.d/lid.conf` (`HandleLidSwitchExternalPower=ignore`), installed by the ansible `logind` role (`ansible-playbook -i localhost, -c local --tags logind playbook-environment.yml`).

The work instance deliberately leaves `CLAUDE_CONFIG_DIR` unset: set explicitly to `~/.claude`, claude reads the account from `~/.claude/.claude.json` instead of `~/.claude.json` and refuses with "Unable to determine your organization for Remote Control eligibility".
