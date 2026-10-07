# Claude Code sessions

How to keep Claude Code sessions organised: what a session is and how it gets named.

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

The work instance deliberately leaves `CLAUDE_CONFIG_DIR` unset: set explicitly to `~/.claude`, claude reads the account from `~/.claude/.claude.json` instead of `~/.claude.json` and refuses with "Unable to determine your organization for Remote Control eligibility".
