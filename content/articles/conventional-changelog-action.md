Title: Conventional Changelog Action
Date: 2026-07-01
Slug: conventional-changelog-action
Ecosystem: GitHub Actions
Tags: github-action, conventional-commits, semantic-versioning, changelog-file, ci-cd
Tool_URL: https://github.com/marketplace/actions/conventional-changelog-action
Tool_Status: active
Summary: GitHub Action that bumps the version, tags the commit, and updates CHANGELOG.md from Conventional Commits in one step.

## Overview

`conventional-changelog-action` (TriPSs) wraps the `conventional-changelog` toolchain in a single GitHub Action. On each run it reads Conventional Commits since the last tag, computes the next SemVer version, updates `CHANGELOG.md`, and creates a tag and commit — optionally emitting outputs a later step can use to publish a GitHub Release.

It occupies the middle ground between a pure note generator and full release automation: it mutates the repository (changelog file + tag) but leaves publishing to you.

## Installation

```yaml
- uses: TriPSs/conventional-changelog-action@v6
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

## What It Does

- Parses Conventional Commits to determine the version bump.
- Writes or prepends to `CHANGELOG.md`.
- Commits the changelog and bumped version files, then creates a git tag.
- Outputs the new version, tag, and changelog body for downstream steps.
- Supports several preset formats (Angular, conventionalcommits, etc.).

## Configuration

Most projects need only a token and a preset; the defaults commit and tag on the current branch.

```yaml
- uses: TriPSs/conventional-changelog-action@v6
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    preset: conventionalcommits
    output-file: CHANGELOG.md
```

First-run setup is easy if the project already uses Conventional Commits. The main friction is that the action pushes a commit and tag back to the branch, so branch-protection rules and the token's write permissions need attention.

## Output Quality

```markdown
## [1.4.0](https://github.com/acme/widget/compare/v1.3.0...v1.4.0) (2026-07-01)

### Features

* add hosted changelog preview (#241)

### Bug Fixes

* keep draft notes when a patch branch is retagged (#248)
```

Output matches the well-known `conventional-changelog` format. Quality depends entirely on commit-message discipline; non-conforming commits are silently dropped from the notes.

## Ecosystem Fit

Language-neutral and GitHub-native, though it leans toward Node projects because it can bump `package.json`. It suits teams that enforce Conventional Commits and want changelog + tag maintained in CI without adopting the heavier release-please or semantic-release workflows.

## Maintenance Status

- Widely used and actively maintained.
- Repository: <a href="https://github.com/TriPSs/conventional-changelog-action" target="_blank" rel="noopener noreferrer">https://github.com/TriPSs/conventional-changelog-action</a>

## Verdict

**Verdict: Recommended**

A solid, lightweight choice for Conventional-Commits projects that want an updated `CHANGELOG.md` and a tag produced in CI. Choose release-please if you prefer a release-PR review gate, or semantic-release if you want full publish automation rather than just changelog-and-tag.
