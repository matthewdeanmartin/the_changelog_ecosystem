Title: changelog-from-release
Date: 2026-05-31
Slug: changelog-from-release
Ecosystem: Cross
Tags: backfill, cli, cross
Tool_URL: https://github.com/rhysd/changelog-from-release
Tool_Version: 3.9.1
Tool_Status: unmaintained
Summary: Small CLI that backfills/generates a Markdown changelog from existing GitHub Releases.



## Overview

`changelog-from-release` solves the inverse problem from most changelog tools: it turns existing GitHub Releases into a local Markdown changelog. It is aimed at projects that have been publishing release notes on GitHub for years and now want a `CHANGELOG.md` without rewriting history by hand.

It is intentionally narrow. Use it for backfill and synchronization from GitHub Releases, not as a full release orchestration system.

## Installation

```bash
# See https://github.com/rhysd/changelog-from-release for binary and package-manager options.
```

## What It Does

- Reads GitHub Release entries for a repository.
- Converts release titles, tags, dates, and bodies into a Markdown changelog.
- Helps backfill `CHANGELOG.md` when GitHub Releases are already the source of truth.
- Works as a small CLI that can be run locally or from CI.

## Configuration

Configuration is mostly command-line driven: provide the target repository, choose the output file, and decide whether to include prereleases or drafts. The first run is light if GitHub Releases are already well written.

```bash
changelog-from-release --output CHANGELOG.md owner/repo
```

The setup burden is editorial rather than technical. If old release bodies are inconsistent, the generated changelog will faithfully preserve that inconsistency.

## Output Quality

The generated file mirrors GitHub Release content:

```markdown
## v3.9.1 - 2025-10-19

### Changes

- Fix release body extraction for older GitHub Releases
- Update bundled dependencies
```

That is useful for archival work, but it is only as readable as the release notes already stored on GitHub.

## Ecosystem Fit

Because it only depends on GitHub Releases, `changelog-from-release` is language-agnostic and works for any repository hosted on GitHub. It fits best as a one-time migration or occasional sync helper.

It does not replace tools such as Release Drafter, release-please, git-cliff, or Changesets. Those tools decide what should go into the next release; this one recovers what was already published.

## Maintenance Status

- Latest version: **3.9.1**
- Last release: **2025-10-19**
- GitHub stars: **112**
- Appears actively maintained.
- Repository: <a href="https://github.com/rhysd/changelog-from-release" target="_blank" rel="noopener noreferrer">https://github.com/rhysd/changelog-from-release</a>

The project is small but has a recent release in the site metadata. Treat it as a focused utility rather than a broad platform dependency.

## Verdict

**Verdict: Situational**

Use `changelog-from-release` when GitHub Releases are already your historical record and you need to create or refresh a Markdown changelog. Choose a forward-looking generator if you are designing a new release process.
