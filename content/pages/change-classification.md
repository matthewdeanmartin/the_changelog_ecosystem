Title: Change Classification
Date: 2026-06-01
Slug: change-classification
sortorder: 6
Summary: Taxonomies for Added, Changed, Fixed, breaking changes, maintenance work, and tool-specific buckets.

## Purpose

Change classification is where changelog prose meets release automation. Tools need categories to group entries, decide version bumps, and decide what should be visible to users.

This section compares human-facing taxonomies such as Keep a Changelog with older GNU/Gnits-style conventions, Conventional Commits types, Towncrier fragment categories, and the categories exposed by release platforms.

## Core Articles

- [GNU, Gnits, and Historical Change Logs]({filename}../articles/gnu-gnits-historical-change-logs.md)
- [Change Taxonomies Across Tools]({filename}../articles/change-taxonomies-across-tools.md)
- [Keep a Changelog]({filename}../articles/keep-a-changelog.md)
- [towncrier]({filename}../articles/towncrier.md)
- [scriv]({filename}../articles/scriv.md)
- [reno]({filename}../articles/reno.md)

## Classification Axes

- User-visible feature, bug fix, security fix, documentation, maintenance, dependency update.
- Breaking versus non-breaking behavior.
- Public API change versus internal implementation change.
- Release-note worthy versus noise that belongs only in commit history.
