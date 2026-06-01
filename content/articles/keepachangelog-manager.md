Title: keepachangelog-manager
Date: 2026-05-31
Slug: keepachangelog-manager
Ecosystem: Python
Tags: keep-a-changelog, python, python-cli, validation, release-notes, github-integration, ci-cd, multi-component
Tool_URL: https://pypi.org/project/keepachangelog-manager/
Tool_Version: 4.0.0
Tool_Status: active
Summary: CLI for managing Keep a Changelog format files.



## Overview

`keepachangelog-manager` is a Python CLI for teams that want a structured command-line workflow around a Keep a Changelog-style `CHANGELOG.md`. It can create changelogs, add entries, validate format, export JSON, promote unreleased changes into a release, and help publish GitHub release notes.

The tool is more workflow-oriented than the `keepachangelog` library. It is aimed at maintainers who want a CLI that enforces changelog hygiene rather than an importable parser alone.

## Installation

```bash
pip install keepachangelog-manager
# or with uv:
uv add keepachangelog-manager
```

## What It Does

- Creates a new empty `CHANGELOG.md` with the expected Keep a Changelog structure.
- Adds messages to sections such as Added, Changed, Deprecated, Removed, Fixed, and Security.
- Validates changelog consistency and can format errors for local terminals or GitHub annotations.
- Releases the `[Unreleased]` block into a versioned section.
- Exports changelog content to JSON and includes GitHub release automation commands.
- Supports multiple changelog files in one repository through a component configuration file.

## Configuration

The default workflow can operate on a single `CHANGELOG.md` with command-line options such as `--input-file`. For repositories with multiple components, the project can define a YAML config and select a component at runtime.

```yaml
project:
  components:
    - name: Service Component
      changelog: service/CHANGELOG.md
    - name: Client Interface
      changelog: client/CHANGELOG.md
```

```bash
changelogmanager --config config.yml --component "Client Interface" validate
changelogmanager --input-file CHANGELOG.md release 1.4.0
```

First-run setup is low for a single changelog and moderate for multi-component repositories. The commands are explicit, which makes the tool straightforward to wire into CI.

## Output Quality

The output remains standard Keep a Changelog Markdown rather than a generated commit digest:

```markdown
## [1.4.0] - 2026-05-31

### Added

- Add client-side changelog validation to the release pipeline.

### Fixed

- Preserve component-specific comparison links during release.
```

The validation and release commands are the main quality guardrails. They help keep headings, versions, and unreleased sections consistent, but the actual prose still needs to be written by humans.

## Ecosystem Fit

`keepachangelog-manager` fits Python projects that prefer a command-oriented release process and a committed changelog. It can be used from `uv run`, `tox`, or CI jobs, and its GitHub-oriented error formatting and release commands make it practical for automated release pipelines.

It is less useful for projects that want fragments per pull request or changelogs generated from Conventional Commits. Its best niche is validating and operating an explicit Keep a Changelog file.

## Maintenance Status

- Latest version: **4.0.0**
- Last release: **2025-06-10**
- GitHub stars: **0**
- Appears actively maintained.
- Repository: <a href="https://github.com/tomtom-international/keepachangelog-manager" target="_blank" rel="noopener noreferrer">https://github.com/tomtom-international/keepachangelog-manager</a>

The current README documents CLI commands for create, add, validate, release, JSON export, GitHub release handling, and multi-component configuration.

## Verdict

**Verdict: Situational**

Use `keepachangelog-manager` when the team wants a CLI to enforce and operate a Keep a Changelog file, especially in CI or multi-component repositories. For broad community adoption and fragment workflows, Towncrier or Scriv are stronger defaults; for strict changelog-file validation and release promotion, this tool is a practical fit.
