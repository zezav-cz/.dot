# Go

- Module path follows the `github.com/<org>/<repo>` convention.
- Lint with `golangci-lint`, configured via `.golangci.yml` at the project root.
- Format with `gofmt` and vet with `govet`/`staticcheck`, enabled as hooks so `just fmt` and `just lint` cover them.
- Organize packages as `cmd/`, `internal/`, `pkg/` where appropriate — `cmd/` for binaries, `internal/` for code that shouldn't be imported outside the module, `pkg/` for code that's fine to be imported by other projects.

Hooks in `flake.nix`. `golangci-lint` has no catalogue hook, so define it inline:

```nix
hooks = {
  gofmt.enable = true;
  govet.enable = true;
  staticcheck.enable = true;
  golangci-lint = {
    enable = true;
    name = "golangci-lint";
    entry = "${pkgs.golangci-lint}/bin/golangci-lint run";
    types = [ "go" ];
    pass_filenames = false;
  };
};
```

Typical `justfile` for a Go project:

```just
# Repair formatting across the working tree.
fmt:
    pre-commit run --all-files

# Verify without modifying anything.
lint:
    nix flake check

# Run tests.
test:
    go test ./...

# Build binary.
build:
    go build -o bin/app ./cmd/app

# Run lint + test.
ci: lint test
```
