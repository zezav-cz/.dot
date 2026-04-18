"""Colored logging using the standard logging module."""

import logging
import sys

_GREEN = "\033[32m"
_RED = "\033[31m"
_YELLOW = "\033[33m"
_GRAY = "\033[90m"
_RESET = "\033[0m"

_COLORS = {
    logging.DEBUG: _GRAY,
    logging.INFO: _GREEN,
    logging.WARNING: _YELLOW,
    logging.ERROR: _RED,
}


class _ColorFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        color = _COLORS.get(record.levelno, _RESET)
        prefix = f"{color}[{record.levelname}]{_RESET}"
        return f"{prefix} {record.getMessage()}"


def setup(verbose: bool = False) -> None:
    """Configure the root logger. Call once at startup."""
    level = logging.DEBUG if verbose else logging.INFO
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(_ColorFormatter())
    logging.root.handlers.clear()
    logging.root.addHandler(handler)
    logging.root.setLevel(level)
