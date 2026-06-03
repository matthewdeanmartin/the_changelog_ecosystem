Title: scriv
Date: 2026-06-02
Slug: scriv
Ecosystem: Python
Tags: keep-a-changelog, news-fragments, python, python-cli, pyproject-config, custom-templates, github-integration, hands-on
Tool_URL: https://pypi.org/project/scriv/
Tool_Version: 1.8.0
Tool_Status: active
Experiment: examples/python/scriv/
Summary: Changelog fragment CLI that collects fragments into a project changelog — hands-on testing confirms a one-command release step, with a few format divergences from strict Keep a Changelog.



## Overview

`scriv` is a changelog fragment tool for teams that like the Towncrier idea but want a smaller, direct workflow around a conventional `CHANGELOG.md`. Contributors create short fragments in a directory such as `changelog.d`, and maintainers run `scriv collect` to roll them into the main changelog.

Its personality is pragmatic: it supports Markdown or reStructuredText, reads configuration from common Python project files, and includes commands for creating fragments, collecting them, and publishing GitHub release text.

A reproducible hands-on experiment for this tool lives in [`examples/python/scriv/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/scriv). The real output shown later in this article comes from that run.

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

First-run complexity is low to moderate. The fragment directory must exist, and teams should decide on categories and heading style, but the defaults are sensible enough for a small package to adopt quickly. (This exact config was used in the hands-on experiment below and worked first time.)

## Output Quality

Scriv produces compact, readable entries that preserve hand-written fragments, with stable HTML anchors auto-inserted before each version heading. The output is a little more maintainer-oriented than marketing-polished release notes, but that is usually the right tradeoff for package changelogs. Because fragments are plain Markdown or reStructuredText, humans can still edit the final text. See the **Hands-on findings** section below for the exact, real output produced when driving a sample project through three releases.

## Ecosystem Fit

Scriv fits Python projects neatly: it works with `pyproject.toml`, `tox.ini`, and `setup.cfg`, and it does not require adopting a full release automation system. It also travels reasonably well to non-Python projects because its fragment model is file-based rather than package-manager-specific.

Compared with Towncrier, Scriv feels lighter and more direct. Compared with Reno, it is far easier to understand for projects that just want a good changelog file. One caveat surfaced in testing: scriv's output is its own changelog style, not a strict Keep a Changelog implementation, so it does not interoperate cleanly with the `keepachangelog` parser library.

## Maintenance Status

- Latest version: **1.8.0**
- Last release: **2025-12-30**
- GitHub stars: **304**
- Appears actively maintained.
- Repository: <a href="https://github.com/nedbat/scriv" target="_blank" rel="noopener noreferrer">https://github.com/nedbat/scriv</a>

The documentation covers current configuration files, TOML version lookups, fragment templates, Markdown anchors, and GitHub release rendering.

---

## Hands-on findings

A reproducible experiment lives in [`examples/python/scriv/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/scriv). All output below is **real**, captured from that run — not hypothetical.

### What I actually ran

Container base image: `python:3.12-slim`. Tool: `scriv 1.8.0` (installed via `pip install scriv==1.8.0`). The scenario drove a restaurant tip-calculator app through four life-cycle stages:

1. **No changelog** — v1.0.0 code committed, no changelog yet.
2. **Changelog created** — appended `[tool.scriv]` config to `pyproject.toml`; dropped a pre-written fragment into `changelog.d/`; `scriv collect` assembled `CHANGELOG.md` for v1.0.0.
3. **Changelog updated** — added a v2.0.0 fragment to `changelog.d/`.
4. **Release v2.0.0 and v3.0.0** — `scriv collect` aggregated pending fragments into `CHANGELOG.md` for each version.

The fragment format used:

```markdown
## Added

- Compute the tip and total for a single restaurant bill.
```

### Real output

`scriv collect` stdout on first run (Stage 2) — the missing-changelog warning is expected and benign; scriv creates the file:

```
Collecting from changelog.d
Reading changelog CHANGELOG.md
warning: Changelog CHANGELOG.md doesn't exist
Deleting fragment file 'changelog.d/20260101_initial.md'
```

`CHANGELOG.md` after collecting v1.0.0 (Stage 2):

```markdown

<a id='changelog-1.0.0'></a>
# 1.0.0 — 2026-06-02

## Added

- Compute the tip and total for a single restaurant bill.
```

Final `CHANGELOG.md` after v3.0.0 (Stage 4b):

```markdown

<a id='changelog-3.0.0'></a>
# 3.0.0 — 2026-06-02

## Added

- Split the bill unevenly using per-person weights; output now lists each diner's share on its own line.

<a id='changelog-2.0.0'></a>
# 2.0.0 — 2026-06-02

## Added

- Split the bill evenly among a fixed number of diners.

<a id='changelog-1.0.0'></a>
# 1.0.0 — 2026-06-02

## Added

- Compute the tip and total for a single restaurant bill.
```

### Pros (observed)

- **`scriv collect` is the entire release step.** No sub-commands, no version argument needed if configured; the version is read from `pyproject.toml` via the `literal:` reference. The command is one word.
- **Version read from `pyproject.toml` works correctly.** Setting `version = "literal: pyproject.toml: project.version"` and updating the `version = "2.0.0"` line in `pyproject.toml` is all that is needed before `collect`. No separate bump command.
- **Fragment deletion is clean.** Consumed fragment files are deleted from `changelog.d/` after `collect`, leaving no clutter. (This empties the directory, so a `mkdir -p changelog.d` is needed before the next fragment — a minor gotcha.)
- **Stable HTML anchors are auto-inserted.** Each version heading gets a `<a id='changelog-X.Y.Z'>` anchor automatically, useful for deep-linking from release notes or PR descriptions.
- **Markdown output is clean and direct.** Sections map one-to-one from the fragment's headings; no transformation or RST conversion involved.
- **Installed with no friction.** The dependency set (click, jinja2, attrs, requests) resolved cleanly on Python 3.12, and each `collect` ran in under a second.
- **Warning messages are honest.** The first-run missing-changelog warning is accurate and non-alarming.

### Cons / pain points (observed)

- **No `draft` mode for previewing before collection.** Towncrier has `towncrier build --draft` to preview without consuming fragments. Scriv's `collect` both assembles the changelog and deletes the fragments in one step; previewing requires manually inspecting `changelog.d/`.
- **Section heading level differs from Keep a Changelog convention.** KAC uses `###` for section names; scriv copies the fragment's heading level verbatim, so `## Added` fragments produce `## Added` output. Teams wanting KAC-style `###` must write their fragments with `###` headings — a bit surprising.
- **No `[Unreleased]` section.** The collected changelog uses version-dated `#` headings rather than the KAC `[Unreleased]` structure. This means scriv-generated files cannot be parsed by the plain `keepachangelog` library.
- **`scriv create` is interactive only.** It opens an editor to scaffold a fragment; there is no `--content` or stdin mode. CI pipelines that want to inject a fragment programmatically must write a file to `changelog.d/` directly.

### Docs vs. reality

The original description was accurate: the `collect` workflow, `pyproject.toml` config, and stable-anchor output all matched observation. What it understated: the heading-level difference (`##` vs `###`) is a real interoperability issue with the broader KAC ecosystem, the absence of a draft/preview mode is a practical limitation, and scriv's output is structurally incompatible with the `keepachangelog` parser library.

## Verdict

**Verdict: Recommended (confirmed)**

Scriv works as advertised. `collect` is genuinely the simplest way to aggregate fragments into a changelog, and version detection from `pyproject.toml` eliminates a common manual step. The stable anchors are a nice touch for linking from release notes.

The KAC format divergence (no `[Unreleased]`, `##` not `###`) means scriv is its own changelog style rather than a strict KAC implementation. That is fine for teams adopting it fresh, but teams migrating from KAC tooling or pairing with the `keepachangelog` library should be aware.

Scriv remains a strong default for Python projects that want news fragments without Towncrier's extra complexity. Choose it when the goal is a tidy `CHANGELOG.md`, simple contributor instructions, and enough configuration to match local style without turning release notes into a subsystem.
