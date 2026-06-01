Title: standard-version
Date: 2026-05-31
Slug: standard-version
Ecosystem: Node
Tags: conventional-commits, keep-a-changelog, node, npm-cli, semantic-versioning, git-tags, changelog-file, legacy
Tool_URL: https://www.npmjs.com/package/standard-version
Tool_Version: 9.5.0
Tool_Status: unmaintained
Summary: Automate versioning and CHANGELOG generation with semver and conventional commits

> **Note:** This tool is considered legacy. The community has largely moved on; see Maintenance Status.

## Overview

`standard-version` was the classic npm release helper for Conventional Commits projects: bump the version, update `CHANGELOG.md`, create a release commit, and tag it. It shaped a lot of Node release habits.

Today it is mainly important as legacy context. Projects that still use it can keep working, but new projects should usually choose `commit-and-tag-version`, release-it, or semantic-release.

## Installation

```bash
npm install --save-dev standard-version
```

## What It Does

- Determines semver bumps from Conventional Commits.
- Updates `package.json` and related version files.
- Generates a changelog through conventional-changelog.
- Commits release changes and creates a git tag.
- Supports custom presets and lifecycle scripts.

## Configuration

The old standard setup is an npm script:

```json
{
  "scripts": {
    "release": "standard-version"
  },
  "standard-version": {
    "preset": "conventionalcommits"
  }
}
```

First-run setup is easy, but the maintenance posture changes the recommendation.

## Output Quality

Output is conventional-changelog style:

```markdown
## 9.5.0 (2026-05-31)

### Features

- add npm release automation

### Bug Fixes

- update generated changelog links
```

The output remains useful, but the tool is no longer the preferred implementation of this workflow.

## Ecosystem Fit

Historically, standard-version fit npm packages very well. It is still common in older repositories, docs, and copy-pasted release scripts.

For new work, `commit-and-tag-version` preserves the same mental model with more active maintenance.

## Maintenance Status

- Latest version: **9.5.0**
- Last release: **2022-05-15**
- Tool status in this survey: **unmaintained**
- Repository: <a href="https://github.com/conventional-changelog/standard-version" target="_blank" rel="noopener noreferrer">https://github.com/conventional-changelog/standard-version</a>

Treat this as legacy release infrastructure.

## Verdict

**Verdict: Avoid for new projects**

Keep `standard-version` only where it is already working and low risk. For new npm release workflows, use `commit-and-tag-version`, release-it, semantic-release, or Changesets depending on the desired release style.
