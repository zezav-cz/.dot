# TypeScript / Node

- Use `prettier` for formatting and `eslint` for linting.
- `package.json` scripts should just call through to the same commands `just` uses — don't maintain two separate command surfaces (npm scripts vs just recipes) that can drift apart.
- Use `pnpm` over `npm` or `yarn` for installs and running scripts.

Node and pnpm come from the devshell, and prettier/eslint are catalogue hooks:

```nix
devShells.default = pkgs.mkShellNoCC {
  packages = [
    pkgs.nodejs_22
    pkgs.pnpm
    pkgs.just
  ];
};

hooks = {
  prettier.enable = true;
  eslint.enable = true;
};
```

Typical `justfile` for a Node project:

```just
# Repair formatting across the working tree.
fmt:
    pre-commit run --all-files

# Verify without modifying anything.
lint:
    nix flake check

# Run tests.
test:
    pnpm test

# Build project.
build:
    pnpm build

# Run lint + test.
ci: lint test
```
