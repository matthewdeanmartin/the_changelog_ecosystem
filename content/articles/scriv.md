Title: scriv
Date: 2026-05-31
Slug: scriv
Ecosystem: Python
Tags: keep-a-changelog, news-fragments, python, python-cli, pyproject-config, custom-templates, github-integration
Tool_URL: https://pypi.org/project/scriv/
Tool_Version: 1.8.0
Tool_Status: active
Summary: Changelog management CLI that creates and aggregates changelog fragments into a project changelog.



## Overview

`scriv` is a changelog fragment tool for teams that like the Towncrier idea but want a smaller, direct workflow around a conventional `CHANGELOG.md`. Contributors create short fragments in a directory such as `changelog.d`, and maintainers run `scriv collect` to roll them into the main changelog.

Its personality is pragmatic: it supports Markdown or reStructuredText, reads configuration from common Python project files, and includes commands for creating fragments, collecting them, and publishing GitHub release text.

## Installation

```bash
pip install scriv
# or with uv:
uv add scriv
```

## What It Does

- Creates fragment files with `scriv create`, optionally opening an editor and using branch or author information in the filename.
- Aggregates fragment files into a main changelog with `scriv collect`.
- Reads the version from a literal in `pyproject.toml`, a Python module, a YAML file, a command, or a configured static value.
- Supports standard changelog categories such as Removed, Added, Changed, Deprecated, Fixed, and Security.
- Can render a GitHub release body from the collected changelog using `scriv github-release`.

## Configuration

Scriv can read settings from `setup.cfg`, `tox.ini`, `pyproject.toml`, or `scriv.ini` in the fragment directory. In TOML, settings live under `[tool.scriv]`; on Python 3.11 and newer this is straightforward because TOML parsing is in the standard library.

```toml
[tool.scriv]
format = "md"
changelog = "CHANGELOG.md"
fragment_directory = "changelog.d"
version = "literal: pyproject.toml: project.version"
categories = "Added, Changed, Deprecated, Removed, Fixed, Security"
```

First-run complexity is low to moderate. The fragment directory must exist, and teams should decide on categories and heading style, but the defaults are sensible enough for a small package to adopt quickly.

## Output Quality

Scriv produces compact, readable entries that preserve hand-written fragments. A typical Markdown collection looks like this:

```markdown
<a id='changelog-1.8.0'></a>
## 1.8.0 - 2026-05-31

### Added

- Add stable anchors before generated version sections.

### Fixed

- Keep release-note rendering deterministic when fragments are collected.
```

The output is a little more maintainer-oriented than marketing-polished release notes, but that is usually the right tradeoff for package changelogs. Because fragments are plain Markdown or reStructuredText, humans can still edit the final text.

## Ecosystem Fit

Scriv fits Python projects neatly: it works with `pyproject.toml`, `tox.ini`, and `setup.cfg`, and it does not require adopting a full release automation system. It also travels reasonably well to non-Python projects because its fragment model is file-based rather than package-manager-specific.

Compared with Towncrier, Scriv feels lighter and more direct. Compared with Reno, it is far easier to understand for projects that just want a good changelog file.

## Maintenance Status

- Latest version: **1.8.0**
- Last release: **2025-12-30**
- GitHub stars: **304**
- Appears actively maintained.
- Repository: <a href="https://github.com/nedbat/scriv" target="_blank" rel="noopener noreferrer">https://github.com/nedbat/scriv</a>

The documentation covers current configuration files, TOML version lookups, fragment templates, Markdown anchors, and GitHub release rendering.

## Verdict

**Verdict: Recommended**

Scriv is a strong default for Python projects that want news fragments without a large release-note framework. Choose it when the goal is a tidy `CHANGELOG.md`, simple contributor instructions, and enough configuration to match local style without turning release notes into a subsystem.
