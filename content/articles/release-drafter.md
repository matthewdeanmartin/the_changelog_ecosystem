Title: Release Drafter
Date: 2026-05-31
Slug: release-drafter
Ecosystem: Cross
Tags: cross, draft-releases, github-action, github-integration, release-notes
Tool_URL: https://github.com/marketplace/actions
Tool_Version: 7.3.1
Tool_Status: active
Summary: GitHub Action that keeps a draft release updated as PRs merge, grouping release notes by labels and rules.



## Overview

Release Drafter keeps a GitHub draft release continuously updated as pull requests merge. It is for teams that want the release notes to be visible and editable before publication, with PR labels driving categories.

Its center of gravity is human-reviewed GitHub Releases rather than fully automatic publishing.

## Installation

```yaml
- uses: release-drafter/release-drafter@v7
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## What It Does

- Creates or updates a draft GitHub Release.
- Groups pull requests by labels such as `feature`, `bug`, or `maintenance`.
- Uses templates for release names, bodies, categories, and change entries.
- Supports excluding labels and autolabeling based on files or branch names.
- Lets maintainers edit the draft before publishing.

## Configuration

Configuration lives in `.github/release-drafter.yml`, plus a GitHub Actions workflow. A minimal configuration maps labels into sections.

```yaml
categories:
  - title: Features
    labels:
      - feature
  - title: Fixes
    labels:
      - bug
change-template: "- $TITLE @$AUTHOR (#$NUMBER)"
template: |
  ## Changes

  $CHANGES
```

First-run setup is moderate because labels and PR titles need to be cleaned up, but the workflow is straightforward once the label taxonomy is stable.

## Output Quality

Release Drafter produces PR-based notes:

```markdown
## Changes

### Features

- Add hosted changelog preview @alex (#241)

### Fixes

- Keep draft release notes when a patch branch is retagged @sam (#248)
```

The output is usually better than raw generated release notes because categories and templates are explicit. It still depends on PR titles being written for readers.

## Ecosystem Fit

Release Drafter is GitHub-native and language-neutral. It works well for libraries, apps, and infrastructure projects that merge through pull requests and want release notes assembled incrementally.

It does not update version files, publish packages, or maintain `CHANGELOG.md` by default. Pair it with other tooling when those steps matter.

## Maintenance Status

- Latest version: **7.3.1**
- Last release: **2026-05-25**
- GitHub stars: **3,879**
- Appears actively maintained.
- Repository: <a href="https://github.com/release-drafter/release-drafter" target="_blank" rel="noopener noreferrer">https://github.com/release-drafter/release-drafter</a>

The recent release cadence and large install base make it one of the safer GitHub Action choices in this space.

## Verdict

**Verdict: Recommended**

Use Release Drafter when you want GitHub Releases with editable, label-driven notes. Choose release-please or semantic-release if version bumps and publishing should be automated as part of the same flow.
