# Hardcoded `/home/jan` paths in tracked generated state

These five tracked files contain absolute `/home/jan/...` paths baked in by
the apps that own them, not hand-authored config. They weren't fixed as part
of the `openclaw-gateway.service` cleanup (see `stow/systemd/.config/systemd/user/openclaw-gateway.service`,
which now uses systemd's `%h` specifier) because stow does no templating --
there's no mechanism to substitute a param into these formats. Listed here
for review/decision: leave as-is (self-corrects when the owning app re-runs
under a new user), untrack + gitignore, or hand-edit.

- `stow/k9s/.config/k9s/config.yaml` -- `screenDumpDir: /home/jan/.local/state/k9s/screen-dumps`, rewritten by k9s on each run.
- `stow/vscode/.config/Code/User/keybindings.json` -- one `"when"` clause referencing `vscode-userdata:/home/jan/.config/Code/User/keybindings.json`, written when a keybinding was recorded via the VS Code GUI.
- `stow/claude/.claude/plugins/installed_plugins.json` -- plugin cache `installPath`/`projectPath` entries under `/home/jan/.claude/...` and `/home/jan/.dot`, rewritten by Claude Code's plugin manager.
- `stow/claude/.claude/plugins/known_marketplaces.json` -- marketplace `installLocation` entries under `/home/jan/.claude/plugins/marketplaces/...`, same source as above.
- `stow/claude/.claude/agents/doc-maintainer.md` and `stow/claude/.claude/agents/devops-setup-engineer.md` -- marketplace-installed agent files, each with a baked-in agent-memory path (`/home/jan/.claude/agent-memory/<agent>/`).

Not included: `stow/claude/.claude/settings.json` line ~109, which lists
`/home/jan/dev/fin` as a trusted repo -- that's personal trust data, not
portable config, so it's out of scope here.
