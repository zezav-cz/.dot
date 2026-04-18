#!/usr/bin/env python3
"""Bootstrap script for a fresh Linux system.

Usage:
    python3 install.py              # run all steps
    python3 install.py --only stow  # run a single step
    python3 install.py --skip repos packages  # skip heavy steps
    python3 install.py --dry-run    # preview without executing
    python3 install.py --list       # list available steps
    python3 install.py -v           # verbose output
"""

import argparse
import logging
import os
import sys

from installer import cmd
from installer.distro import Distro
from installer.distro import detect as detect_distro
from installer.errors import InstallerError
from installer.log import setup as setup_logging
from installer.steps import STEP_NAMES, STEPS

REQUIRED_TOOLS = ["git", "wget", "stow"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="System bootstrap installer for dotfiles and packages.",
    )
    parser.add_argument(
        "--only",
        nargs="+",
        metavar="STEP",
        help=f"Run only these steps. Available: {', '.join(STEP_NAMES)}",
    )
    parser.add_argument(
        "--skip",
        nargs="+",
        metavar="STEP",
        default=[],
        help="Skip these steps.",
    )
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="Print commands without executing them.",
    )
    parser.add_argument(
        "-l",
        "--list",
        action="store_true",
        help="List available steps and exit.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Show subprocess output.",
    )
    return parser.parse_args()


def preflight(dry_run: bool) -> Distro:
    """Run pre-flight checks, return detected distro."""
    distro = detect_distro()
    logging.info(f"Detected distro: {distro.value}")

    if distro == Distro.UNKNOWN and not dry_run:
        logging.warning("Unknown distro — some steps may fail.")

    # Check required tools
    missing = [t for t in REQUIRED_TOOLS if not cmd.is_installed(t)]
    if missing:
        logging.warning(f"Missing tools: {', '.join(missing)} — some steps may fail.")

    # Check sudo access (skip in dry-run)
    if not dry_run:
        result = cmd.run("sudo", "-n", "true", check=False, capture=True)
        if result.returncode != 0:
            logging.warning(
                "sudo requires a password — you may be prompted during installation."
            )

    return distro


def main() -> None:
    args = parse_args()

    if args.list:
        print("Available steps:")
        for name, mod in STEPS:
            doc = (mod.run_step.__doc__ or mod.__doc__ or "").strip().split("\n")[0]
            print(f"  {name:12s}  {doc}")
        sys.exit(0)

    # Validate step names in --only and --skip
    for name in (args.only or []) + args.skip:
        if name not in STEP_NAMES:
            logging.error(f"Unknown step: '{name}'. Available: {', '.join(STEP_NAMES)}")
            sys.exit(1)

    # Configure logging and global flags
    setup_logging(verbose=args.verbose)
    cmd.DRY_RUN = args.dry_run

    # Work from the dotfiles directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    distro = preflight(args.dry_run)

    logging.info("Starting installation")
    if args.dry_run:
        logging.warning("Dry-run mode — no changes will be made.")

    succeeded = []
    failed = []
    skipped = []

    try:
        for name, mod in STEPS:
            if args.only and name not in args.only:
                continue
            if name in args.skip:
                logging.info(f"Skipping step: {name}")
                skipped.append(name)
                continue

            logging.info(f"{'=' * 20} {name} {'=' * 20}")
            mod.run_step(dry_run=args.dry_run, distro=distro)
            succeeded.append(name)
    except InstallerError as e:
        logging.error(str(e))
        sys.exit(1)

    # Summary
    logging.info("=" * 50)
    logging.info("Summary:")
    if succeeded:
        logging.info(f"  Succeeded: {', '.join(succeeded)}")
    if skipped:
        logging.info(f"  Skipped:   {', '.join(skipped)}")
    if failed:
        logging.error(f"  Failed:    {', '.join(failed)}")
    if not failed:
        logging.info("All done!")
    else:
        logging.warning(f"Finished with {len(failed)} failure(s).")


if __name__ == "__main__":
    main()
