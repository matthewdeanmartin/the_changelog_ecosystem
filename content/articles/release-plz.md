Title: release-plz
Date: 2026-05-31
Slug: release-plz
Ecosystem: Rust
Tags: github-integration, gitlab-integration, rust, rust-cli-ci, semantic-versioning, release-pr, crates-io, changelog-file, ci-cd, git-cliff
Tool_URL: https://crates.io/crates/release-plz
Tool_Version: 0.3.158
Tool_Status: active
Summary: Rust crate release automation that updates changelogs with git-cliff, bumps Cargo.toml versions, publishes crates, and creates releases.



## Overview

`release-plz` is the most complete Rust-specific release automation tool in this survey. It analyzes a crate or workspace, opens a release pull request that updates versions and changelogs, and then publishes to crates.io plus GitHub, Gitea, or GitLab when that release is approved.

Its changelog story is powered by `git-cliff`, so it fits projects that already use structured commits or are willing to tune commit parsing. The main distinction from plain `git-cliff` is workflow: `release-plz` turns generated notes into a release PR and publish step instead of only writing a changelog file.

## Installation

```bash
cargo install release-plz
```

## What It Does

- Opens a release PR that updates `Cargo.toml`, `Cargo.lock`, and `CHANGELOG.md`.
- Generates changelogs from git history using `git-cliff` as a library.
- Computes version bumps for changed crates and supports Cargo workspaces.
- Publishes crates to crates.io after the release PR is merged.
- Creates tags and releases on GitHub, GitLab, or Gitea.
- Provides separate commands for `release-pr`, `release`, `update`, and `set-version`.

## Configuration

Release-plz can run with defaults, but real projects normally add `release-plz.toml` and, when changelog formatting matters, a `cliff.toml` file. The release-plz config controls per-package release behavior, changelog settings, registry publishing, and whether release PRs are created.

```toml
[workspace]
changelog_config = "cliff.toml"
git_release_enable = true
publish = true

[[package]]
name = "my-crate"
changelog_path = "CHANGELOG.md"
semver_check = true
```

Typical CI uses one job to run `release-plz release-pr` on the default branch, then a release job that runs `release-plz release` after the PR lands. First-run setup is moderate: tokens, registry credentials, and changelog preferences all need to be deliberate.

## Output Quality

Release-plz output is as good as the underlying git history and `git-cliff` configuration. A release PR commonly produces a changelog section like:

```markdown
## [0.8.0] - 2026-05-31

### Features

- Add workspace-aware changelog generation for unpublished crates.

### Bug Fixes

- Avoid publishing crates whose dependency graph did not change.
```

The PR workflow is the important quality control: generated notes can be reviewed and edited before publishing. That gives teams a better safety margin than a fully invisible publish step.

## Ecosystem Fit

Release-plz feels highly native to Rust. It understands Cargo metadata, crates.io publishing, workspaces, tags, and the common GitHub Actions release-PR pattern. For library crates, it addresses the actual pain point: “what changed, what version should this crate be, and can we publish it without a bespoke script?”

It is less compelling for applications that only need binary artifacts and GitHub Releases; those projects may pair `git-cliff` with `cargo-dist` instead.

## Maintenance Status

- Latest version: **0.3.158**
- Last release: **2026-05-10**
- GitHub stars: **1,379**
- Appears actively maintained.
- Repository: <a href="https://github.com/release-plz/release-plz" target="_blank" rel="noopener noreferrer">https://github.com/release-plz/release-plz</a>

The docs are current and cover release PRs, publishing, changelog configuration, semver checks, GitHub/GitLab/Gitea support, and CI setup.

## Verdict

**Verdict: Recommended**

Use `release-plz` when a Rust crate or workspace wants CI-managed release PRs, generated changelogs, and crates.io publishing in one workflow. It is the strongest Rust-native answer for maintainers who want automation but still want a human-reviewed PR before a release goes out.
