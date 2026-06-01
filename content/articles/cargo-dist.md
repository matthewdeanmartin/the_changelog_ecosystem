Title: cargo-dist
Date: 2026-05-31
Slug: cargo-dist
Ecosystem: Rust
Tags: cargo-subcommand-ci, github-integration, rust, release-orchestration, artifacts, installers, ci-cd, github-releases
Tool_URL: https://crates.io/crates/cargo-dist
Tool_Version: 0.32.0
Tool_Status: active
Summary: Rust release distribution tool that generates CI and publishes artifacts/installers to GitHub Releases; often paired with changelog generators.



## Overview

`cargo-dist` is release distribution infrastructure for Rust applications. It generates CI workflows, builds release artifacts, creates installers, uploads checksums and manifests, and announces releases through GitHub Releases or related hosting.

It is adjacent to changelog tooling rather than a primary changelog editor. Its importance here is that many Rust CLI projects need release notes to travel with binaries, installers, and GitHub Releases, and `cargo-dist` is one of the strongest tools for that final distribution step.

## Installation

```bash
cargo install cargo-dist
```

## What It Does

- Generates GitHub Actions workflows for release builds.
- Builds platform artifacts for Rust binaries and other supported projects.
- Produces installers and installation scripts for end users.
- Publishes artifacts, checksums, and manifests to GitHub Releases or other configured hosts.
- Can interoperate with tools such as `cargo-release`, Release Drafter, or a manually maintained release notes file.

## Configuration

Newer projects can use `dist-workspace.toml` or `dist.toml`; Rust projects may also have older `[workspace.metadata.dist]` style configuration. `dist init` creates the baseline config and generated CI workflow.

```toml
[dist]
cargo-dist-version = "0.32.0"
ci = ["github"]
installers = ["shell", "powershell"]
targets = ["x86_64-unknown-linux-gnu", "x86_64-pc-windows-msvc", "aarch64-apple-darwin"]
create-release = true
publish-jobs = ["homebrew"]
```

First-run setup is moderate because the tool touches CI, target platforms, hosting, installers, and release announcements. Changelog configuration is usually handled by a companion tool or by release notes already present in the repository.

## Output Quality

The user-facing output is a release announcement with artifacts attached, not just a changelog file:

```markdown
## my-cli 1.4.0

### Release Notes

- Add native ARM macOS artifacts.
- Generate PowerShell installer checksums during release.

### Artifacts

- my-cli-x86_64-pc-windows-msvc.zip
- my-cli-x86_64-unknown-linux-gnu.tar.xz
- my-cli-aarch64-apple-darwin.tar.xz
```

If the upstream release notes are good, cargo-dist helps package and publish them cleanly. If the project has no changelog discipline, cargo-dist will not fix that by itself.

## Ecosystem Fit

For Rust CLI applications, cargo-dist fits beautifully: it understands Cargo, target triples, generated CI, installers, and GitHub Releases. It fills a gap that crates.io publishing does not cover, especially for end users who expect downloadable binaries.

For libraries, it is usually unnecessary. Library crates care more about crates.io, semver, and changelog text than binary distribution.

## Maintenance Status

- Latest version: **0.32.0**
- Last release: **2026-05-22**
- GitHub stars: **2,044**
- Appears actively maintained.
- Repository: <a href="https://github.com/axodotdev/cargo-dist" target="_blank" rel="noopener noreferrer">https://github.com/axodotdev/cargo-dist</a>

The current docs cover config files, generated CI, custom jobs, publish phases, installer options, GitHub release behavior, and integration patterns with tools such as `cargo-release`.

## Verdict

**Verdict: Situational**

Use `cargo-dist` when the release problem is “ship binaries and installers with solid GitHub Releases.” Pair it with `git-cliff`, Release Drafter, `release-plz`, or a hand-maintained changelog for the actual release-note prose.
