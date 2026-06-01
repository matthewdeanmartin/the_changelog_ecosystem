Title: commit-and-tag-version
Date: 2026-05-31
Slug: commit-and-tag-version
Ecosystem: Node
Tags: conventional-commits, keep-a-changelog, node, npm-cli, semantic-versioning, git-tags, changelog-file
Tool_URL: https://www.npmjs.com/package/commit-and-tag-version
Tool_Version: 12.7.3
Tool_Status: active
Summary: Drop-in replacement style tool for npm version workflows with automated bumping, tagging, and changelog generation.



## Overview

`commit-and-tag-version` is a maintained continuation of the standard-version style workflow: analyze Conventional Commits, bump versions, update `CHANGELOG.md`, create a release commit, and tag it.

It is intentionally simpler than semantic-release. A maintainer runs a command, reviews the diff, and pushes the result.

## Installation

```bash
npm install --save-dev commit-and-tag-version
```

## What It Does

- Computes the next semver version from Conventional Commits.
- Updates package metadata such as `package.json` and lockfiles.
- Generates or updates `CHANGELOG.md`.
- Creates a release commit and git tag.
- Supports configuration inherited from the standard-version/conventional-changelog ecosystem.

## Configuration

Most projects add an npm script:

```json
{
  "scripts": {
    "release": "commit-and-tag-version"
  },
  "commit-and-tag-version": {
    "preset": "conventionalcommits",
    "tagPrefix": "v"
  }
}
```

First-run setup is low for single-package repositories. Workspaces and nonstandard version files need more configuration.

## Output Quality

The changelog output follows conventional-changelog patterns:

```markdown
## 12.7.3 (2026-05-31)

### Features

- add release commit validation

### Bug Fixes

- keep generated changelog section ordering stable
```

It is clean if commit messages are clean, and the committed diff gives maintainers a review point before pushing.

## Ecosystem Fit

This fits npm packages that want an explicit local release command and a committed changelog. It is less ambitious than release-it and less automated than semantic-release, which is a virtue for some teams.

It is also a practical migration path for projects that used standard-version and want a maintained equivalent.

## Maintenance Status

- Latest version: **12.7.3**
- Appears actively maintained.
- Repository: <a href="https://github.com/absolute-version/commit-and-tag-version" target="_blank" rel="noopener noreferrer">https://github.com/absolute-version/commit-and-tag-version</a>

The project exists largely to keep the standard-version-style workflow alive with current dependencies and maintenance.

## Verdict

**Verdict: Recommended**

Use `commit-and-tag-version` when you want a straightforward Conventional Commits release command that updates files, commits, and tags. It is a good fit for smaller npm packages and teams migrating away from standard-version.
