#!/usr/bin/env bash

set -e

uv run .github/scripts/repo_structure.py
uv run .github/scripts/shell_files.py
uv run .github/scripts/utility_scripts.py
