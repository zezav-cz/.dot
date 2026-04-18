# Adding a new stow package

## 1. Create the directory structure

Mirror the home directory layout under a new subdirectory of `stow/`:

```bash
mkdir -p stow/newpkg/.config/newpkg/
```

## 2. Add config files

Place your config files inside the directory tree. The path relative to the
package root must match the desired path relative to `~/`:

```
stow/newpkg/.config/newpkg/config.toml  -->  ~/.config/newpkg/config.toml
```

## 3. Register the package

Open `installer/config.py` and add the package name to one of:

- **`STOW_PACKAGES`** -- for normal packages (stow may create directory
  symlinks via folding).
- **`STOW_NO_FOLDING`** -- for packages where the parent directory is shared
  with non-stow files (e.g., `my-scripts` installs into `~/.local/bin/` which
  also contains files from other sources).

## 4. Test with dry-run

```bash
# Preview what stow would do (run from repo root):
stow -d stow -t ~ -nv newpkg

# If using --no-folding:
stow -d stow -t ~ -nv newpkg --no-folding
```

Check that the symlinks point where you expect and that there are no conflicts
with existing files.

## 5. Apply

```bash
# Via the installer:
python3 install.py --only stow

# Or directly (from repo root):
stow -d stow -t ~ -v newpkg
```

---

## Adding a new installer step

If you need a step beyond stowing configs (e.g., downloading a binary,
enabling a service):

1. Create a new module in `installer/steps/`, following the naming convention
  `sNN_name.py` (e.g., `s08_services.py`).
2. Implement `run_step(dry_run: bool = False) -> None`. Use `installer.cmd`
  for subprocess calls and respect the `dry_run` parameter.
3. Import the module in `installer/steps/__init__.py` and add it to the
  `STEPS` list at the appropriate position (see example below).
4. Test: `python3 install.py --only services --dry-run`

Example `__init__.py` addition:

```python
from installer.steps import s08_services

STEPS = [
  ...
  ("services", s08_services),
]
```
