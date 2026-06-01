Title: release-it
Date: 2026-05-31
Slug: release-it
Ecosystem: Node
Tags: extensible, github-integration, gitlab-integration, node, npm-cli, package-publishing, semantic-versioning, changelog-preview, interactive
Tool_URL: https://www.npmjs.com/package/release-it
Tool_Version: 20.2.0
Tool_Status: active
Summary: Generic CLI tool to automate versioning and package publishing



## Overview

`release-it` is an explicit release command for projects that want automation without handing the entire release decision to CI. It can run interactively for local releases or non-interactively in CI, bump versions, create tags, generate changelog previews, publish packages, and create GitHub/GitLab releases.

It sits between semantic-release and manual scripts: more guided and plugin-friendly than a custom npm script, but less dogmatic than fully automated commit-driven publishing.

## Installation

```bash
npm install --save-dev release-it
```

## What It Does

- Prompts for or computes the next version.
- Runs git checks, commits, tags, and pushes release changes.
- Generates a changelog preview from commits or plugins.
- Publishes to npm and creates GitHub or GitLab releases.
- Supports plugins for Conventional Commits, workspaces, containers, Slack, and custom release steps.

## Configuration

Configuration can live in `.release-it.json`, `.release-it.js`, or `package.json`. A compact setup might look like:

```json
{
  "git": {
    "commitMessage": "chore: release v${version}",
    "tagName": "v${version}"
  },
  "github": {
    "release": true
  },
  "npm": {
    "publish": true
  },
  "plugins": {
    "@release-it/conventional-changelog": {
      "preset": "conventionalcommits"
    }
  }
}
```

First-run setup is moderate: decide what should be local, what should run in CI, and which plugins own changelog text.

## Output Quality

With the conventional-changelog plugin, release notes look familiar:

```markdown
## 20.2.0

### Features

- add dry-run release preview for npm provenance

### Bug Fixes

- keep GitHub release notes aligned with generated changelog
```

The preview step is valuable because maintainers can see the release notes before the release is finalized.

## Ecosystem Fit

`release-it` fits Node projects that want a human-invoked release command, especially libraries and apps where a maintainer still wants to approve the version. Its plugin system makes it adaptable beyond npm.

For fully automated CI releases, semantic-release is cleaner. For monorepo package intent, Changesets is usually better.

## Maintenance Status

- Latest version: **20.2.0**
- Last release: **2026-05-30**
- GitHub stars: **8,966**
- Appears actively maintained.
- Repository: <a href="https://github.com/release-it/release-it" target="_blank" rel="noopener noreferrer">https://github.com/release-it/release-it</a>

The project is actively maintained with current docs for config files, interactive mode, CI mode, plugins, npm, GitHub, and GitLab releases.

## Verdict

**Verdict: Recommended**

Use `release-it` when you want a clear release command with automation, previews, and plugin hooks. It is the best fit for teams that want to automate the ceremony while keeping the release moment explicit.
