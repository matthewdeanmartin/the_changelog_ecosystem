Title: release-plz
Date: 2026-06-02
Slug: release-plz
Ecosystem: Rust
Tags: github-integration, gitlab-integration, rust, rust-cli-ci, semantic-versioning, release-pr, crates-io, changelog-file, ci-cd, git-cliff, hands-on
Tool_URL: https://crates.io/crates/release-plz
Tool_Version: 0.3.158
Tool_Status: active
Experiment: examples/rust/release-plz/
Summary: Hands-on-grounded review of release-plz, the most complete Rust release automation tool — a CI-native release-PR/publish layer over git-cliff, with limited local utility because crates.io is its version source of truth.



## Overview

`release-plz` is the most complete Rust-specific release automation tool in this survey. It analyzes a crate or workspace, opens a release pull request that updates versions and changelogs, and then publishes to crates.io plus GitHub, Gitea, or GitLab when that release is approved.

Its changelog story is powered by `git-cliff`, so it fits projects that already use structured commits or are willing to tune commit parsing. The main distinction from plain `git-cliff` is workflow: `release-plz` turns generated notes into a release PR and publish step instead of only writing a changelog file.

A reproducible hands-on experiment for this tool lives in [`examples/rust/release-plz/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/release-plz).

## Installation

```bash
cargo install release-plz
```

(In the experiment, release-plz was used as a pre-built musl binary; `cargo` is still needed at runtime because release-plz packages crates to compute version deltas.)

## What It Does

- Opens a release PR that updates `Cargo.toml`, `Cargo.lock`, and `CHANGELOG.md`.
- Generates changelogs from git history using `git-cliff` as a library.
- Computes version bumps for changed crates and supports Cargo workspaces.
- Publishes crates to crates.io after the release PR is merged.
- Creates tags and releases on GitHub, GitLab, or Gitea.
- Provides separate commands for `release-pr`, `release`, `update`, and `set-version`.

> **Discoverability gotcha (observed):** there is **no `release-plz changelog` subcommand** in v0.3.158 — invoking it returns `error: unrecognized subcommand 'changelog'`. Despite docs/blog references to previewing notes that way, the only command that generates a changelog is `release-plz update`.

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

Typical CI uses one job to run `release-plz release-pr` on the default branch, then a release job that runs `release-plz release` after the PR lands. First-run setup is moderate: tokens, registry credentials, and changelog preferences all need to be deliberate. The hands-on run confirmed that setting `publish = false` and `git_release_enable = false` is enough to run `release-plz update` fully offline.

## Output Quality

Release-plz output is as good as the underlying git history and `git-cliff` configuration. Here is the *real* changelog produced by `release-plz update` in the hands-on run (replacing the imagined example the original article showed), with **zero** `[git]`/`[changelog]` config beyond the top-level workspace settings:

```markdown
# Changelog

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill
- Split the bill evenly among diners
```

In a real CI flow the PR workflow is the important quality control: generated notes can be reviewed and edited before publishing, which gives teams a better safety margin than a fully invisible publish step.

## Ecosystem Fit

Release-plz feels highly native to Rust. It understands Cargo metadata, crates.io publishing, workspaces, tags, and the common GitHub Actions release-PR pattern. For library crates, it addresses the actual pain point: "what changed, what version should this crate be, and can we publish it without a bespoke script?"

It is less compelling for applications that only need binary artifacts and GitHub Releases; those projects may pair `git-cliff` with `cargo-dist` instead. It is also a poor fit as a *pure local* changelog generator — see the hands-on findings on the crates.io dependency.

## Maintenance Status

- Latest version: **0.3.158**
- Last release: **2026-05-10**
- GitHub stars: **1,379**
- Appears actively maintained.
- Repository: <a href="https://github.com/release-plz/release-plz" target="_blank" rel="noopener noreferrer">https://github.com/release-plz/release-plz</a>

The docs are current and cover release PRs, publishing, changelog configuration, semver checks, GitHub/GitLab/Gitea support, and CI setup.

---

## Hands-on findings

This section is grounded in *running* release-plz in a container, not reading its docs. The reproducible experiment lives in [`examples/rust/release-plz/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/release-plz).

### What we ran

- **Base image:** `rust:1.87-slim` (cargo required at runtime; release-plz itself is a pre-built musl binary)
- **Tool version:** `release-plz 0.3.158`
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog.
  2. `release-plz changelog` — tested as a subcommand (it does not exist).
  3. Implement even-split feature; `release-plz update` — bumps version + writes `CHANGELOG.md`.
  4. Tag v2.0.0 manually; attempt `release-plz update` again for v3.0.0.

### Real output

After a second `release-plz update` attempt for v3.0.0 (stage 4b), the tool printed:

```
INFO determining next version for tipcalc 1.0.0
INFO tipcalc: next version is 1.0.0
INFO the repository is already up-to-date
```

No new `CHANGELOG.md` entry was written — only the single v1.0.0 section (shown in Output Quality above) was ever produced.

### Pros (observed)

- **`release-plz update` works entirely offline with `publish = false`.** Setting `publish = false` and `git_release_enable = false` suppressed all network-dependent behavior. The tool produced a valid `CHANGELOG.md` and bumped `Cargo.toml` in a headless container — in one command.
- **Zero changelog config needed.** It parsed `feat:` commits and produced a grouped, dated, Keep-a-Changelog-compatible file without any `[git]`/`[changelog]` config.
- **Clear, actionable warnings.** Missing remote URL, missing crates.io package, and "already up-to-date" were all explicit INFO/WARN messages, not silent failures.
- **Single command for the combined update.** One `release-plz update` bumps the version, writes the changelog, and optionally commits — significantly less ceremony than the separate git-cliff + version-bump workflow.

### Cons / pain points (observed)

- **`release-plz changelog` does not exist in v0.3.158** (`error: unrecognized subcommand 'changelog'`). The only generation path is `release-plz update`.
- **crates.io is the version source of truth, not git tags.** release-plz queries the registry to determine "what is already released" and computes the next version as a delta. Because the `tipcalc` fixture is unpublished, it could not advance past 1.0.0 — a second `release-plz update` reported `already up-to-date` regardless of new commits or local tags. This is a fundamental design constraint, not a bug.
- **Multi-release simulation fails in a purely local scenario.** Only one changelog entry (v1.0.0) was ever produced; both the even-split and uneven-split features were attributed to 1.0.0 because release-plz had no crates.io history to distinguish them.
- **No hyperlinks without a remote.** `Cannot determine repo url` is harmless but means the changelog has no `[1.0.0]: https://...` comparison links.
- **`release-plz release-pr` and `release-plz release` require GitHub.** These are the primary value-add commands (open a release PR; publish after merge) and cannot be demonstrated in a local container — the tool's main workflow is fundamentally CI-native.

### Docs vs. reality

The original article accurately described the overall workflow and the crates.io dependency. What it did not make explicit:

1. **The `changelog` subcommand does not exist** (at least in 0.3.158), despite docs/blog references to it.
2. **The local-only workflow is limited to a single release cycle** — release-plz cannot advance past v1.0.0 without a real published crate, so multi-release simulation in isolation is impossible.
3. **The tool is primarily a CI automation layer over git-cliff.** Locally, `release-plz update` is a useful preview/version-bump; the full value requires GitHub tokens, a real remote, and crates.io.

The original article's description of the PR-based release workflow is accurate — we simply cannot demonstrate it locally.

## Verdict

**Verdict: Recommended for crates.io + GitHub projects; CI-native with limited local utility.**

release-plz is an excellent choice for Rust projects that publish to crates.io and use GitHub (or GitLab/Gitea), where it delivers a fully automated release PR → publish workflow with `git-cliff`-powered changelogs and a human-reviewed PR before anything ships. The hands-on run confirmed that `release-plz update` produces a clean changelog offline with almost no configuration — but it also confirmed that crates.io is the version source of truth, so release-plz cannot simulate a multi-version history in isolation. For teams that need a pure local changelog generator, git-cliff is the better fit; for teams that want the full release automation story, release-plz is the strongest Rust-native answer.
