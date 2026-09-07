---
name: dev-conventions
description: Zezav's standard conventions for every coding project — Nix flakes for tool/runtime management, just recipes (fmt/lint/test/build/ci) as the only automation entry point, .editorconfig, a README + doc/ documentation structure with ADRs, nix flake check as the CI gate with git-hooks.nix pre-commit hooks, a project bootstrapping checklist, and Conventional Commits for git history. Consult this whenever writing or modifying code in a git repository — bootstrapping a new project, adding or changing a build/lint/test task, writing a README or architecture doc, setting up or editing a CI pipeline, committing changes, or writing Go, TypeScript/Node, Python, Ruby, Puppet, or shell code — even if the user doesn't say "conventions" or name this file. Also consult before running `git commit`, when a new repo is being scaffolded from scratch, or when working with Puppet modules, a control repo, Hiera, or a Puppet Bolt project (plans/tasks/inventory).
---

# Dev Project Conventions

This is how Zezav works across every project, in every language. The goal is that any repo, opened cold, looks and behaves the same way: same tool manager, same task names, same docs layout, same commit style. Follow these conventions by default; don't ask permission to apply them unless the repo already does something conflicting and the change would be disruptive.

## Tool & runtime management — Nix

Every project declares its runtimes and CLIs in a `flake.nix` at the project root, with `flake.lock` committed so builds are reproducible across machines. Don't assume a tool (Go, Node, a linter) is globally available — put it in the devshell.

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

Activation is direnv: an `.envrc` with `use flake`, plus `dotenv_if_exists .env` when the project needs secrets. When bootstrapping or picking up a project, run `direnv allow` (or `nix develop`) before anything else.

## Task runner — just

All automation goes through `just <recipe>`, never raw invocations of the underlying tool. This keeps the command a contributor runs identical regardless of what's implementing it underneath. Bare `just` lists every recipe, so the justfile is its own help text.

- **Small recipes (≤ 5 lines)**: define inline in `justfile`.
- **Large recipes (> 5 lines)**: put them in a file-based script under `scripts/<name>`, `chmod +x` it.

```just
# Repair formatting across the working tree.
fmt:
    pre-commit run --all-files

# Verify without modifying anything — same hooks, sandboxed.
lint:
    nix flake check

# Run tests.
test:
    go test ./...

# Build binary.
build:
    go build -o bin/app ./cmd/app
```

```sh
# scripts/release
#!/usr/bin/env bash
set -euo pipefail
# multi-step release logic here
```

Every project must have these five recipes: `fmt`, `lint`, `test`, `build`, and `ci` (which runs lint + test). After touching source files, run `fmt`, `lint`, and `test`. Before committing, run `just ci`.

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

`README.md` needs these five sections, in order: what this is (one paragraph, no fluff), prerequisites (Nix with flakes, direnv), quick start (clone → `direnv allow` → `just build`), available tasks (table of every `just` recipe), and project structure (brief directory map).

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

## CI/CD — nix flake check

`nix flake check` is the CI gate, not raw YAML in the CI provider. It runs the project's pre-commit hooks against a sandboxed copy of the source, so CI and the local commit hook check identical definitions. A hosted runner, when one is needed, does nothing but check out the repo and run `nix flake check`.

Hooks are defined once, in `flake.nix`, via `git-hooks.nix`. Enable every hook from its catalogue that applies to the languages present, plus `commitizen` for Conventional Commits.

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

The layering rule: per-file hygiene belongs in hooks, project operations belong in `justfile`. Where they overlap, just delegates to the hooks — `just lint` is `nix flake check` and `just fmt` is `pre-commit run --all-files`, so lint is never defined twice.

## Bootstrapping a new project

When creating a project from scratch, do this in order — skipping steps is how repos end up inconsistent with everything else Zezav owns:

1. `git init`
2. Create `flake.nix` with the devshell and the hook set
3. `direnv allow` (or `nix develop`)
4. Initialize the language project (`go mod init ...`, `npm init`, `uv init`, `bundle init` + local bundler config, `pdk new module ...`, `bolt project init ...`, etc.)
5. Create `.editorconfig`
6. Create `.gitignore` (language-appropriate template), always including `/.direnv/`, `/result` and `/.pre-commit-config.yaml`; `flake.lock` is committed, never ignored
7. Create `justfile` with the five mandatory recipes
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
| `ci` | CI pipeline or hook set changes |
| `perf` | Performance improvement |

Rules: subject line ≤ 72 chars, imperative mood ("add X" not "added X"); scope is the component/package affected (optional but helpful); the body explains *why*, since the diff already shows *what*; one logical change per commit; always run `just ci` before committing.

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
chore: add golangci-lint to the devshell and hook set
```
```
docs(architecture): document L4 LB failover topology
```

## Language-specific notes

Read the reference file for whichever language(s) the project uses before writing fmt/lint/test tasks or bootstrapping — each has its own package manager and tool conventions that plug into the flake/just setup above.

- Go → `references/go.md`
- TypeScript / Node → `references/typescript.md`
- Python → `references/python.md`
- Ruby → `references/ruby.md`
- Puppet & Puppet Bolt → `references/puppet.md`
- Shell scripts → `references/shell.md`
