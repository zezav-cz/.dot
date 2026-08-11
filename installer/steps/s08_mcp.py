"""Register Claude Code MCP servers in ~/.claude.json."""

import json
import logging
import os
import tempfile

from installer.config import CLAUDE_CONFIG, MCP_SERVERS
from installer.distro import Distro


def run_step(dry_run: bool = False, distro: Distro = Distro.UNKNOWN, **kw) -> None:
    config = {}
    if CLAUDE_CONFIG.is_file():
        config = json.loads(CLAUDE_CONFIG.read_text())

    servers = config.setdefault("mcpServers", {})
    # only add missing entries — never clobber manually tweaked servers
    missing = {name: spec for name, spec in MCP_SERVERS.items() if name not in servers}

    for name in MCP_SERVERS:
        if name not in missing:
            logging.info(f"MCP server '{name}' already registered. Skipping.")

    if not missing:
        logging.info("All MCP servers already registered.")
        return

    if dry_run:
        for name in missing:
            logging.info(f"[dry-run] Would add MCP server '{name}' -> {CLAUDE_CONFIG}")
        return

    servers.update(missing)
    # atomic replace so a crash can't truncate Claude Code's main config
    fd, tmp_path = tempfile.mkstemp(dir=CLAUDE_CONFIG.parent, suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as tmp:
            json.dump(config, tmp, indent=2)
        os.replace(tmp_path, CLAUDE_CONFIG)
    except BaseException:
        os.unlink(tmp_path)
        raise

    for name in missing:
        logging.info(f"Registered MCP server '{name}'.")
