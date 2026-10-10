---
name: commit
description: Create standardized git commits using Conventional Commits with intelligent diff analysis
argument-hint: "[optional message hint]"
allowed-tools: Bash(git *), Bash(pre-commit *), Read
---

# Git Commit with Conventional Commits

Create standardized, semantic git commits following the
[Conventional Commits](https://www.conventionalcommits.org/) specification. Analyze the
actual diff to determine the appropriate type, scope, and message. This skill is
repo-agnostic — it adapts to whatever project it is invoked in.

## Conventional Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

| Type       | Purpose                        |
| ---------- | ------------------------------ |
| `feat`     | New feature                    |
| `fix`      | Bug fix                        |
| `docs`     | Documentation only             |
| `style`    | Formatting/style (no logic)    |
| `refactor` | Code refactor (no feature/fix) |
| `perf`     | Performance improvement        |
| `test`     | Add/update tests               |
| `build`    | Build system/dependencies      |
| `ci`       | CI/config changes              |
| `chore`    | Maintenance/misc               |
| `revert`   | Revert commit                  |

## Workflow

### Step 1: Gather context

Run these commands **in parallel** to understand the current state:

```bash
git status
git diff --staged
git diff
git log --oneline -10
```

Skim the recent `git log` to match the repository's existing commit conventions
(scope names, casing, trailer style).

### Step 2: Stage files

- If nothing is staged, determine which files to stage based on logical grouping.
- **Stage specific files by name** — avoid `git add -A` or `git add .` which can
  accidentally include sensitive files.
- Group related changes into one commit. If changes span multiple logical units,
  suggest splitting into multiple commits.
- **NEVER stage files that likely contain secrets** (.env, credentials.json, private
  keys, tokens). Warn the user if they request it.

### Step 3: Run pre-commit on staged files (if configured)

If the repo has a `.pre-commit-config.yaml`, run the hooks on all staged files to catch
lint/formatting issues early:

```bash
pre-commit run --files $(git diff --staged --name-only | tr '\n' ' ')
```

- If pre-commit **modifies files** (auto-formatting), re-stage the fixed files with
  `git add` and note the fixes to the user.
- If pre-commit **fails** with errors that cannot be auto-fixed, fix the issues, re-stage,
  and re-run pre-commit until it passes.
- If `.pre-commit-config.yaml` exists but `pre-commit` is not installed, **stop and ask
  the developer to install it** (e.g., `pip install pre-commit`). Do not proceed.
- If the repo has no pre-commit config, skip this step.

### Step 4: Generate commit message

Analyze the staged diff to determine:

- **Type**: What kind of change? Use the table above.
- **Scope**: What module or area is affected? Use the directory or component name
  (e.g., the top-level package, subsystem, or `ci`, `docs`). Match the scope style
  already used in the repo's `git log`.
- **Description**: Concise summary in present tense, imperative mood, under 72 chars.
- **Body** (optional): Explain _why_ the change was made, not _what_ changed (the diff
  shows what). Use when the motivation isn't obvious from the description alone.
- **Footer** (optional): Reference issues (`Closes ABC-1234`, `Refs ABC-5678`) using the
  project's tracker prefix.

If the user provided a hint via `$ARGUMENTS`, incorporate it into the message.

### Step 5: Execute commit

Always use a HEREDOC for the commit message to ensure correct formatting:

```bash
git commit -m "$(cat <<'EOF'
<type>[scope]: <description>

<optional body>

<optional footer>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Step 6: Verify

Run `git status` after the commit to confirm success.

## Breaking Changes

For breaking changes, add `!` after the type/scope:

```
feat!: remove deprecated endpoint
```

Or use a `BREAKING CHANGE` footer for details:

```
feat: allow config to extend other configs

BREAKING CHANGE: `extends` key behavior changed
```

## Rules

- One logical change per commit
- Present tense imperative mood: "add" not "added", "fix bug" not "fixes bug"
- Keep the description line under 72 characters
- Always include the `Co-Authored-By: Claude <noreply@anthropic.com>` trailer
- If the commit fails due to pre-commit hooks, fix the issue and create a **NEW**
  commit — do NOT amend

## Git Safety Protocol

- NEVER update git config
- NEVER run destructive commands (--force, reset --hard, checkout .) without explicit
  user request
- NEVER skip hooks (--no-verify) unless the user explicitly asks
- NEVER force push to the trunk branch — warn the user if requested
- NEVER amend commits unless the user explicitly asks — create NEW commits instead
- Do NOT push to remote unless the user explicitly asks
