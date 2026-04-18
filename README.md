# Dotfiles

Personal setup repository for bootstrapping Fedora Sway Spin installations.

## Overview

This repository contains my system configuration files and an automated setup script for quickly configuring a fresh Fedora Sway environment.

## What It Does

- Installs essential packages and tools
- Uses GNU Stow to symlink configuration files to their proper locations
- Sets up development environment and applications

## Usage

Clone this repository and run the installer:

```bash
git clone <repository-url> ~/.dot
cd ~/.dot
python3 install.py
```

See `CLAUDE.md` for flags (`--dry-run`, `--only`, `--skip`, `--list`) and `doc/` for architecture notes.

## Structure

Configuration files are organized by application/category and managed with GNU Stow for easy deployment and maintenance.
