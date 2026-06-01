Title: @changesets/changelog-github
Date: 2026-05-31
Slug: changesets-changelog-github
Ecosystem: Node
Tags: node, npm-plugin, changesets, github-integration, pull-requests, contributors, changelog-template
Tool_URL: https://www.npmjs.com/package/@changesets/changelog-github
Tool_Version: 0.7.0
Tool_Status: active
Summary: Changesets changelog generator that links changelog entries to GitHub commits, PRs, and users.



## Overview

`@changesets/changelog-github` is a Changesets plugin, not a standalone release workflow. It customizes generated package changelogs so entries link back to GitHub pull requests, commits, and contributors.

Use it when Changesets is already the release system and the missing piece is richer GitHub context in the generated changelog.

## Installation

```bash
npm install --save-dev @changesets/changelog-github
```

## What It Does

- Formats Changesets changelog entries with GitHub links.
- Adds pull request, commit, and author context where available.
- Works inside the Changesets versioning process.
- Improves package changelogs without changing the release model.

## Configuration

Configure it in `.changeset/config.json`:

```json
{
  "changelog": ["@changesets/changelog-github", { "repo": "example/project" }]
}
```

First-run setup is tiny if Changesets is already installed.

## Output Quality

The plugin makes entries more navigable:

```markdown
- Add keyboard navigation support ([#184](https://github.com/example/project/pull/184)) by [@alice](https://github.com/alice)
```

The prose still comes from changeset files, which is the right division of labor.

## Ecosystem Fit

This fits GitHub-hosted npm monorepos using Changesets. It is irrelevant without Changesets and less useful outside GitHub.

## Maintenance Status

- Latest version: **0.7.0**
- Appears active as part of the Changesets package family.
- Repository: <a href="https://github.com/changesets/changesets" target="_blank" rel="noopener noreferrer">https://github.com/changesets/changesets</a>

## Verdict

**Verdict: Recommended with Changesets**

Use `@changesets/changelog-github` when a GitHub-hosted Changesets project wants changelog entries to point back to PRs and contributors. It is a plugin worth enabling, not a separate strategy.
