# Go

- Module path follows the `github.com/<org>/<repo>` convention.
- Lint with `golangci-lint`, configured via `.golangci.yml` at the project root.
- Format with `gofmt` (wired up as `mise run fmt`).
- Organize packages as `cmd/`, `internal/`, `pkg/` where appropriate — `cmd/` for binaries, `internal/` for code that shouldn't be imported outside the module, `pkg/` for code that's fine to be imported by other projects.

Typical `mise.toml` task block for a Go project:

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

[tasks.ci]
run = ["mise run fmt", "mise run lint", "mise run test"]
description = "Run fmt + lint + test"
```
