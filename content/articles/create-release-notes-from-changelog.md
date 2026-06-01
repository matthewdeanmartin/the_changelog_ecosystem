Title: Create release notes from changelog
Date: 2026-05-31
Slug: create-release-notes-from-changelog
Ecosystem: Cross
Tags: cross, github-action
Tool_URL: https://github.com/marketplace/actions
Tool_Version: 3.9.1
Tool_Status: active
Summary: GitHub Action that extracts release notes from CHANGELOG.md, optionally combines a static header, and writes RELEASE.md.



## Overview

`Create release notes from changelog` is the GitHub Action wrapper around `changelog-from-release`-style release-note extraction. It is for teams that maintain a human-edited `CHANGELOG.md` and want the matching version section copied into a file that can be uploaded to a GitHub Release.

Its value is simplicity: the changelog remains the source of truth, and the action avoids duplicating release prose in workflow YAML.

## Installation

```yaml
- uses: rhysd/changelog-from-release/action@v3
```

## What It Does

- Finds the section for the release version in `CHANGELOG.md`.
- Writes that section to a release-note file such as `RELEASE.md`.
- Can combine extracted notes with a static header or template content.
- Fits into a GitHub Actions release workflow before a release-publishing step.

## Configuration

Configuration lives in the workflow step. The important inputs are the changelog path, the version or tag to extract, and the output file.

```yaml
- uses: rhysd/changelog-from-release/action@v3
  with:
    file: CHANGELOG.md
    version: ${{ github.ref_name }}
    output: RELEASE.md
```

First-run setup is easy if the changelog headings are predictable. The main risk is heading drift: if release sections are named inconsistently, extraction can miss the intended block.

## Output Quality

The output is copied from the source changelog:

```markdown
## 2.4.0

### Fixed

- Keep the release job from publishing duplicate assets.
- Clarify the migration note for hosted runners.
```

That makes quality highly controllable. Humans write the changelog, and the action just moves the relevant slice into the release workflow.

## Ecosystem Fit

This is a GitHub Actions-native helper, so it fits any language ecosystem already using GitHub Releases. It pairs well with manual changelog policies and with release actions that accept a release body file.

It is not useful for teams that want release notes generated from commits, pull requests, labels, or change fragments.

## Maintenance Status

- Latest version: **3.9.1**
- Last release: **2025-10-19**
- GitHub stars: **112**
- Appears actively maintained.
- Repository: <a href="https://github.com/rhysd/changelog-from-release" target="_blank" rel="noopener noreferrer">https://github.com/rhysd/changelog-from-release</a>

The action inherits the narrow scope and maintenance profile of the underlying project.

## Verdict

**Verdict: Situational**

Use it when `CHANGELOG.md` is authoritative and the release workflow only needs a reliable extraction step. Skip it if the team wants automation to decide release content.
