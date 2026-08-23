# Shell scripts

- Start every script with `#!/usr/bin/env bash` followed by `set -euo pipefail` — fail fast on errors, unset variables, and pipe failures rather than silently continuing.
- Lint with `shellcheck`, wired in as (or as part of) the project's `mise run lint` task.
