Title: glab release
Date: 2026-05-31
Slug: glab-release
Ecosystem: Cross
Tags: cli, cross, gitlab-integration
Tool_URL: https://gitlab.com/gitlab-org/cli
Tool_Version: unknown
Tool_Status: active
Summary: GitLab CLI release command for creating or updating releases, including using release notes from a file.



## Overview

`glab release` is the official GitLab CLI command for creating, viewing, updating, and deleting GitLab Releases. It is not primarily a changelog generator; it is the publication step that turns tags, notes, milestones, and assets into a GitLab Release.

It matters because GitLab's older `release-cli` is deprecated, and new GitLab release automation should generally use `glab`.

## Installation

Install the official GitLab CLI and authenticate it before using release commands.

```bash
glab auth login
```

## What It Does

- Creates GitLab Releases for existing or new tags.
- Updates release names, descriptions, milestones, and asset links.
- Reads release notes from a file, which pairs well with `glab changelog generate`.
- Runs cleanly from GitLab CI when provided with the right token and project context.

## Configuration

Configuration is mostly command flags plus GitLab authentication. A common pattern is to generate notes first, then publish them.

```bash
glab changelog generate --version v1.8.0 > RELEASE.md
glab release create v1.8.0 --notes-file RELEASE.md
```

The first-run complexity is mostly CI permissions: the job needs a token that can create releases and, if needed, upload assets.

## Output Quality

`glab release` publishes the notes you give it:

```markdown
## v1.8.0

### Added

- Add SBOM upload to release assets

### Fixed

- Correct release links for self-managed GitLab instances
```

Quality comes from the upstream note generator or human-written file. The command itself is a transport and release-management tool.

## Ecosystem Fit

The fit is excellent for GitLab projects in any language. It is the natural replacement for `release-cli` and works with GitLab CI/CD conventions.

It is irrelevant for GitHub Releases and does not maintain a committed `CHANGELOG.md` by itself.

## Maintenance Status

- Latest version: **unknown**
- Last release: **unknown**
- Appears actively maintained.
- Repository: <a href="https://github.com/gitlab-org/cli" target="_blank" rel="noopener noreferrer">https://github.com/gitlab-org/cli</a>

`glab release` is part of the official GitLab CLI and should be treated as the current GitLab release command surface.

## Verdict

**Verdict: Recommended**

Use `glab release` for GitLab release publication, especially in new CI jobs replacing `release-cli`. Pair it with `glab changelog`, GitLab Changelogs, or a separate generator for the actual prose.
