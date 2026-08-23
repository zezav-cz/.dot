# Claude Code — Project Conventions

This file defines how I work in every project. Follow these conventions consistently.

---

## Tool & Runtime Management — mise

All runtimes, CLIs, and tools are managed via [mise](https://mise.jdx.dev/).

- Always use `mise.toml` at the project root (never `.tool-versions` alone)
- Pin exact versions for reproducibility
- Never assume a tool is globally available — declare it in `mise.toml`

```toml
# mise.toml — minimal example
[tools]
go = "1.22"
node = "22"
golangci-lint = "1.58"
dagger = "0.11"
```

When bootstrapping a new project, run:
```sh
mise install
```

---

## Task Runner — mise tasks

Use `mise run <task>` for all automation. Two conventions:

### Small tasks (≤ 5 lines) — inline in `mise.toml`

```toml
[tasks.fmt]
run = "gofmt -w ."
description = "Format Go source"

[tasks.lint]
run = "golangci-lint run ./..."
description = "Run linter"

[tasks.test]
run = "go test ./..."
description = "Run tests"

[tasks.build]
run = "go build -o bin/app ./cmd/app"
description = "Build binary"
```

### Large tasks (> 5 lines) — file-based scripts in `.mise/tasks/`

```sh
# .mise/tasks/release
#!/usr/bin/env bash
set -euo pipefail
# multi-step release logic here
```

Mark executable: `chmod +x .mise/tasks/release`

### Mandatory tasks every project must have

| Task | Purpose |
|------|---------|
| `mise run fmt` | Format all source files |
| `mise run lint` | Run linter(s) |
| `mise run test` | Run test suite |
| `mise run build` | Build the project |
| `mise run ci` | Run fmt + lint + test in sequence |

Auto-run after touching source files: `fmt`, `lint`, `test`.
Auto-run before committing: `ci`.

---

## Editor Config — `.editorconfig`

Always create `.editorconfig` at the project root. Adapt per language.

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.go]
indent_style = tab
indent_size = 4

[*.{ts,js,json,yaml,yml,toml}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
max_line_length = 120

[Makefile]
indent_style = tab
```

---

## Documentation

### Structure

```
/
├── README.md          # Quick overview, setup, task reference
└── doc/
    ├── architecture.md
    ├── development.md
    ├── operations.md
    └── decisions/
        └── 001-<title>.md   # ADRs when needed
```

### README.md — required sections

1. **What this is** — one paragraph, no fluff
2. **Prerequisites** — runtime versions, mise setup
3. **Quick start** — clone → `mise install` → `mise run build`
4. **Available tasks** — table of all `mise run` tasks
5. **Project structure** — brief directory map

### doc/ — knowledge sharing

- `architecture.md` — system design, component responsibilities, data flow
- `development.md` — local setup details, env vars, debugging tips
- `operations.md` — deployment, config, runbook

Keep docs **close to the code they describe**. Update docs in the same commit as the related code change. Never let docs drift.

### ADRs (Architecture Decision Records)

For non-trivial decisions, create `doc/decisions/NNN-title.md`:

```markdown
# NNN: Title

**Status:** Accepted | Superseded by NNN
**Date:** YYYY-MM-DD

## Context
Why this decision was needed.

## Decision
What we decided.

## Consequences
Trade-offs and implications.
```

---

## CI/CD Pipelines — Dagger

All pipelines are written in Dagger. Initialize at the project root:

```sh
dagger init --name <project> --sdk go   # preferred
# or
dagger init --name <project> --sdk typescript
```

### Conventions

- Pipeline entry point: `ci/main.go` (Go SDK) or `ci/src/index.ts` (TS SDK)
- Use Go SDK by default; use TypeScript SDK only when the project is Node-first
- Pipelines call `mise run` tasks inside containers — don't duplicate logic

### Minimal Go pipeline skeleton

```go
// ci/main.go
package main

import (
    "context"
    "dagger/ci/internal/dagger"
)

type Ci struct{}

func (m *Ci) Build(ctx context.Context, src *dagger.Directory) (string, error) {
    return dag.Container().
        From("golang:1.22-alpine").
        WithDirectory("/src", src).
        WithWorkdir("/src").
        WithExec([]string{"go", "build", "./..."}).
        Stdout(ctx)
}

func (m *Ci) Test(ctx context.Context, src *dagger.Directory) (string, error) {
    return dag.Container().
        From("golang:1.22-alpine").
        WithDirectory("/src", src).
        WithWorkdir("/src").
        WithExec([]string{"go", "test", "./..."}).
        Stdout(ctx)
}
```

Run locally:
```sh
dagger call build --src .
dagger call test --src .
```

---

## Project Bootstrapping Checklist

When creating a new project from scratch, do this in order:

1. `git init`
2. Create `mise.toml` with required tools and tasks
3. `mise install`
4. Initialize language project (`go mod init ...`, `npm init`, etc.)
5. Create `.editorconfig`
6. Create `.gitignore` (use language-appropriate template)
7. `dagger init --sdk go` (or ts)
8. Create `README.md` with all required sections
9. Create `doc/` with at least `architecture.md` and `development.md`
10. Initial commit: `git add -A && git commit -m "chore: initial project scaffold"`

---

## Git — Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>

[optional body — explain WHY, not WHAT]

[optional footer: Breaking-Change, Closes #issue]
```

### Types

| Type | When |
|------|------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `chore` | Tooling, deps, config, scaffolding |
| `docs` | Documentation only |
| `refactor` | Code restructure, no behavior change |
| `test` | Adding or fixing tests |
| `ci` | Pipeline / Dagger changes |
| `perf` | Performance improvement |

### Rules

- Subject line ≤ 72 chars, imperative mood ("add X", not "added X")
- Scope = component/package affected (optional but helpful)
- Body explains *why*, not *what* — the diff shows what
- One logical change per commit
- Always run `mise run ci` before committing

### Deriving commit message from git diff

When asked to commit:
1. Run `git diff --staged` (or `git diff HEAD` if nothing staged yet)
2. Identify the logical change — type, scope, summary
3. If multiple unrelated changes: split into separate commits
4. Stage and commit with appropriate message

### Examples

```
feat(api): add pagination to /events endpoint

Default page size 50, configurable via ?limit=. Closes #42.
```

```
fix(vault): handle 429 on CRL fetch with exponential backoff
```

```
chore: add golangci-lint to mise.toml and ci pipeline
```

```
docs(architecture): document L4 LB failover topology
```

---

## Language-Specific Notes

### Go

- Module path follows `github.com/<org>/<repo>` convention
- `golangci-lint` with config at `.golangci.yml`
- `gofmt` for formatting (via `mise run fmt`)
- Packages organized as `cmd/`, `internal/`, `pkg/` where appropriate

### TypeScript / Node

- `prettier` + `eslint` for fmt/lint
- `package.json` scripts map to `mise run` tasks
- Use `pnpm` over npm/yarn

### Python

- Package manager: **uv** exclusively — never pip, pipenv, or poetry
- Declare `python` version in `mise.toml`:

```toml
[tools]
python = "3.12"
uv = "latest"
```

#### Python projects

Use `uv` for dependency management:

```sh
uv init          # new project
uv add <pkg>     # add dependency
uv sync          # install from lockfile
uv run <cmd>     # run inside the managed venv
```

Lint/format tasks use `ruff`:

```toml
[tasks.fmt]
run = "uv run ruff format ."

[tasks.lint]
run = "uv run ruff check . && uv run mypy ."

[tasks.test]
run = "uv run pytest"
```

#### Standalone Python scripts

Single-file scripts carry their own dependency metadata as a PEP 723 inline script header, and use the uv shebang so they are directly executable without any manual setup.

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "httpx>=0.27",
#   "rich>=13",
# ]
# ///

import httpx
from rich import print
...
```

Rules:
- First line is always `#!/usr/bin/env -S uv run --script` — makes the script self-executing
- `# /// script` block immediately follows with `requires-python` and `dependencies`
- No `requirements.txt` or `pyproject.toml` needed alongside the script
- Make executable: `chmod +x script.py`
- Run directly: `./script.py` or `uv run script.py`

### Shell scripts

- `#!/usr/bin/env bash` + `set -euo pipefail`
- shellcheck via lint task

---

*This file is the source of truth for project conventions. When in doubt, follow it.*
