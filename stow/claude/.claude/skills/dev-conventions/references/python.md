# Python

Package manager is **uv**, exclusively — never pip, pipenv, or poetry. Declare the Python version in `mise.toml`:

```toml
[tools]
python = "3.12"
uv = "latest"
```

## Python projects (multi-file)

```sh
uv init          # new project
uv add <pkg>     # add a dependency
uv sync          # install from lockfile
uv run <cmd>     # run inside the managed venv
```

Lint/format with `ruff` (and `mypy` for typing), wired into mise tasks:

```toml
[tasks.fmt]
run = "uv run ruff format ."

[tasks.lint]
run = "uv run ruff check . && uv run mypy ."

[tasks.test]
run = "uv run pytest"

[tasks.ci]
run = ["mise run fmt", "mise run lint", "mise run test"]
```

## Standalone Python scripts

A single-file script carries its own dependency metadata as a PEP 723 inline header and uses the uv shebang, so it's directly executable with no project setup at all:

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

Rules:
- First line is always `#!/usr/bin/env -S uv run --script` — this is what makes the script self-executing.
- The `# /// script` block immediately follows, with `requires-python` and `dependencies`.
- No `requirements.txt` or `pyproject.toml` needed alongside the script.
- Make it executable (`chmod +x script.py`) and run it directly (`./script.py` or `uv run script.py`).

Reach for this pattern for one-off utility scripts; reach for a full `uv init` project once there's more than one file or the script needs to be imported elsewhere.
