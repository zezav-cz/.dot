# Python

Package manager is **uv**, exclusively — never pip, pipenv, or poetry. Python and uv come from the devshell:

```nix
devShells.default = pkgs.mkShellNoCC {
  packages = [
    pkgs.python3
    pkgs.uv
    pkgs.just
  ];
};
```

## Python projects (multi-file)

```sh
uv init          # new project
uv add <pkg>     # add a dependency
uv sync          # install from lockfile
uv run <cmd>     # run inside the managed venv
```

Lint/format with `ruff` (and `mypy` for typing) as hooks, so they are defined once and checked on every commit:

```nix
hooks = {
  ruff.enable = true;
  ruff-format.enable = true;
  mypy.enable = true;
};
```

```just
# Repair formatting across the working tree.
fmt:
    pre-commit run --all-files

# Verify without modifying anything.
lint:
    nix flake check

# Run tests.
test:
    uv run pytest

# Run lint + test.
ci: lint test
```

## Standalone Python scripts

In a Nix project, a script gets its dependencies from the devshell's `python3.withPackages` and uses a plain shebang:

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

Make it executable (`chmod +x scripts/<name>`) and drop the `.py` extension for repo tasks, so `just` recipes read cleanly. Outside the devshell the imports will fail — that is the trade for having every dependency locked.

The PEP 723 inline header with the uv shebang remains the right pattern only for a script that must run outside any project, such as a one-off utility in `~/bin`:

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

Rules for that standalone case:
- First line is always `#!/usr/bin/env -S uv run --script` — this is what makes the script self-executing.
- The `# /// script` block immediately follows, with `requires-python` and `dependencies`.
- No `requirements.txt` or `pyproject.toml` needed alongside the script.
- Make it executable (`chmod +x script.py`) and run it directly (`./script.py` or `uv run script.py`).

Reach for this pattern for one-off utility scripts; reach for a full `uv init` project once there's more than one file or the script needs to be imported elsewhere.
