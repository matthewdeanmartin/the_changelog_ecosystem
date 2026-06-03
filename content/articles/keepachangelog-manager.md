Title: keepachangelog-manager-fork
Date: 2026-06-02
Slug: keepachangelog-manager
Ecosystem: Python
Tags: keep-a-changelog, python, python-cli, validation, release-notes, github-integration, ci-cd, multi-component, hands-on
Tool_URL: https://pypi.org/project/keepachangelog-manager-fork/
Tool_Version: 5.2.0
Tool_Status: active
Experiment: examples/python/keepachangelog-manager/
Summary: Maintained fork providing a command-line workflow around Keep a Changelog files — hands-on testing confirms a clean create/add/release triad with two format caveats.



## Overview

`keepachangelog-manager-fork` is the maintained fork of `keepachangelog-manager`, a Python CLI for teams that want a structured command-line workflow around a Keep a Changelog-style `CHANGELOG.md`. It can create changelogs, add entries, validate format, export JSON, promote unreleased changes into a release, and help publish GitHub release notes.

This distinction matters: the original `tomtom-international/keepachangelog-manager` project is archived and unsupported. The maintained fork lives at `matthewdeanmartin/keepachangelog-manager`, is published on PyPI as `keepachangelog-manager-fork`, and has continued feature work focused on usability and release automation.

The fork is more workflow-oriented than the `keepachangelog` library and more capable than the archived upstream package. It is aimed at maintainers who want a CLI that enforces changelog hygiene rather than an importable parser alone.

A reproducible hands-on experiment for this tool lives in [`examples/python/keepachangelog-manager/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/keepachangelog-manager). The real output shown later in this article comes from that run.

## Installation

```bash
pip install keepachangelog-manager-fork
# or with uv:
uv add keepachangelog-manager-fork
```

The CLI entry point is `changelogmanager`.

## What It Does

- Creates a new empty `CHANGELOG.md` with the expected Keep a Changelog structure.
- Adds messages to sections such as Added, Changed, Deprecated, Removed, Fixed, and Security (via `--change-type`).
- Validates changelog consistency and can format errors for local terminals or GitHub annotations.
- Releases the `[Unreleased]` block into a versioned section.
- Exports changelog content to JSON and includes GitHub release automation commands.
- Supports multiple changelog files in one repository through a component configuration file.
- Improves maintainer ergonomics in the fork with commands and options around GitHub release and pull request workflows.

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

First-run setup is low for a single changelog and moderate for multi-component repositories. The commands are explicit, which makes the tool straightforward to wire into CI. (For non-interactive CI use, the `--yes` flag is essential — see the hands-on findings.)

## Output Quality

The output remains standard Keep a Changelog Markdown rather than a generated commit digest. The validation and release commands are the main quality guardrails — they help keep headings, versions, and unreleased sections consistent, but the actual prose still needs to be written by humans. See the **Hands-on findings** section below for the exact, real output produced when driving a sample project through several releases (including two format gaps worth knowing about).

## Ecosystem Fit

`keepachangelog-manager-fork` fits Python projects that prefer a command-oriented release process and a committed changelog. It can be used from `uv run`, `tox`, or CI jobs, and its GitHub-oriented error formatting and release commands make it practical for automated release pipelines.

It is less useful for projects that want fragments per pull request or changelogs generated from Conventional Commits. Its best niche is validating and operating an explicit Keep a Changelog file.

## Maintenance Status

- Latest version: **5.2.0**
- Last release: **2026-05-31**
- GitHub stars: **0**
- Appears actively maintained.
- Maintained fork repository: <a href="https://github.com/matthewdeanmartin/keepachangelog-manager" target="_blank" rel="noopener noreferrer">https://github.com/matthewdeanmartin/keepachangelog-manager</a>
- PyPI package: <a href="https://pypi.org/project/keepachangelog-manager-fork/" target="_blank" rel="noopener noreferrer">keepachangelog-manager-fork</a>
- Archived upstream: <a href="https://github.com/tomtom-international/keepachangelog-manager" target="_blank" rel="noopener noreferrer">tomtom-international/keepachangelog-manager</a>

The current fork documents CLI commands for create, add, validate, release, JSON export, GitHub release handling, pull request workflow support, formatting options, and multi-component configuration. The archived upstream has fewer features and should be treated as unsupported historical context, not the recommended package.

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

### Pros (observed)

- **`create` + `add` + `release` is a coherent three-command workflow.** No manual `CHANGELOG.md` editing is required. Each command has a clear, single responsibility.
- **`add` is the standout feature over the plain `keepachangelog` library.** A command that places a formatted bullet under the right section removes the most common human error in manual changelog workflows.
- **`release --yes` is non-interactive and automation-safe.** The `--yes` flag skips the confirmation prompt cleanly; `--override-version` pins the version so CI pipelines do not need to infer it.
- **`release` prints a clear confirmation.** `Released 2.0.0` on stdout is enough for a CI log to confirm success without parsing file output.
- **Installs on Python 3.12 without issues.** The dependency tree (inquirer, blessed, etc.) resolved cleanly.
- **Generates the `[Unreleased]` header on `create`.** The output follows Keep a Changelog 1.1.0 conventions, a minor but meaningful format update over the older 1.0.0 spec.

### Cons / pain points (observed)

- **`[Unreleased]` section is dropped after `release`.** After `changelogmanager release`, the `[Unreleased]` section does not reappear in the file. The plain `keepachangelog` library preserves an empty `[Unreleased]` header; `changelogmanager` removes it. This is a footgun for teams that run `validate` against a released changelog and expect the section to be there, or for CI rules that assert its presence.
- **No comparison links are generated.** Unlike `keepachangelog release`, the fork does not maintain `[x.y.z]: https://...compare/...` link definitions at the bottom of the file. A strict KAC validator would flag the output as incomplete.
- **Version is not reliably auto-detected.** `release` without `--override-version` attempts to infer the version, but in the experiment it required `--override-version` to pin correctly.
- **`--version` is not exposed.** `changelogmanager --version` fails (SystemExit 2). Verifying the installed version requires `pip show keepachangelog-manager-fork`.
- **Output whitespace differs from the plain library.** `create` writes `## [Unreleased]\n### Added\n` with no blank line after the header, whereas the `keepachangelog` library writes blank lines between sections. Both are valid KAC, but switching between the two tools can produce noisy diffs.
- **Heavier dependency footprint.** Requires inquirer, blessed, jinxed, readchar — a larger install than the plain `keepachangelog` library.

### Docs vs. reality

The original description correctly identified the fork as the maintained package and described its command set; the workflow-oriented CLI matched what was observed. What it did not capture: the `--section` flag does not exist (the real flag is `--change-type` with lowercase type names), the missing `[Unreleased]` section after `release`, the absence of comparison links, and that the `--yes` flag is essential for non-interactive use.

## Verdict

**Verdict: Situational (confirmed, with format caveats)**

`keepachangelog-manager-fork` delivers on its core promise: a CLI workflow that avoids hand-editing `CHANGELOG.md`. The `create`/`add`/`release` triad is clean, non-interactive with `--yes`, and suitable for CI pipelines.

The two format gaps (no `[Unreleased]` after release, no comparison links) make the output non-compliant with a strict reading of the KAC spec and incompatible with the plain `keepachangelog` library's output style. Projects that need those features should add a post-release step to restore the `[Unreleased]` header and maintain link definitions.

Prefer the fork over the archived `tomtom-international/keepachangelog-manager`; the fork is the only version worth considering. For broad community adoption and fragment workflows, Towncrier or Scriv are stronger defaults; for strict changelog-file validation, usability-focused release commands, and release promotion, this tool is a practical fit.
