"""Step registry — ordered list of all installation steps.

Each step module must define:
    run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN) -> None
"""

from installer.steps import (
    s00_update,
    s01_repos,
    s02_packages,
    s03_shell,
    s04_apps,
    s05_fonts,
    s06_stow,
    s07_vnotes,
    s08_mcp,
)

# Each entry: (name used in --only/--skip, module with run_step())
STEPS = [
    ("update", s00_update),
    ("repos", s01_repos),
    ("packages", s02_packages),
    ("shell", s03_shell),
    ("apps", s04_apps),
    ("fonts", s05_fonts),
    ("stow", s06_stow),
    ("vnotes", s07_vnotes),
    ("mcp", s08_mcp),
]

STEP_NAMES = [name for name, _ in STEPS]
