Title: release-cli
Date: 2026-05-31
Slug: release-cli
Ecosystem: Cross
Tags: cli, cross, gitlab-integration
Tool_URL: https://gitlab.com/gitlab-org/release-cli
Tool_Version: unknown
Tool_Status: archived
Summary: Deprecated GitLab release command-line tool formerly used by CI release jobs to create releases through the Releases API.

> **Note:** This tool is deprecated. See the Maintenance Status section for migration guidance.

## Overview

`release-cli` was GitLab's dedicated command-line tool for creating Releases from CI jobs. It existed to make release publication easy inside `.gitlab-ci.yml`, but it has been superseded by the official `glab release` command.

For new work, treat it as legacy compatibility only.

## Installation

Avoid adding `release-cli` to new pipelines. Existing GitLab examples may still show it, but current release jobs should use `glab`.

```bash
glab release create v1.8.0 --notes-file RELEASE.md
```

## What It Does

- Creates GitLab Releases from CI jobs.
- Publishes release descriptions and asset links.
- Works with existing tags or release tags created in the pipeline.
- Does not generate changelog prose by itself.

## Configuration

Configuration was usually inline in `.gitlab-ci.yml` through command flags or the `release:` job keyword.

```yaml
release_job:
  stage: release
  script:
    - glab release create "$CI_COMMIT_TAG" --notes-file RELEASE.md
  rules:
    - if: $CI_COMMIT_TAG
```

When migrating, keep the release intent but switch the command surface to `glab`.

## Output Quality

`release-cli` publishes the release body supplied by the pipeline:

```markdown
## v1.8.0

### Fixed

- Correct the Linux package asset link.
```

It is not a note generator, so output quality depends entirely on the file or string passed into the release command.

## Ecosystem Fit

Historically it fit GitLab CI well, but `glab release` is now the better GitLab-native path. `release-cli` has no reason to be selected for GitHub projects or forge-neutral workflows.

Existing pipelines do not need panic rewrites, but they should be migrated when touched.

## Maintenance Status

- Latest version: **unknown**
- Last release: **unknown**
- **Repository is archived** - no new development expected.
- Repository: <a href="https://gitlab.com/gitlab-org/release-cli" target="_blank" rel="noopener noreferrer">https://gitlab.com/gitlab-org/release-cli</a>

GitLab's guidance is to move release automation to `glab`.

## Verdict

**Verdict: Avoid**

Do not choose `release-cli` for new release automation. Use `glab release` for GitLab release publication and pair it with GitLab Changelogs or another generator for release-note content.
