Title: Changesets Action
Date: 2026-07-01
Slug: changesets-action
Ecosystem: GitHub Actions
Tags: github-action, monorepo, package-publishing, news-fragments, ci-cd
Tool_URL: https://github.com/marketplace/actions/changeset-action
Tool_Status: active
Summary: The official GitHub Action for the Changesets workflow — opens a versioning PR from accumulated changesets and publishes on merge.

## Overview

`changesets/action` is the official GitHub Action for the [Changesets](../changesets/) workflow. Contributors add changeset files to their PRs; this action watches the default branch, and when changesets are present it opens (and keeps updated) a "Version Packages" PR that consumes them, bumps versions, and edits changelogs. Merging that PR triggers publication.

This review covers the action surface only. For the fragment format, monorepo behavior, and when Changesets is the right model, see the [Changesets review](../changesets/).

## Installation

```yaml
- uses: changesets/action@v1
  with:
    publish: pnpm release
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## What It Does

- Detects pending changeset files on the default branch.
- Opens / updates a release PR that runs `changeset version` (bumps + changelog edits).
- On merge, runs the configured `publish` command and can create GitHub Releases.
- Exposes outputs (`published`, `publishedPackages`) for downstream steps.

## Configuration

The action's own inputs are few (`version`, `publish`, `commit`, `title`); the substantive configuration is the standard `.changeset/config.json`. A typical setup wires a publish command and tokens, as shown above.

First-run complexity is Changesets' rather than the action's: deciding on the changeset config, access mode, and publish command. The action itself is straightforward once those are set.

## Output Quality

Changelogs and release notes are produced by Changesets' changelog generator (or a custom one such as `@changesets/changelog-github`); see the engine review for output samples. The action does not shape the text itself.

## Ecosystem Fit

Squarely aimed at JavaScript/TypeScript monorepos publishing to npm, and it is the canonical way to run Changesets in CI. Outside that niche its value drops sharply — the fragment-and-release-PR model is tightly coupled to the npm/pnpm/yarn workspace world.

## Maintenance Status

- Official and actively maintained.
- Repository: <a href="https://github.com/changesets/action" target="_blank" rel="noopener noreferrer">https://github.com/changesets/action</a>

## Verdict

**Verdict: Recommended with caveats**

The standard, reliable way to run Changesets in GitHub Actions — recommended if you have adopted the Changesets model, which is itself best suited to npm monorepos. The real decision is about the [Changesets](../changesets/) workflow, not this action; teams outside the JS ecosystem will usually be better served by release-please or a Conventional-Commits action.
