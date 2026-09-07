# Claude Code — Project Conventions

This file defines how I work in every project. Follow these conventions consistently.

---

## Tool & Runtime Management — Nix

All runtimes, CLIs, and tools are declared in a Nix flake.

- Always use `flake.nix` at the project root, with `flake.lock` committed
- Never assume a tool is globally available — put it in the devshell
- Activate with direnv: `.envrc` containing `use flake` and, when the
  project needs secrets, `dotenv_if_exists .env`

```nix
# flake.nix — minimal devshell
devShells.default = pkgs.mkShellNoCC {
  packages = [
    pkgs.just
    pkgs.go
    pkgs.golangci-lint
  ];
};
```

When bootstrapping a new project, run:
```sh
direnv allow
```

---

## Task Runner — just

Use `just <recipe>` for all automation. Two conventions:

### Small recipes (≤ 5 lines) — inline in `justfile`

```just
# Format all source files.
fmt:
    pre-commit run --all-files

# Verify without modifying anything — same hooks, sandboxed.
lint:
    nix flake check

# Run the test suite.
test:
    go test ./...

# Build the project.
build:
    go build -o bin/app ./cmd/app
```

### Large recipes (> 5 lines) — file-based scripts in `scripts/`

Recipes longer than a few lines call a script in `scripts/` rather than
growing inline.

```sh
# scripts/release
#!/usr/bin/env bash
set -euo pipefail
# multi-step release logic here
```

Mark executable: `chmod +x scripts/release`

### Mandatory recipes every project must have

| Recipe | Purpose |
|--------|---------|
| `just fmt` | Repair formatting across the working tree |
| `just lint` | Verify without modifying (`nix flake check`) |
| `just test` | Run test suite |
| `just build` | Build the project |
| `just ci` | lint + test |

Bare `just` lists every recipe, so the justfile is its own help text.

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
2. **Prerequisites** — Nix with flakes, direnv
3. **Quick start** — clone → `direnv allow` → `just build`
4. **Available tasks** — table of all `just` recipes
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

## CI/CD — nix flake check

`nix flake check` is the CI gate. It runs the project's pre-commit hooks
against a sandboxed copy of the source, so CI and the local commit hook
check identical definitions.

### Conventions

- Hooks are defined once, in `flake.nix`, via `git-hooks.nix`
- `just lint` is `nix flake check`; `just fmt` is `pre-commit run --all-files`
  over the working tree
- Per-file hygiene belongs in hooks; project operations belong in
  `justfile`. Where they overlap, just delegates to the hooks — never
  define lint twice
- Enable every hook from the `git-hooks.nix` catalogue that applies to the
  languages in the project, plus `commitizen` for Conventional Commits

```nix
checks.pre-commit = git-hooks.lib.${system}.run {
  src = ./.;
  hooks = {
    gofmt.enable = true;
    govet.enable = true;
    staticcheck.enable = true;
    end-of-file-fixer.enable = true;
    trim-trailing-whitespace.enable = true;
    commitizen.enable = true;

    # A tool the catalogue doesn't cover gets defined inline.
    golangci-lint = {
      enable = true;
      name = "golangci-lint";
      entry = "${pkgs.golangci-lint}/bin/golangci-lint run";
      types = [ "go" ];
      pass_filenames = false;
    };
  };
};
```

Check the catalogue before assuming a hook exists — it covers `gofmt`,
`govet`, `staticcheck`, `prettier`, `eslint`, `ruff`, `mypy`, `shellcheck`
and ~140 more, but not `golangci-lint`, `rubocop` or `puppet-lint`. Those
get an inline definition like the one above.

A hosted CI runner, when one is needed, does nothing but check out the
repo and run `nix flake check`.

---

## Project Bootstrapping Checklist

When creating a new project from scratch, do this in order:

1. `git init`
2. Create `flake.nix` with the devshell and the hook set
3. `direnv allow` (or `nix develop`)
4. Initialize language project (`go mod init ...`, `npm init`, etc.)
5. Create `.editorconfig`
6. Create `.gitignore` (use language-appropriate template) — always
   including `/.direnv/`, `/result` and `/.pre-commit-config.yaml`;
   `flake.lock` is committed, never ignored
7. Create `justfile` with the mandatory recipes
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
| `ci` | CI pipeline or hook set changes |
| `perf` | Performance improvement |

### Rules

- Subject line ≤ 72 chars, imperative mood ("add X", not "added X")
- Scope = component/package affected (optional but helpful)
- Body explains *why*, not *what* — the diff shows what
- One logical change per commit
- Always run `just ci` before committing

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
chore: add golangci-lint to the devshell and hook set
```

```
docs(architecture): document L4 LB failover topology
```

---

## Language-Specific Notes

### Go

- Module path follows `github.com/<org>/<repo>` convention
- `golangci-lint` with config at `.golangci.yml`
- `gofmt` for formatting (via `just fmt`)
- Packages organized as `cmd/`, `internal/`, `pkg/` where appropriate

### TypeScript / Node

- `prettier` + `eslint` for fmt/lint
- `package.json` scripts map to `just` recipes
- Use `pnpm` over npm/yarn

### Python

- Package manager: **uv** exclusively — never pip, pipenv, or poetry
- Python and uv come from the devshell:

```nix
packages = [
  pkgs.python3
  pkgs.uv
];
```

#### Python projects

Use `uv` for dependency management:

```sh
uv init          # new project
uv add <pkg>     # add dependency
uv sync          # install from lockfile
uv run <cmd>     # run inside the managed venv
```

Lint/format recipes use `ruff`:

```just
fmt:
    pre-commit run --all-files

lint:
    nix flake check

test:
    uv run pytest
```

`ruff` and `mypy` run as `git-hooks.nix` hooks rather than as their own
recipes, so they are defined once and checked on every commit.

#### Standalone Python scripts

In a Nix project, scripts get their dependencies from the devshell's
`python3.withPackages`, and use a plain `#!/usr/bin/env python3` shebang.

```nix
packages = [
  (pkgs.python3.withPackages (ps: with ps; [ httpx rich ]))
];
```

```python
#!/usr/bin/env python3

import httpx
from rich import print
...
```

The PEP 723 inline header plus the `uv run --script` shebang remains the
right pattern only for scripts that must run outside any project — a
one-off utility in `~/bin`, not a task in a repo.

Rules:
- Make executable: `chmod +x scripts/<name>`, and drop the `.py` extension
  for repo tasks so `just` recipes read cleanly
- Run inside the devshell; outside it, the imports will fail

### Shell scripts

- `#!/usr/bin/env bash` + `set -euo pipefail`
- shellcheck via lint task

---

*This file is the source of truth for project conventions. When in doubt, follow it.*
