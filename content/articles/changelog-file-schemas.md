Title: Changelog File Schemas
Date: 2026-06-02
Slug: changelog-file-schemas
Ecosystem: Cross
Tags: changelog-schema, keep-a-changelog, validation, markdown, release-notes
Tool_Status: research
Summary: A survey of changelog file structures — from informal CHANGELOG.md conventions through Keep a Changelog, machine-readable JSON/YAML variants, fragment directories, and generated release-note formats — with notes on what each format preserves and what it costs.

## Overview

Changelog tools store their data in at least five structurally distinct formats. Choosing a format is not just a style choice: it determines whether CI can validate entries, whether the data can be parsed by other tools, and whether human editors can modify it without an intermediary command.

This article surveys the formats in use, identifies their structural requirements, and maps each one to the tools that read or write it.

## Format Families

### 1. Informal CHANGELOG.md

The most common starting point: a hand-written Markdown file with no enforced schema. Typical structure:

```markdown
# Changelog

## 2.1.0 – 2025-11-10

- Added dark mode toggle (#312)
- Fixed login redirect loop (#298)

## 2.0.0 – 2025-09-01

- Removed legacy XML import format
```

**What it preserves:** Full human authorship, any prose style, arbitrary structure.

**What it costs:** Tools cannot reliably parse it. Version headings vary (`## 2.1.0`, `## v2.1.0 (2025-11-10)`, `### Release 2.1.0`), section groupings are ad hoc, and date formats differ. The `keepachangelog` Python library, for example, will refuse to parse a file with non-standard headings.

**Who uses it:** Most small projects, before adopting any tooling. Projects that adopt tooling often migrate away from this format.

### 2. Keep a Changelog Markdown

[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) defines a concrete Markdown schema on top of the informal convention. The key structural rules:

- The file starts with a `# Changelog` heading.
- An `## [Unreleased]` section sits at the top for pending changes.
- Each release uses `## [version] - YYYY-MM-DD` (e.g. `## [2.1.0] - 2025-11-10`).
- Within each release, change types use `### Added`, `### Changed`, `### Deprecated`, `### Removed`, `### Fixed`, `### Security`.
- A reference link block at the bottom maps each version to a comparison URL: `[2.1.0]: https://github.com/example/repo/compare/v2.0.0...v2.1.0`.

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2025-11-10

### Added

- Dark mode toggle (#312)

### Fixed

- Login redirect loop (#298)

[Unreleased]: https://github.com/example/repo/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/example/repo/compare/v2.0.0...v2.1.0
```

**What it preserves:** Human readability, hand-authored prose, and a parseable structure.

**What tools rely on it:** `keepachangelog` (Python library), `keepachangelog-manager`, changie (produces KAC-compatible output), scriv (partially — see below), release-please, and any CI step that validates `## [Unreleased]` exists.

**Parsing requirements for tool compatibility:** To be reliably parsed by `keepachangelog`, the file must use bracketed version headings (`[2.1.0]` not `2.1.0`) and ISO dates. Scriv produces KAC-*adjacent* output but uses `# version` (h1) headings rather than `## [version]` (h2), which breaks the `keepachangelog` parser.

### 3. Fragment Directories

Fragment-based tools — Towncrier, Scriv, Reno, Changie — store individual change entries as small files rather than a single accumulated changelog. The schema lives in the file's name and/or content.

**Towncrier fragments** (`newsfragments/`)

The filename encodes both the type and the issue reference:

```
123.feature          # issue 123, type = feature
456.bugfix           # issue 456, type = bugfix
+orphan.doc          # no issue number; + prefix marks an orphan
```

File content is plain text (or reStructuredText). The schema is entirely in the filename. There is no structured data inside the file.

**Changie fragments** (`.changes/unreleased/`)

Changie fragments are YAML files with a schema defined by the project's `.changie.yaml`:

```yaml
kind: Added
body: Split the bill evenly among a fixed number of diners.
time: 2026-06-02T10:00:00Z
custom:
  Issue: "42"
```

Core fields: `kind` (maps to a configured kind label), `body` (free text), `time` (ISO timestamp), `custom` (arbitrary key-value pairs from configured prompts). The schema is versioned through the `.changie.yaml` configuration.

**Reno fragments** (`releasenotes/notes/`)

Reno uses YAML files with fixed section keys:

```yaml
---
features:
  - |
    Added dark mode toggle.
fixes:
  - |
    Fixed login redirect loop; resolves issue #298.
upgrade:
  - |
    The config key `theme` is now `ui.theme`; update your config file.
```

Section keys are the taxonomy keys (`features`, `fixes`, `upgrade`, `deprecations`, `security`, `issues`, `critical`, `other`, `prelude`). Values are YAML lists of pipe-literal strings to preserve multi-line RST content. The filename includes a random hex suffix to avoid merge conflicts: `dark-mode-abc123def456.yaml`.

**Scriv fragments** (`changelog.d/`)

Scriv fragments are plain Markdown (or RST) files with free-form content under category headings:

```markdown
## Added

- Split the bill evenly among a fixed number of diners.

## Fixed

- Corrected tip calculation when tip percentage is zero.
```

The schema is the heading level and the category name. There is no structured data file — `scriv collect` parses the headings and assembles them into the main changelog.

### 4. Generated Release-Note Formats

Some tools produce output that is not intended to be a persistent `CHANGELOG.md` but is used in GitHub Releases, CI artifacts, or documentation pipelines.

**GitHub Releases body (Markdown)**

GitHub Releases stores the body as raw Markdown in the GitHub API. When using release-please, the body is generated from Conventional Commits and looks like:

```markdown
## [2.1.0](https://github.com/example/repo/compare/v2.0.0...v2.1.0) (2025-11-10)

### Features

* Add dark mode toggle ([#312](https://github.com/example/repo/pull/312))

### Bug Fixes

* Fix login redirect loop ([#298](https://github.com/example/repo/pull/298))
```

This is KAC-adjacent but not KAC-compliant: version headings include a hyperlink inline, and the version is not bracketed as `[2.1.0]`.

**Reno RST reports**

`reno report` outputs reStructuredText to stdout. It is designed to be embedded in a Sphinx documentation build:

```rst
=============
Release Notes
=============

.. _Release Notes_2.1.0:

2.1.0
=====

.. _Release Notes_2.1.0_New Features:

New Features
------------

- Added dark mode toggle.
```

This is not a `CHANGELOG.md` equivalent — it is a documentation section. Teams that want a `CHANGELOG.md` must either run reno separately from their docs or convert the RST output.

**release-please manifest (JSON)**

release-please maintains a `.release-please-manifest.json` that records the current version for each package path:

```json
{
  ".": "2.1.0",
  "packages/cli": "1.4.0",
  "packages/core": "3.0.1"
}
```

This is not a changelog; it is release state. It pairs with `release-please-config.json` for configuration. Both are machine-readable by design — they are never hand-edited once the workflow is running.

## Structural Requirements for Tool Compatibility

The table below summarizes what fields each format requires to be parseable by the tooling that reads it.

| Format | Required fields | Encoding | Human-editable? |
|---|---|---|---|
| Informal CHANGELOG.md | None — free-form | Markdown | Yes |
| Keep a Changelog MD | `## [version] - YYYY-MM-DD`, `### Section` headings, reference links | Markdown | Yes |
| Towncrier fragments | `{issue}.{type}` filename pattern | Plain text | Yes |
| Changie fragments | `kind`, `body`, `time` YAML keys | YAML | Barely (generated by tool) |
| Reno fragments | One or more section keys (`features`, `fixes`, etc.) as YAML lists | YAML with pipe literals | With care |
| Scriv fragments | `## Category` headings in Markdown | Markdown | Yes |
| GitHub release body | None — free-form | Markdown | Yes |
| Reno RST report | RST section headings | reStructuredText | No (generated) |
| release-please manifest | `{"path": "version"}` JSON map | JSON | No (managed by tool) |

## Which Formats Are CI-Validatable?

**Easily validated in CI:**

- Keep a Changelog Markdown — `keepachangelog show Unreleased` exits non-zero if the section is missing or malformed. Release-please and git-cliff both fail gracefully on malformed input.
- Towncrier fragments — `towncrier check --compare-with <ref>` verifies that at least one fragment exists for a non-trivial change.
- Changie fragments — `changie latest` and `changie batch` both fail on malformed YAML.
- Reno fragments — `reno lint` scans the note directory for YAML errors and misattributed notes.

**Not easily validated without custom scripts:**

- Informal CHANGELOG.md — no tool can reliably parse it without assumptions about the format.
- GitHub release bodies — validated indirectly when the release is published; there is no pre-publish linting.
- Reno RST output — validated by the Sphinx build, not by reno itself.

## Which Formats Survive Human Editing?

Fragment-based formats are the most durable under human editing because each change is an independent file. A malformed fragment affects only that entry, not the entire release history.

KAC Markdown survives human editing if contributors know the format. The comparison link block at the bottom is the highest-risk section — a missed link or wrong URL range is hard to catch by eye and breaks the parseable structure.

Reno YAML fragments are technically editable but fragile in practice: YAML pipe-literal syntax (`- |` with correct indentation) is easy to break silently without a YAML linter. The random-hex filename convention makes them safe to create on parallel branches.

The release-please manifest and Changie YAML fragments should not be hand-edited once tooling is running. They are intended as machine-generated state files.

## Summary

| Format | Parseable | CI-gateable | Human-authored | Fragment-based |
|---|---|---|---|---|
| Informal CHANGELOG.md | No | No | Yes | No |
| Keep a Changelog MD | Yes | Yes | Yes | No |
| Towncrier fragments | Yes | Yes | Yes | Yes |
| Changie fragments | Yes | Yes | Rarely | Yes |
| Reno fragments | Yes | Yes | With care | Yes |
| Scriv fragments | Yes | No | Yes | Yes |
| GitHub release body | No | No | Yes | No |
| release-please manifest | Yes | N/A | No | No |

The clearest pattern: **parseable formats require a committed structural convention** — either at the file level (KAC's heading rules) or at the encoding level (YAML with required keys). Formats that leave structure entirely to authors are human-friendly but tool-hostile. The fragment directory model splits the difference: each fragment is tiny and independently parseable, so the full changelog can be validated or regenerated at any time without relying on the accumulated document remaining well-formed.

## Related Articles

- [Keep a Changelog]({filename}keep-a-changelog.md)
- [keepachangelog]({filename}keepachangelog.md)
- [towncrier]({filename}towncrier.md)
- [reno]({filename}reno.md)
- [changie]({filename}changie.md)
- [scriv]({filename}scriv.md)
- [Change Taxonomies Across Tools]({filename}change-taxonomies-across-tools.md)
- [Changelog Validation Boundaries]({filename}changelog-validation-boundaries.md)
