Title: keepachangelog-manager
Date: 2026-05-31
Slug: keepachangelog-manager
Ecosystem: Python
Tool_URL: https://pypi.org/project/keepachangelog-manager/
Tool_Version: 0.1.0
Tool_Status: active
Summary: A Python CLI for managing Keep a Changelog format files — validation, entry management, and release automation.

## Overview

`keepachangelog-manager` is a Python tool that implements the
[Keep a Changelog](https://keepachangelog.com/) specification. It gives you a CLI for
adding changelog entries, validating the format, and automating version bumps and releases.

## Installation

```bash
pip install keepachangelog-manager
# or with uv:
uv add keepachangelog-manager
```

## What It Does

- Validates `CHANGELOG.md` files against the Keep a Changelog spec
- Adds structured entries (Added, Changed, Fixed, Removed, etc.)
- Bumps version and marks a release
- Integrates with CI for release automation

## Configuration

Minimal — works out of the box with a standard `CHANGELOG.md`. Optional configuration
via `pyproject.toml`.

## Output Quality

Produces well-formed Keep a Changelog output. The format is predictable and diff-friendly.

## Ecosystem Fit

Feels native to the Python toolchain. Works well alongside `uv`, `hatch`, or plain `pip`.

## Maintenance Status

Actively maintained as of May 2026.

## Verdict

**Recommended** for Python projects following the Keep a Changelog convention.
Simple, spec-compliant, and CI-friendly.
