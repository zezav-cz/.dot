# Shell scripts

- Start every script with `#!/usr/bin/env bash` followed by `set -euo pipefail` — fail fast on errors, unset variables, and pipe failures rather than silently continuing.
- Lint with `shellcheck` and format with `shfmt`, both enabled as hooks (`shellcheck.enable = true;`, `shfmt.enable = true;`) so `just lint` and `just fmt` cover them.
