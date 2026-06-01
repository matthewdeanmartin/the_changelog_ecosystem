Title: changelogithub
Date: 2026-05-31
Slug: changelogithub
Ecosystem: Node
Tags: conventional-commits, github-integration, node, npm-cli, release-notes, contributors, github-releases
Tool_URL: https://www.npmjs.com/package/changelogithub
Tool_Version: 14.0.0
Tool_Status: active
Summary: CLI for generating GitHub release changelogs from Conventional Commits, powered by changelogen.



## Overview

`changelogithub` is a focused CLI for generating or updating GitHub Release notes from Conventional Commits. It is popular in modern JavaScript/TypeScript open source projects that care more about GitHub Releases than a committed `CHANGELOG.md`.

Under the hood it builds on changelogen-style grouping and can include contributors. The workflow is simple: tag a release, run the tool, and let GitHub Releases carry the notes.

## Installation

```bash
npm install --save-dev changelogithub
```

## What It Does

- Generates GitHub release notes from commits.
- Groups Conventional Commits into sections.
- Adds contributor information.
- Can update an existing GitHub Release instead of only creating a new one.
- Runs well in GitHub Actions for tag-triggered releases.

## Configuration

Most projects use CLI flags or a GitHub Actions step. A minimal workflow is compact:

```yaml
name: release
on:
  push:
    tags:
      - 'v*'
jobs:
  notes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - run: npx changelogithub
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

First-run setup is low if tags and Conventional Commits are already in place.

## Output Quality

The output is release-page oriented:

```markdown
### Features

- add typed config loader

### Bug Fixes

- preserve contributor links in generated release notes

### Contributors

- @alice
- @bob
```

It is crisp for GitHub Releases, though projects that need a durable changelog file should pair it with another tool.

## Ecosystem Fit

This feels very native to GitHub-first JS/TS projects. It works nicely with npm scripts, GitHub Actions, tags, and Conventional Commits.

It is less useful for packages that need version bumping, publishing, or monorepo-aware changelogs. Use it when release-note publication is the missing step.

## Maintenance Status

- Latest version: **14.0.0**
- Appears actively maintained.
- Repository: <a href="https://github.com/antfu/changelogithub" target="_blank" rel="noopener noreferrer">https://github.com/antfu/changelogithub</a>

The project remains active in the modern unjs/antfu toolchain orbit.

## Verdict

**Verdict: Recommended**

Use `changelogithub` for GitHub Release notes in Conventional Commits-driven JS/TS projects. It is deliberately narrow, which is exactly why it is pleasant when GitHub Releases are the target.
