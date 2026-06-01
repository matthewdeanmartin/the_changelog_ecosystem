Title: towncrier
Date: 2026-05-31
Slug: towncrier
Ecosystem: Python
Tags: keep-a-changelog, news-fragments, python, python-cli, release-notes, custom-templates, ci-cd
Tool_URL: https://pypi.org/project/towncrier/
Tool_Version: 25.8.0
Tool_Status: active
Summary: Building newsfiles for your project via news fragments



## Overview

`towncrier` is the canonical Python news-fragment tool: each user-visible change is written as a small file alongside the code change, then collected into release notes when the project cuts a release. It is strongest for libraries and frameworks where contributors should explain the user impact before the maintainer is assembling the final changelog.

The tool distinguishes itself by being mature, configurable, and strict enough to work as a release gate. It is less about reading git history after the fact and more about making release-note writing part of the contribution workflow.

## Installation

```bash
pip install towncrier
# or with uv:
uv add towncrier
```

## What It Does

- Creates individual news fragments such as `123.feature` or `456.bugfix`, usually stored in a `newsfragments` directory.
- Collects fragments into a project news file, commonly `NEWS.rst`, `NEWS.md`, or `CHANGELOG.md`.
- Supports Markdown and reStructuredText templates, with a Markdown-specific release-note start marker when the output file ends in `.md`.
- Lets projects define fragment categories such as features, bug fixes, removals, docs, or project-specific types.
- Provides `towncrier check` so CI can reject pull requests that forget a required user-facing note.

## Configuration

Towncrier reads TOML configuration from `pyproject.toml` or `towncrier.toml` under `[tool.towncrier]`. A minimal Python package can start with just the package name; Towncrier can infer the display name and version from installed package metadata or a package `__version__`.

```toml
[tool.towncrier]
package = "myproject"
filename = "CHANGELOG.md"
directory = "newsfragments"
issue_format = "[#{issue}](https://github.com/example/myproject/issues/{issue})"

[[tool.towncrier.type]]
directory = "feature"
name = "Features"
showcontent = true

[[tool.towncrier.type]]
directory = "bugfix"
name = "Bug Fixes"
showcontent = true
```

First-run setup is moderate: you need to pick a fragment directory, decide whether output is Markdown or reStructuredText, and agree on fragment categories. After that, contributor ergonomics are simple: add a short fragment file with the change.

## Output Quality

Towncrier output is intentionally human-facing, not a raw commit log. A Markdown release can look like this:

```markdown
## My Project 1.4.0 (2026-05-31)

### Features

- Add TOML configuration discovery for plugin packages. [#184](https://github.com/example/myproject/issues/184)

### Bug Fixes

- Preserve explicit changelog links when rebuilding release notes. [#191](https://github.com/example/myproject/issues/191)
```

The quality depends on fragment discipline. If contributors write good fragments, Towncrier produces clean release notes with stable categories and issue links; if they write vague fragments, it will faithfully preserve the vagueness.

## Ecosystem Fit

Towncrier feels very native to Python packaging. It lives comfortably in `pyproject.toml`, works with `pip`, `uv`, `tox`, `nox`, and pre-commit-style checks, and it is already familiar in established Python projects that care about release notes as documentation.

Its model is especially good for contributor-heavy open source projects. Small applications with one maintainer may find the fragment ceremony heavier than a direct `CHANGELOG.md` edit.

## Maintenance Status

- Latest version: **25.8.0**
- Last release: **2025-08-30**
- GitHub stars: **899**
- Appears actively maintained.
- Repository: <a href="https://github.com/twisted/towncrier" target="_blank" rel="noopener noreferrer">https://github.com/twisted/towncrier</a>

Towncrier has a long maintenance history and current documentation for modern `pyproject.toml` configuration, custom fragment types, Markdown output, and CI checks.

## Verdict

**Verdict: Recommended**

Use Towncrier when a Python project wants contributors to record user-visible changes as part of the patch, especially for libraries, frameworks, and projects with many external contributors. It is not the lightest option, but it is the Python baseline for news-fragment workflows and belongs near the top of any changelog-tool shortlist.
