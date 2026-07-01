Title: python-kacl
Date: 2026-07-01
Slug: python-kacl
Ecosystem: Python
Tags: keep-a-changelog, python, python-library-cli, validation, pre-commit, release-notes, news-fragments
Tool_URL: https://pypi.org/project/python-kacl/
Tool_Version: 0.7.3
Tool_Status: active
Summary: Python library/CLI for verifying and operating Keep a Changelog files, with pre-commit hooks, stash support, and release helpers — strongest when strict changelog validation matters.

## Overview

`python-kacl` is a Python CLI/library focused on one specific job: keeping a changelog file in a Keep a Changelog-shaped workflow. It can initialize a changelog, verify structure, add entries, release `[Unreleased]` changes, generate links, and stash unreleased changes to avoid merge conflicts.

What makes it interesting is the validation-first posture. Compared with a broader workflow tool such as `keepachangelog-manager-fork`, `python-kacl` is more centered on changelog-file correctness, pre-commit use, and release-oriented helpers around that file.

One important maintenance note up front: the old GitHub repository now points users to GitLab, while the current PyPI metadata and README describe a newer command set than the stale GitHub README. The project appears active, but the canonical home is a little split.

## Installation

```bash
pip install python-kacl
# or with uv:
uv add python-kacl
```

The installed CLI is `kacl-cli`.

## What It Does

- Verifies changelog structure with `kacl-cli verify`, including `--json` output for CI.
- Creates a changelog with `kacl-cli new` or initializes both changelog and config with `kacl-cli init`.
- Adds entries to unreleased sections with `kacl-cli add ... --modify`.
- Releases unreleased changes into a dated version section with `kacl-cli release`.
- Supports auto-generated links, optional git commit/tag steps, and issue-comment integration.
- Provides `stash` support and a pre-commit hook to move unreleased changes out of the main changelog before commits, reducing merge conflicts.
- Includes helper commands such as `current`, `get`, `next`, `link`, `squash`, and `add-comments`.

## Configuration

The project supports a config file and the PyPI README documents a generated `.kacl.yml` produced by `kacl-cli init`. The documented defaults include:

- allowed header titles and version sections
- git commit/tag behavior
- link-generation templates
- issue-tracker integration
- stash-directory settings

That makes setup more explicit than a zero-config parser, but less sprawling than a full release orchestrator. If you need auto-link generation or repository-specific release behavior, config matters; in a quick local probe, `release --auto-link` failed outside a configured git/project context with:

```text
ERROR: Could not determine project url. Update your config or run within a valid git repository
```

## Output Quality

The tool's output is readable Markdown and it is clearly designed to maintain a single human-facing changelog file rather than synthesize prose from commit history.

In a small local probe, this sequence worked:

```bash
kacl-cli new --output-file CHANGELOG.md
kacl-cli add added "Initial public release" --modify
kacl-cli verify
kacl-cli release 0.1.0 --modify
```

Resulting `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.1.0 - 2026-07-01

### Added

- Initial public release
```

`kacl-cli get 0.1.0` then returned the released section cleanly.

The main caveat is format strictness versus the canonical KAC examples used elsewhere in this site: observed output used `## Unreleased` and `## 0.1.0 - ...` without square brackets. The tool still calls this valid KAC, but projects expecting bracketed headings for compatibility with other parsers should check that assumption carefully.

## Ecosystem Fit

`python-kacl` fits Python teams that want changelog validation and release helpers more than a giant release pipeline. The pre-commit hook support is a particularly good fit for repos that want changelog discipline enforced before changes land.

It is less compelling if the team wants:

- fragment-first contributor workflows like Towncrier or Scriv
- a broader KAC workflow surface with tasks, GUI support, and multi-component automation
- commit-derived release notes instead of maintaining a changelog file directly

Its niche is "treat the changelog as a governed artifact and check it aggressively."

## Maintenance Status

- Latest version: **0.7.3**
- Last release: **2026-06-19**
- GitHub stars: **25**
- GitHub repository is not archived and was updated in 2026, but its README now redirects users to GitLab.
- PyPI metadata and README reflect a newer command surface than the old GitHub README.
- GitHub repository: <a href="https://github.com/mschmieder/python-kacl" target="_blank" rel="noopener noreferrer">https://github.com/mschmieder/python-kacl</a>
- PyPI package: <a href="https://pypi.org/project/python-kacl/" target="_blank" rel="noopener noreferrer">python-kacl</a>
- GitLab home: <a href="https://gitlab.com/schmieder.matthias/python-kacl" target="_blank" rel="noopener noreferrer">https://gitlab.com/schmieder.matthias/python-kacl</a>

The project does not look abandoned, but the GitHub/GitLab split adds a bit of friction when you are trying to determine which docs are authoritative.

## Hands-on findings

The review above is grounded in the current PyPI README, GitHub repository metadata, and a direct CLI probe using the published package.

Observed directly:

- `kacl-cli --help` exposes a larger command surface than the old GitHub README suggests, including `init`, `next`, `link`, `squash`, `stash`, and `add-comments`.
- `verify --help` confirms CI-friendly JSON output.
- `release --help` shows git commit/tag options, auto-link support, and an `--allow-no-changes` escape hatch.
- `release --auto-link` needs repo/config context to infer the project URL.
- Plain `release ... --modify` worked cleanly in a local directory and preserved an empty unreleased section for the next cycle.

## Verdict

**Verdict: Situational**

`python-kacl` is a good fit when the priority is **validating and operating a KAC-style changelog file** with CLI and pre-commit tooling. Its verification command, stash workflow, and release helpers make it a credible choice for teams that want changelog correctness enforced in automation.

The caveat is interoperability and project shape. Its observed heading conventions are KAC-adjacent rather than identical to the bracketed form many other tools on this site assume, and the split between GitHub and GitLab makes the documentation story slightly messy. Choose it when strict changelog validation and pre-commit discipline matter more than broad release orchestration.
