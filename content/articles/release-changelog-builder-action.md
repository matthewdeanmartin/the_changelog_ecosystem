Title: Release Changelog Builder
Date: 2026-07-01
Slug: release-changelog-builder-action
Ecosystem: GitHub Actions
Tags: github-action, github-integration, release-notes, custom-templates, categorization
Tool_URL: https://github.com/marketplace/actions/release-changelog-builder
Tool_Status: active
Summary: GitHub Action that builds highly customizable release notes from the pull requests and commits between two references.

## Overview

`release-changelog-builder-action` (mikepenz) assembles release-note text from the pull requests and commits between two git references. Unlike Release Drafter, it does not maintain a running draft; it produces a changelog string on demand — typically inside a tag or release workflow — that you then feed to a release-creation step.

Its distinguishing feature is a rich templating and categorization engine: labels, PR titles, and regular expressions decide which section each change lands in, and placeholders control the exact output shape.

## Installation

```yaml
- uses: mikepenz/release-changelog-builder-action@v5
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## What It Does

- Computes the set of merged PRs / commits between `fromTag` and `toTag`.
- Sorts them into categories by label rules or title regexes.
- Renders a template with placeholders such as `#{{TITLE}}`, `#{{AUTHOR}}`, `#{{NUMBER}}`.
- Exposes the built changelog as a step output for a downstream release step.
- Supports duplicate handling, ignore rules, and empty-section suppression.

## Configuration

Behavior lives in a `configuration.json` referenced from the workflow. A minimal config maps labels to sections and sets a template.

```json
{
  "categories": [
    { "title": "## Features", "labels": ["feature"] },
    { "title": "## Fixes", "labels": ["bug"] }
  ],
  "template": "#{{CHANGELOG}}",
  "pr_template": "- #{{TITLE}} (##{{NUMBER}})"
}
```

First-run setup is moderate: the defaults produce usable output, but getting clean categories requires a consistent label or PR-title convention. The configuration surface is large, which is both its strength and its main cost.

## Output Quality

```markdown
## Features

- Add hosted changelog preview (#241)

## Fixes

- Keep draft notes when a patch branch is retagged (#248)
```

Output quality is high when labels are disciplined and can approach hand-written notes. Without a label convention it falls back to PR titles, so quality tracks how PRs are written.

## Ecosystem Fit

GitHub-native and language-neutral. It fits projects that publish GitHub Releases and want the note body computed at release time rather than accumulated in a draft. It does not bump versions, edit `CHANGELOG.md`, or publish packages — pair it with a release-creation action.

## Maintenance Status

- Actively maintained with a large install base.
- Repository: <a href="https://github.com/mikepenz/release-changelog-builder-action" target="_blank" rel="noopener noreferrer">https://github.com/mikepenz/release-changelog-builder-action</a>

## Verdict

**Verdict: Recommended**

A strong choice when you want templated, category-driven GitHub Release notes computed per release and have (or can adopt) a label convention. Prefer Release Drafter if you would rather accumulate an editable draft as PRs merge, or release-please / semantic-release if version bumping and publishing should be automated in the same flow.
