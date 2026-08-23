# TypeScript / Node

- Use `prettier` for formatting and `eslint` for linting.
- `package.json` scripts should just call through to the same commands `mise run` uses — don't maintain two separate command surfaces (npm scripts vs mise tasks) that can drift apart.
- Use `pnpm` over `npm` or `yarn` for installs and running scripts.

Typical `mise.toml` task block for a Node project:

```toml
[tools]
node = "22"
pnpm = "9"

[tasks.fmt]
run = "pnpm exec prettier --write ."
description = "Format source"

[tasks.lint]
run = "pnpm exec eslint ."
description = "Run linter"

[tasks.test]
run = "pnpm test"
description = "Run tests"

[tasks.build]
run = "pnpm build"
description = "Build project"

[tasks.ci]
run = ["mise run fmt", "mise run lint", "mise run test"]
description = "Run fmt + lint + test"
```
