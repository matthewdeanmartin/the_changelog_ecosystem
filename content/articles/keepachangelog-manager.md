Title: keepachangelog-manager-fork
Date: 2026-06-02
Slug: keepachangelog-manager
Ecosystem: Python
Tags: keep-a-changelog, python, python-cli, validation, release-notes, github-integration, ci-cd, multi-component, hands-on
Tool_URL: https://pypi.org/project/keepachangelog-manager-fork/
Tool_Version: 5.2.0
Tool_Status: active
Experiment: examples/python/keepachangelog-manager/
Summary: Actively maintained Keep a Changelog workflow CLI with task staging, fragments, backfill, validation/autofix, release automation, and a GUI — especially strong for KAC-native maintainer workflows.



## Overview

`keepachangelog-manager-fork` is the maintained fork of `keepachangelog-manager`, a Python CLI for teams that want a full workflow around a Keep a Changelog-style `CHANGELOG.md`. It covers creation, editing, validation, release promotion, version calculation, task staging, fragment collection, backfill, and release publishing.

This distinction matters: the original `tomtom-international/keepachangelog-manager` project is archived and unsupported, and should be treated as **not recommended** for new use. The maintained fork lives at `matthewdeanmartin/keepachangelog-manager`, is published on PyPI as `keepachangelog-manager-fork`, and has continued feature work focused on usability and release automation.

The fork is more workflow-oriented than the `keepachangelog` library and more capable than the archived upstream package. It is aimed at maintainers who want a KAC-native workflow tool rather than just a parser or a commit-to-markdown generator.

A reproducible hands-on experiment for this tool lives in [`examples/python/keepachangelog-manager/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/keepachangelog-manager). The real output shown later in this article comes from that run.

## Installation

```bash
pip install keepachangelog-manager-fork
# or with uv:
uv add keepachangelog-manager-fork
```

The CLI entry point is `changelogmanager`.

## What It Does

- Creates and validates Keep a Changelog files, including `validate --fix` for safe structural cleanup.
- Adds, edits, lists, and removes `[Unreleased]` entries under the standard KAC change types.
- Computes future versions for SemVer, PEP 440, and CalVer projects, then promotes `[Unreleased]` into a dated release.
- Syncs version strings outside the changelog with `release --bump-versions`.
- Stages future release notes in `TASKS.md`, `changelog.d/`, or richer `tickets/` fragments, then promotes them into `[Unreleased]`.
- Backfills changelog history from local tags and commits, GitHub Releases, merged GitHub PRs, and PyPI history.
- Exports changelog content to JSON and HTML.
- Includes GitHub and GitLab release automation commands plus a Tkinter GUI for editing, backfill, release, and batch component workflows.

## Configuration

The default workflow can operate on a single `CHANGELOG.md` with command-line options such as `--input-file`. For repositories with multiple components, the project can define config in `changelogmanager.toml` or `pyproject.toml`, select a component at runtime, and give each component its own changelog, tasks file, and fragment defaults.

```toml
[[components]]
name = "service"
changelog = "service/CHANGELOG.md"

[[components]]
name = "client"
changelog = "client/CHANGELOG.md"
tasks_file = "client/TASKS.md"
```

```bash
changelogmanager --config changelogmanager.toml --component client validate
changelogmanager --input-file CHANGELOG.md release --override-version 1.4.0 --yes
```

First-run setup is low for a single changelog and moderate for multi-component repositories. The command surface is larger than a tiny parser library, but it is explicit and scriptable, which makes the tool straightforward to wire into CI, pre-commit, or a local maintainer workflow.

## Output Quality

The output remains standard Keep a Changelog Markdown rather than a generated commit digest. That is the point: this tool treats the changelog as a first-class maintained artifact. The current codebase also adds repair-oriented validation, structured task/fragment promotion, and JSON/HTML export, so it can support both human-maintained prose and automation around that prose.

## Ecosystem Fit

`keepachangelog-manager-fork` fits Python projects that prefer a command-oriented release process and a committed changelog. It can be used from `uv run`, `tox`, pre-commit, or CI jobs, and its release commands, version calculation, and GitHub/GitLab integrations make it practical for automated release pipelines.

Its strongest niche is the team that actually wants to stay inside the Keep a Changelog model: explicit `[Unreleased]` editing, KAC-style task tracking, optional fragments, backfill into a real changelog file, and release promotion from that file. In the current site inventory, it is the clearest fit for a KAC-native maintainer workflow rather than a pure commit-log pipeline.

## Maintenance Status

- Latest version: **5.2.0**
- Last release: **2026-05-31**
- GitHub stars: **0**
- Appears actively maintained.
- Maintained fork repository: <a href="https://github.com/matthewdeanmartin/keepachangelog-manager" target="_blank" rel="noopener noreferrer">https://github.com/matthewdeanmartin/keepachangelog-manager</a>
- PyPI package: <a href="https://pypi.org/project/keepachangelog-manager-fork/" target="_blank" rel="noopener noreferrer">keepachangelog-manager-fork</a>
- Archived upstream: <a href="https://github.com/tomtom-international/keepachangelog-manager" target="_blank" rel="noopener noreferrer">tomtom-international/keepachangelog-manager</a>

The current fork documents CLI commands for create, add, edit, remove, validate/autofix, version calculation, release, JSON/HTML export, tasks, fragments, backfill, commit-message linting, rewrite planning, GitHub/GitLab automation, GUI flows, and multi-component configuration. The archived upstream has fewer features and should be treated as unsupported historical context with an **Avoid / not recommended** posture, not as a viable package choice.

---

## Hands-on findings

A reproducible experiment lives in [`examples/python/keepachangelog-manager/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/keepachangelog-manager). All output below is **real**, captured from that run — not hypothetical. This review uses the maintained fork (PyPI: `keepachangelog-manager-fork`), not the archived original.

### What I actually ran

Container base image: `python:3.12-slim`. Tool: `keepachangelog-manager-fork 5.2.0` (installed via `pip install keepachangelog-manager-fork==5.2.0`); CLI entry point `changelogmanager`. The scenario drove a restaurant tip-calculator app through four life-cycle stages:

1. **No changelog** — v1.0.0 code committed, no `CHANGELOG.md` yet.
2. **Changelog created** — `changelogmanager create` produced the skeleton; `changelogmanager add` added the v1.0.0 entry; `changelogmanager release --override-version 1.0.0 --yes` promoted it.
3. **Changelog updated** — `changelogmanager add` recorded the v2.0.0 feature under `[Unreleased]`.
4. **Release v2.0.0 and v3.0.0** — `changelogmanager release --override-version <version> --yes` for each.

### Real output

`CHANGELOG.md` after `create` + `add` (Stage 2 mid-point):

```markdown
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Compute the tip and total for a single restaurant bill.
```

`CHANGELOG.md` after the v2.0.0 release (Stage 4a):

```markdown
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-06-02
### Added
- Split the bill evenly among a fixed number of diners.

## [1.0.0] - 2026-06-02
### Added
- Compute the tip and total for a single restaurant bill.
```

Final `CHANGELOG.md` after v3.0.0 (Stage 4b):

```markdown
## [3.0.0] - 2026-06-02
### Added
- Split the bill unevenly using per-person weights; output now lists each diner's share.

## [2.0.0] - 2026-06-02
### Added
- Split the bill evenly among a fixed number of diners.

## [1.0.0] - 2026-06-02
### Added
- Compute the tip and total for a single restaurant bill.
```

`release` stdout: `Released 2.0.0` — a clean, one-line confirmation. Note the released file contains **no** `[Unreleased]` section and **no** comparison link definitions.

### Current strengths

- **It now covers the full KAC maintainer lifecycle, not just `create`/`add`/`release`.** Tasks, fragments, richer ticket assembly, backfill, version calculation, version syncing, and release publishing make it broader than the earlier snapshot in this article.
- **`validate --fix` materially improves day-to-day usability.** The current codebase can repair many safe structural issues, normalize headings and dates, deduplicate entries, and restore missing link references that strict KAC workflows care about.
- **The task workflow is distinctive.** `TASKS.md`, `tickets/`, and fragment support give teams a way to stage work in KAC categories before promoting it into `[Unreleased]`. That is a real differentiator versus parser-only tools.
- **The automation surface is substantial.** `version`, `release --bump-versions`, GitHub/GitLab release commands, commit-message linting, and rewrite planning make it useful in CI as well as on a maintainer laptop.
- **It scales beyond one changelog file.** Multi-component configuration and the GUI make it viable for repos where a single `CHANGELOG.md` is not the whole story.

### Caveats to know

- **The workflow is intentionally more opinionated than a tiny parser library.** Teams that only want `show`/`release` on an already hand-maintained changelog may prefer a smaller tool.
- **Released-only files are a supported shape.** After `release`, the changelog does not keep an empty `[Unreleased]` section by default; the next `add`, fragment collection, or task promotion recreates working state. Teams that want a permanently present empty `[Unreleased]` section should account for that in their local conventions.
- **This is not the best fit for commit-derived release-note generation.** If the desired workflow is "derive everything from Conventional Commits and publish automatically," tools such as `git-cliff`, `semantic-release`, or `release-please` remain better fits.

### Docs vs. reality

The original description correctly identified the fork as the maintained package, but it understated how much functionality has been added since the upstream split. The current docs and source now cover task promotion, fragment collection, ticket assembly, backfill from several sources, `validate --fix`, version syncing, HTML export, commit-message linting, rewrite planning, GitHub/GitLab automation, and GUI workflows. That broader scope is central to how the tool should be positioned.

## Verdict

**Verdict: Recommended with caveats**

`keepachangelog-manager-fork` is a strong recommendation for teams that want to stay inside a Keep a Changelog workflow instead of replacing it with commit-derived prose. It creates a real maintainer loop around KAC files: stage work, validate and repair structure, compute the next version, promote a release, and publish the result.

It is especially compelling when you want KACL-style task management or promotion into `[Unreleased]`, because that workflow is rare in the rest of the ecosystem. The caveat is scope: if your team wants a minimal parser or a purely Conventional-Commits-driven release bot, this is more tool than you need and a different philosophy than you want. The archived non-fork upstream should not be selected for new work.
