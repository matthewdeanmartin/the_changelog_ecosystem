Title: release-please
Date: 2026-05-31
Slug: release-please
Ecosystem: Cross
Tags: conventional-commits, cross, github-action-cli, github-integration, semantic-versioning
Tool_URL: https://github.com/googleapis/release-please-action
Tool_Version: 5.0.0
Tool_Status: active
Summary: Google release automation that parses Conventional Commits, opens release PRs, updates changelogs, bumps versions, and creates GitHub releases.



## Overview

`release-please` automates releases by opening a release pull request. It parses Conventional Commits, proposes version bumps, updates changelogs and manifest files, and creates GitHub Releases after the release PR merges.

That release-PR model is the key distinction: automation does the bookkeeping, but humans still review the exact release diff.

## Installation

```yaml
- uses: googleapis/release-please-action@v5
  with:
    release-type: node
```

## What It Does

- Parses Conventional Commits to determine semantic version bumps.
- Opens and updates a release PR with changelog and version-file changes.
- Supports many release types, including Node, Python, Java, Go, Ruby, Rust, and simple projects.
- Creates GitHub Releases after the release PR is merged.
- Supports manifest mode for monorepos and multi-package repositories.

## Configuration

Small projects can configure the GitHub Action directly. Larger projects usually use `release-please-config.json` and `.release-please-manifest.json`.

```json
{
  "release-type": "simple",
  "packages": {
    ".": {
      "package-name": "example-tool"
    }
  }
}
```

First-run setup is moderate: commit conventions, package files, branch permissions, and GitHub token behavior must line up. Once it is running, the release PR becomes a clear review point.

## Output Quality

Release notes are generated from Conventional Commits:

```markdown
## [1.7.0](https://github.com/example/tool/compare/v1.6.0...v1.7.0)

### Features

- add GitLab release publishing support

### Bug Fixes

- preserve changelog headings in manifest mode
```

The quality is strong for projects that write user-facing commit messages. It is weaker when commits are noisy or implementation-heavy.

## Ecosystem Fit

`release-please` is cross-language but GitHub-centered. It is especially good for repositories that want version bumps and changelog updates committed before the actual release.

It is less appropriate for teams that publish from GitLab, want fragment files, or prefer a single push-to-main release with no release PR.

## Maintenance Status

- Latest version: **5.0.0**
- Last release: **2026-04-22**
- GitHub stars: **2,415**
- Appears actively maintained.
- Repository: <a href="https://github.com/googleapis/release-please-action" target="_blank" rel="noopener noreferrer">https://github.com/googleapis/release-please-action</a>

The action and CLI remain active and widely used across Google's open-source release workflows.

## Verdict

**Verdict: Recommended**

Use `release-please` when Conventional Commits are viable and you want a reviewable release PR that updates changelogs and versions. It is one of the best default choices for GitHub projects that want automation without losing a human checkpoint.
