Title: github-release-from-changelog
Date: 2026-05-31
Slug: github-release-from-changelog
Ecosystem: Node
Tags: github-integration, node, npm-cli, github-releases, changelog-to-release-notes, unmaintained
Tool_URL: https://www.npmjs.com/package/github-release-from-changelog
Tool_Version: 2.1.1
Tool_Status: unmaintained
Summary: CLI that extracts the relevant changelog section and creates/updates a GitHub Release for a tag.



## Overview

`github-release-from-changelog` is a small CLI for projects that already maintain a changelog and want to publish one version section to GitHub Releases. It does not generate changelog prose; it extracts the relevant text and sends it to GitHub.

That makes it a narrow bridge between manual changelog discipline and GitHub Release publication.

## Installation

```bash
npm install --save-dev github-release-from-changelog
```

## What It Does

- Reads a changelog file.
- Finds the section matching a release tag or version.
- Creates or updates the corresponding GitHub Release.
- Keeps release body text aligned with `CHANGELOG.md`.

## Configuration

Configuration is mostly CLI flags and environment variables:

```bash
GITHUB_TOKEN="$GITHUB_TOKEN" \
  github-release-from-changelog --changelog CHANGELOG.md --tag v2.1.1
```

First-run setup is low if the changelog format is predictable and GitHub authentication is already available.

## Output Quality

Output quality is entirely inherited from the source changelog:

```markdown
## 2.1.1 - 2026-05-31

### Fixed

- Publish the exact changelog section as the GitHub release body.
```

That is a strength when the changelog is curated, and a weakness if the changelog is inconsistent.

## Ecosystem Fit

This fits older npm workflows where `CHANGELOG.md` is the release source of truth. Modern GitHub projects may instead use GitHub's generated release notes, Release Drafter, changelogithub, or release-it.

It is intentionally not a versioning or publishing tool.

## Maintenance Status

- Latest version: **2.1.1**
- Last release: **2020-02-18**
- Tool status in this survey: **unmaintained**
- Repository: <a href="https://github.com/MoOx/github-release-from-changelog" target="_blank" rel="noopener noreferrer">https://github.com/MoOx/github-release-from-changelog</a>

## Verdict

**Verdict: Situational**

Use it only for existing workflows that already depend on extracting GitHub Releases from a committed changelog. For new projects, choose a more active GitHub release tool.
