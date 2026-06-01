Title: cargo-smart-release
Date: 2026-05-31
Slug: cargo-smart-release
Ecosystem: Rust
Tags: cargo-subcommand, rust, workspace, release-orchestration, crates-io, changelog-scaffolding, simulation
Tool_URL: https://crates.io/crates/cargo-smart-release
Tool_Version: 0.21.11
Tool_Status: active
Summary: Cargo subcommand for smarter Rust workspace releases, including changelog scaffolding and release simulation.



## Overview

`cargo-smart-release` is a Rust workspace release tool from the Gitoxide ecosystem. It is designed for maintainers who need to release multiple interdependent crates without manually reasoning through dependency order, version bumps, publish order, and release notes.

Its changelog feature is intentionally semi-manual: it can scaffold changelog material from commits, but the workflow expects maintainers to polish that text before publishing. That makes it a good fit for teams that dislike raw generated changelogs but still want release automation to carry the tedious parts.

## Installation

```bash
cargo install cargo-smart-release
```

## What It Does

- Simulates workspace releases before publishing so maintainers can inspect the release plan.
- Determines which crates in a workspace need a release and in what order.
- Bumps versions and publishes crates to crates.io when run with execution flags.
- Provides `cargo changelog` to update changelog scaffolding for a selected crate.
- Leaves room for human editing before the final `cargo smart-release` execution.

## Configuration

The command leans heavily on Cargo workspace metadata and CLI options rather than a large changelog-specific configuration file. A typical workflow is command-driven:

```bash
cargo changelog --write my-crate
$EDITOR my-crate/CHANGELOG.md
cargo smart-release --bump minor my-crate
cargo smart-release --bump minor my-crate --execute
```

For a workspace, the key setup is agreeing on release policy and changelog locations. First-run complexity is moderate because the tool is solving workspace release order, not just changelog formatting.

## Output Quality

The best output comes from treating generated text as scaffolding:

```markdown
## 0.21.11

### Changed

- Refine release simulation output for workspace packages.
- Update dependency constraints for crates released in the same pass.
```

This is a healthier stance than pretending commit summaries are always publication-ready. The tradeoff is that maintainers must budget time for editing before release.

## Ecosystem Fit

`cargo-smart-release` is very Rust-specific and especially workspace-specific. It makes the most sense for multi-crate repositories where publishing order and dependency updates are the real pain.

For a single crate, `release-plz`, `cargo-release`, or direct `git-cliff` may be simpler. For a Gitoxide-style workspace, `cargo-smart-release` maps closely to the maintainers' actual release problem.

## Maintenance Status

- Latest version: **0.21.11**
- Last release: **2026-03-22**
- GitHub stars: **119**
- Appears actively maintained.
- Repository: <a href="https://github.com/GitoxideLabs/cargo-smart-release" target="_blank" rel="noopener noreferrer">https://github.com/GitoxideLabs/cargo-smart-release</a>

The docs.rs README and changelog describe current `cargo changelog` and `cargo smart-release` workflows, including release simulation and human-polished changelog scaffolding.

## Verdict

**Verdict: Situational**

Choose `cargo-smart-release` for complex Rust workspaces where release order and dependency propagation matter as much as the changelog. It is not the general-purpose Rust changelog default, but it is an unusually thoughtful tool for maintainers who want automation plus hand-polished notes.
