Title: Changesets
Date: 2026-05-31
Slug: changesets
Ecosystem: Node
Tags: keep-a-changelog, monorepo, news-fragments, node, npm-cli, package-publishing, semantic-versioning, release-pr, changelog-file
Tool_URL: https://www.npmjs.com/package/@changesets/cli
Tool_Version: 2.31.0
Tool_Status: active
Summary: File-based release intent workflow for packages and monorepos; contributors add changeset files that drive version bumps, changelogs, and publishing.



## Overview

Changesets is the dominant file-based release intent workflow for Node package monorepos. Contributors add small Markdown changeset files that declare which packages changed, what bump level they need, and the human-facing note that should land in the changelog.

Compared with semantic-release, Changesets moves release intent out of commit messages and into reviewable files. That makes it especially strong for multi-package repositories where a single pull request can affect several packages differently.

## Installation

```bash
npm install --save-dev @changesets/cli
npx changeset init
```

## What It Does

- Creates `.changeset/*.md` files with package bump metadata and prose.
- Aggregates changesets into version bumps and package changelogs.
- Supports monorepos with independent package versions.
- Opens release PRs through the Changesets GitHub Action.
- Publishes packages to npm after the release PR merges.

## Configuration

Configuration lives in `.changeset/config.json`. The defaults work for many repos, but monorepos often customize changelog writers, access, base branch, and update strategy.

```json
{
  "$schema": "https://unpkg.com/@changesets/config/schema.json",
  "changelog": ["@changesets/changelog-github", { "repo": "example/project" }],
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "public",
  "baseBranch": "main",
  "updateInternalDependencies": "patch"
}
```

First-run setup is moderate. The CLI can initialize the repo quickly, but the team needs to adopt the habit of requiring a changeset for user-visible package changes.

## Output Quality

Because entries are written by contributors, output is usually more intentional than raw commit logs:

```markdown
## @example/button@2.1.0

### Minor Changes

- Add keyboard navigation support for segmented controls.

### Patch Changes

- Fix focus ring color in high contrast mode.
```

The best output comes when reviewers treat changeset text as documentation, not as a checkbox.

## Ecosystem Fit

Changesets fits modern npm workspaces, pnpm, Yarn, and package monorepos extremely well. It is less tied to Conventional Commits and more tied to explicit release intent.

For single-package projects it can still be useful, but release-it or semantic-release may feel lighter depending on whether the team prefers manual or automated releases.

## Maintenance Status

- Latest version: **2.31.0**
- Appears actively maintained.
- Repository: <a href="https://github.com/changesets/changesets" target="_blank" rel="noopener noreferrer">https://github.com/changesets/changesets</a>

Changesets remains widely used in Node package monorepos and has active documentation for config, versioning, publishing, and GitHub workflows.

## Verdict

**Verdict: Recommended**

Use Changesets when package release intent should be explicit, reviewed, and package-aware. It is the default recommendation for Node monorepos and a strong alternative to commit-message-driven automation.
