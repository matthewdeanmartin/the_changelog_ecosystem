Title: Action For Semantic Release
Date: 2026-07-01
Slug: semantic-release-action
Ecosystem: GitHub Actions
Tags: github-action, conventional-commits, semantic-versioning, package-publishing, ci-cd
Tool_URL: https://github.com/marketplace/actions/action-for-semantic-release
Tool_Status: active
Summary: The common GitHub Action entry point for running semantic-release, which drives fully automated versioning, changelogs, and publishing.

## Overview

`semantic-release-action` (cycjimmy) is the most common way to run [semantic-release](../semantic-release/) inside GitHub Actions. It is a thin execution wrapper: the behavior, plugins, and configuration are all semantic-release's — the action mainly handles installing it and running it in the workflow.

Because the engine does the real work, this review covers only the GitHub Actions surface. For how the tool behaves, its plugin model, and when to choose it, see the [semantic-release review](../semantic-release/).

## Installation

```yaml
- uses: cycjimmy/semantic-release-action@v4
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## What It Does

- Installs semantic-release (and optionally listed plugins) and runs it.
- Passes through `GITHUB_TOKEN` / `NPM_TOKEN` for release and publish steps.
- Exposes outputs such as `new_release_version` and `new_release_published`.
- Otherwise defers entirely to your `.releaserc` / `release.config.js`.

## Configuration

The action takes a handful of inputs (semantic-release version, extra plugins, dry-run), but the substantive configuration is the standard semantic-release config file. A minimal setup:

```yaml
- uses: cycjimmy/semantic-release-action@v4
  with:
    extra_plugins: |
      @semantic-release/changelog
      @semantic-release/git
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

First-run complexity is semantic-release's, not the action's: getting the plugin chain right is the real task. The action itself is close to zero-configuration.

## Output Quality

Output (release notes, `CHANGELOG.md`, GitHub Release body) is produced by semantic-release's plugins and is identical to running the CLI locally. See the engine review for samples and caveats.

## Ecosystem Fit

GitHub-native and language-neutral, though semantic-release's roots and plugin ecosystem are strongest for npm publishing. If you have already decided to use semantic-release, this is the standard action to run it with.

## Maintenance Status

- Actively maintained; the de-facto action for semantic-release.
- Repository: <a href="https://github.com/cycjimmy/semantic-release-action" target="_blank" rel="noopener noreferrer">https://github.com/cycjimmy/semantic-release-action</a>

## Verdict

**Verdict: Recommended**

The right way to run semantic-release in GitHub Actions — but the adoption decision is really about the [semantic-release](../semantic-release/) engine, not this wrapper. If full publish-on-merge automation is what you want, use it; if you prefer a review gate before releasing, look at release-please instead.
