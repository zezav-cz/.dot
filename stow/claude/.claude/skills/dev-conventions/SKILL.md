---
name: dev-conventions
description: Zezav's standard conventions for every coding project — mise for tool/runtime management, mise tasks (fmt/lint/test/build/ci) as the only automation entry point, .editorconfig, a README + doc/ documentation structure with ADRs, Dagger-based CI/CD pipelines, a project bootstrapping checklist, and Conventional Commits for git history. Consult this whenever writing or modifying code in a git repository — bootstrapping a new project, adding or changing a build/lint/test task, writing a README or architecture doc, setting up or editing a CI pipeline, committing changes, or writing Go, TypeScript/Node, Python, Ruby, Puppet, or shell code — even if the user doesn't say "conventions" or name this file. Also consult before running `git commit`, when a new repo is being scaffolded from scratch, or when working with Puppet modules, a control repo, Hiera, or a Puppet Bolt project (plans/tasks/inventory).
---

# Dev Project Conventions

This is how Zezav works across every project, in every language. The goal is that any repo, opened cold, looks and behaves the same way: same tool manager, same task names, same docs layout, same commit style. Follow these conventions by default; don't ask permission to apply them unless the repo already does something conflicting and the change would be disruptive.

## Tool & runtime management — mise

Every project pins its runtimes and CLIs in a `mise.toml` at the project root — never a bare `.tool-versions`. Pin exact versions so builds are reproducible across machines; don't assume a tool (Go, Node, a linter, Dagger itself) is globally available, declare it.

```toml
# mise.toml — minimal example
[tools]
go = "1.22"
node = "22"
golangci-lint = "1.58"
dagger = "0.11"
```

When bootstrapping or picking up a project, run `mise install` before anything else.

## Task runner — mise tasks

All automation goes through `mise run <task>`, never raw invocations of the underlying tool. This keeps the command a contributor runs identical regardless of what's implementing it underneath.

- **Small tasks (≤ 5 lines)**: define inline in `mise.toml`.
- **Large tasks (> 5 lines)**: put them in a file-based script under `.mise/tasks/<name>`, `chmod +x` it.

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

```sh
# .mise/tasks/release
#!/usr/bin/env bash
set -euo pipefail
# multi-step release logic here
```

Every project must have these five tasks: `fmt`, `lint`, `test`, `build`, and `ci` (which runs fmt + lint + test in sequence). After touching source files, run `fmt`, `lint`, and `test`. Before committing, run `mise run ci`.

## Editor config

Every project root gets an `.editorconfig`, adapted per language present. Baseline:

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

## Documentation

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

`README.md` needs these five sections, in order: what this is (one paragraph, no fluff), prerequisites (runtime versions, mise setup), quick start (clone → `mise install` → `mise run build`), available tasks (table of every `mise run` task), and project structure (brief directory map).

`doc/architecture.md` covers system design, component responsibilities, and data flow. `doc/development.md` covers local setup details, env vars, and debugging tips. `doc/operations.md` covers deployment, config, and the runbook.

Keep docs close to the code they describe, and update them in the same commit as the related change — docs that drift from the code are worse than no docs. For a non-trivial decision (a real trade-off, not a routine change), add `doc/decisions/NNN-title.md`:

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

## CI/CD pipelines — Dagger

All pipelines are written in Dagger, not raw YAML in the CI provider. Initialize at the project root:

```sh
dagger init --name <project> --sdk go   # preferred
# or
dagger init --name <project> --sdk typescript   # only when the project is Node-first
```

Pipeline entry point is `ci/main.go` (Go SDK) or `ci/src/index.ts` (TS SDK). The pipeline should call `mise run` tasks inside containers rather than duplicating the fmt/lint/test/build logic in Dagger itself — Dagger orchestrates, mise defines the actual commands.

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

Run locally with `dagger call build --src .` / `dagger call test --src .`.

## Bootstrapping a new project

When creating a project from scratch, do this in order — skipping steps is how repos end up inconsistent with everything else Zezav owns:

1. `git init`
2. Create `mise.toml` with the required tools and the five mandatory tasks
3. `mise install`
4. Initialize the language project (`go mod init ...`, `npm init`, `uv init`, `bundle init` + local bundler config, `pdk new module ...`, `bolt project init ...`, etc.)
5. Create `.editorconfig`
6. Create `.gitignore` (language-appropriate template)
7. `dagger init --sdk go` (or `ts`)
8. Create `README.md` with all five required sections
9. Create `doc/` with at least `architecture.md` and `development.md`
10. Initial commit: `git add -A && git commit -m "chore: initial project scaffold"`

## Git commit messages — Conventional Commits

```
<type>(<scope>): <short summary>

[optional body — explain WHY, not WHAT]

[optional footer: Breaking-Change, Closes #issue]
```

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

Rules: subject line ≤ 72 chars, imperative mood ("add X" not "added X"); scope is the component/package affected (optional but helpful); the body explains *why*, since the diff already shows *what*; one logical change per commit; always run `mise run ci` before committing.

When asked to commit, derive the message from the actual diff rather than guessing:

1. Run `git diff --staged` (or `git diff HEAD` if nothing is staged yet)
2. Identify the logical change — type, scope, summary
3. If the diff contains multiple unrelated changes, split into separate commits rather than writing one message that tries to cover everything
4. Stage and commit with the resulting message

Examples:

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

## Language-specific notes

Read the reference file for whichever language(s) the project uses before writing fmt/lint/test tasks or bootstrapping — each has its own package manager and tool conventions that plug into the mise/task setup above.

- Go → `references/go.md`
- TypeScript / Node → `references/typescript.md`
- Python → `references/python.md`
- Ruby → `references/ruby.md`
- Puppet & Puppet Bolt → `references/puppet.md`
- Shell scripts → `references/shell.md`
