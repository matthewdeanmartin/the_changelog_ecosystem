Title: changie
Date: 2026-05-31
Slug: changie
Ecosystem: Go
Tags: go, go-cli, keep-a-changelog, news-fragments, custom-templates, version-management, changelog-file, language-agnostic
Tool_URL: https://github.com/miniscruff/changie
Tool_Version: 1.24.0
Tool_Status: active
Summary: File-based changelog management and versioning tool distributed as a Go binary.



## Overview

`changie` is a file-based changelog tool: each change is captured while the work is fresh, later batched into a release version, and finally merged into the main changelog. It is written in Go and shipped as a single binary, but the workflow is intentionally language-agnostic.

The closest mental model is Towncrier or Changesets without being tied to Python or Node. It is a good fit for teams that want contributors to write release-note fragments instead of trying to reconstruct user impact from commits at release time.

## Installation

```bash
# See https://github.com/miniscruff/changie for installation options
# (binary releases, Homebrew, package managers)
```

## What It Does

- Creates change files with `changie new`.
- Batches unreleased changes into a version file with `changie batch`.
- Merges version files into a parent `CHANGELOG.md` with `changie merge`.
- Tracks change kinds such as added, changed, deprecated, removed, fixed, and security.
- Can compute version bumps from change metadata.
- Supports templates, custom prompts, custom fields, multiple projects, and replacements.

## Configuration

Changie uses `.changie.yaml`, normally created by `changie init`. The config names the change directory, changelog path, version format, change kinds, and output templates.

```yaml
changesDir: .changes
changelogPath: CHANGELOG.md
versionFormat: '## {{.Version}} - {{.Time.Format "2006-01-02"}}'
changeFormat: '- {{.Body}}'
kinds:
  - label: Added
    auto: minor
  - label: Fixed
    auto: patch
  - label: Security
    auto: patch
```

First-run setup is low to moderate. The init command creates a starting point, but teams should tune kinds, version formatting, and any custom prompts before asking contributors to use it.

## Output Quality

Changie output is usually more human-friendly than a raw commit log because every entry begins as a deliberate change note:

```markdown
## 1.8.0 - 2026-05-31

### Added

- Add multi-project changelog support for CLI and API packages.

### Fixed

- Preserve custom issue links when merging release notes.
```

The quality depends on contributor discipline, but the fragment workflow encourages user-facing language earlier than commit-derived generators do.

## Ecosystem Fit

For Go teams, Changie fits well because it is a static CLI binary and works cleanly in CI without language runtime setup. It is also useful in polyglot repositories where GoReleaser would be too Go-specific and Changesets would be too Node-specific.

It does not build binaries or publish GitHub Releases. Pair it with GoReleaser, GitHub Actions, or a package-specific release process when publication is needed.

## Maintenance Status

- Latest version: **1.24.0**
- Last release: **2025-11-22**
- GitHub stars: **879**
- Appears actively maintained.
- Repository: <a href="https://github.com/miniscruff/changie" target="_blank" rel="noopener noreferrer">https://github.com/miniscruff/changie</a>

The documentation is active and covers quick start, configuration, batching, merging, templates, project support, backups, and CLI commands.

## Verdict

**Verdict: Recommended**

Use Changie when a Go or polyglot project wants intentional, file-based changelog entries with minimal runtime baggage. It is the strongest Go-binary answer to fragment workflows, and it complements GoReleaser nicely when release publication is handled elsewhere.
