Title: cargo-release
Date: 2026-05-31
Slug: cargo-release
Ecosystem: Rust
Tags: cargo-subcommand, rust, semantic-versioning, crates-io, git-tags, release-orchestration, pre-release-hooks, changelog-file
Tool_URL: https://crates.io/crates/cargo-release
Tool_Version: 1.1.2
Tool_Status: active
Summary: Cargo subcommand for crate release automation; commonly combined with git-cliff or cargo-dist for changelog/release pipelines.



## Overview

`cargo-release` is a Cargo subcommand for the mechanical parts of releasing Rust crates: checking the repository, bumping versions, publishing to crates.io, committing, tagging, and pushing. It is not primarily a changelog generator, but it is a common place to wire changelog updates into the release process.

Its role in this survey is “release conductor.” If `git-cliff` writes the changelog and `cargo-dist` builds artifacts, `cargo-release` is often the command that coordinates version changes and crates.io publication.

## Installation

```bash
cargo install cargo-release
```

## What It Does

- Runs preflight checks for branch, clean tree, upstream state, and Cargo packaging.
- Bumps crate versions in `Cargo.toml` and updates dependent crates in a workspace.
- Publishes crates to crates.io and creates git commits and tags.
- Runs in dry-run mode by default; releases require `--execute`.
- Supports pre-release hooks, including commands that generate or validate a changelog before committing.
- Supports file replacements, such as promoting an `Unreleased` changelog section to the current version.

## Configuration

Configuration can live in `release.toml`, package metadata, or workspace metadata depending on the project. For changelog use, the important pieces are pre-release hooks and file replacements.

```toml
pre-release-hook = ["git", "cliff", "--tag", "{{version}}", "-o", "CHANGELOG.md"]

pre-release-replacements = [
  { file = "CHANGELOG.md", search = "Unreleased", replace = "{{version}}" },
  { file = "CHANGELOG.md", search = "ReleaseDate", replace = "{{date}}" },
]

tag-name = "v{{version}}"
publish = true
push = true
```

First-run setup is moderate because the command touches publishing, tagging, and git history. The dry-run-first behavior helps a lot; you can inspect what would happen before adding `--execute`.

## Output Quality

`cargo-release` does not create polished release notes by itself. Its changelog output is whatever the configured hook or replacement produces:

```markdown
## [1.1.2] - 2026-05-31

### Changed

- Update workspace dependency versions before publishing crates.

### Fixed

- Keep release tags aligned with crates.io package versions.
```

That makes it useful for enforcing the release shape, not for inventing content. Pair it with `git-cliff` or a hand-maintained Keep a Changelog file.

## Ecosystem Fit

The fit is excellent for crates.io publishing because the tool extends Cargo instead of replacing it. It understands workspaces, package selection, publishing constraints, and the normal Rust version bump workflow.

For changelogs, treat it as glue. Projects that only need release notes should use `git-cliff`; projects that want release PRs should look at `release-plz`; projects that want one local command to publish a crate can use `cargo-release` effectively.

## Maintenance Status

- Latest version: **1.1.2**
- Last release: **2026-03-24**
- GitHub stars: **1,560**
- Appears actively maintained.
- Repository: <a href="https://github.com/crate-ci/cargo-release" target="_blank" rel="noopener noreferrer">https://github.com/crate-ci/cargo-release</a>

The current project docs and README cover dry runs, workspaces, file replacements, pre-release hooks, publishing, tagging, and related release tools.

## Verdict

**Verdict: Situational**

Use `cargo-release` when you want Cargo-native release orchestration and are comfortable making changelog generation a hook or replacement step. It is not the primary changelog tool in the Rust ecosystem, but it is a dependable release command to pair with one.
