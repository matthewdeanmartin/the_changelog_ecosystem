Title: @semantic-release/release-notes-generator
Date: 2026-05-31
Slug: semantic-release-release-notes-generator
Ecosystem: Node
Tags: node, npm-plugin, release-notes, semantic-release, conventional-changelog, conventional-commits
Tool_URL: https://www.npmjs.com/package/@semantic-release/release-notes-generator
Tool_Version: 14.1.1
Tool_Status: active
Summary: semantic-release plugin that generates release note content with conventional-changelog.



## Overview

`@semantic-release/release-notes-generator` is the standard semantic-release plugin for generating release-note text. It wraps conventional-changelog behavior inside semantic-release's plugin lifecycle.

It is not useful on its own; its job is to fill the `generateNotes` step of a semantic-release pipeline.

## Installation

```bash
npm install --save-dev @semantic-release/release-notes-generator
```

## What It Does

- Generates release notes from commits during semantic-release.
- Uses conventional-changelog presets and parser options.
- Passes notes to publishing plugins such as `@semantic-release/github`.
- Supports custom writer and preset configuration.

## Configuration

Configure it in semantic-release:

```json
{
  "plugins": [
    ["@semantic-release/commit-analyzer", { "preset": "conventionalcommits" }],
    ["@semantic-release/release-notes-generator", { "preset": "conventionalcommits" }],
    "@semantic-release/github"
  ]
}
```

First-run setup is low if semantic-release is already configured.

## Output Quality

Generated notes look like conventional-changelog output:

```markdown
### Features

* add prerelease channel notes

### Bug Fixes

* preserve issue links in generated release notes
```

The plugin is reliable, but the prose quality depends on commit messages.

## Ecosystem Fit

This is core semantic-release infrastructure for Node projects. Use it as part of semantic-release, not as an independent changelog tool.

## Maintenance Status

- Latest version: **14.1.1**
- Appears actively maintained.
- Repository: <a href="https://github.com/semantic-release/release-notes-generator" target="_blank" rel="noopener noreferrer">https://github.com/semantic-release/release-notes-generator</a>

## Verdict

**Verdict: Recommended with semantic-release**

Use this plugin when semantic-release owns the release workflow. Outside semantic-release, use `conventional-changelog` directly or a higher-level release tool.
