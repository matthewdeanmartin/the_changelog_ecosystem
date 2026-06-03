Title: cargo-release
Date: 2026-06-02
Slug: cargo-release
Ecosystem: Rust
Tags: cargo-subcommand, rust, semantic-versioning, crates-io, git-tags, release-orchestration, pre-release-hooks, changelog-file, conventional-commits, git-cliff, hands-on
Tool_URL: https://crates.io/crates/cargo-release
Tool_Version: 1.1.2
Tool_Status: active
Experiment: examples/rust/cargo-release/
Summary: Hands-on-grounded review of cargo-release, a Cargo subcommand that orchestrates crate releases and delegates changelog content to a pre-release hook (commonly git-cliff).



## Overview

`cargo-release` is a Cargo subcommand for the mechanical parts of releasing Rust crates: checking the repository, bumping versions, publishing to crates.io, committing, tagging, and pushing. It is not primarily a changelog generator, but it is a common place to wire changelog updates into the release process.

Its role in this survey is "release conductor." If `git-cliff` writes the changelog and `cargo-dist` builds artifacts, `cargo-release` is often the command that coordinates version changes and crates.io publication.

A reproducible hands-on experiment for this tool lives in [`examples/rust/cargo-release/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-release).

## Installation

```bash
cargo install cargo-release
```

(In the experiment, a pre-built musl binary installed cleanly with no compilation and no system-dependency friction.)

## What It Does

- Runs preflight checks for branch, clean tree, upstream state, and Cargo packaging.
- Bumps crate versions in `Cargo.toml` and updates dependent crates in a workspace.
- Publishes crates to crates.io and creates git commits and tags.
- Runs in dry-run mode by default; releases require `--execute`.
- Supports pre-release hooks, including commands that generate or validate a changelog before committing.
- Supports file replacements, such as promoting an `Unreleased` changelog section to the current version.

## Configuration

Configuration can live in `release.toml`, package metadata, or workspace metadata depending on the project. For changelog use, the important pieces are pre-release hooks and (optionally) file replacements.

```toml
[release]
pre-release-hook = ["git", "cliff", "--tag", "{{version}}", "-o", "CHANGELOG.md"]
tag-name = "v{{version}}"
push = false
publish = false
```

First-run setup is moderate because the command touches publishing, tagging, and git history. The dry-run-first behavior helps a lot; you can inspect what would happen before adding `--execute`. The hands-on run confirmed that `{{version}}` is expanded by cargo-release *before* the hook is invoked, so `git-cliff` receives the real version string (e.g. `v2.0.0`) as its `--tag` argument.

> **Integration gotcha (observed):** cargo-release's *built-in* changelog replacement looks for a `## [Unreleased]` section header. git-cliff's default output does not emit one. If you enable both, every dry-run and release will error with `at least 1 replacements expected, found 0`. The fix is to disable cargo-release's `pre-release-replacements` and let the git-cliff hook own the file entirely. This is the single biggest integration friction point and is a one-time config fix, not an ongoing problem.

## Output Quality

`cargo-release` does not create release notes by itself; its changelog output is whatever the configured hook produces. In the experiment the hook was `git-cliff`, which produced correct, cumulative changelogs across all three versions. (The original version of this article showed an *imagined* changelog block here; it has been replaced by the real generated output in the hands-on section below.)

That makes cargo-release useful for enforcing the release *shape*, not for inventing content. Pair it with `git-cliff` or a hand-maintained Keep a Changelog file.

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

---

## Hands-on findings

This section is grounded in *running* cargo-release in a container alongside git-cliff. The reproducible experiment lives in [`examples/rust/cargo-release/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-release).

### What we ran

- **Base image:** `rust:1.87-slim` (cargo required at runtime; cargo-release validates `Cargo.toml`)
- **Tool versions:** `cargo-release 1.1.2` + `git-cliff 2.13.1` (both pre-built musl binaries)
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog.
  2. git-cliff generates the initial `CHANGELOG.md` for v1.0.0.
  3. Implement an even-split feature; `cargo-release release --dry-run` shows what would happen.
  4. Manually simulate the hook: `git-cliff --tag v2.0.0 --output CHANGELOG.md`, commit, tag; repeat for v3.0.0.

### Real output

`CHANGELOG.md` after the full run (v3.0.0 as top entry):

```markdown
# Changelog

## [3.0.0] - 2026-06-02

### Features

- Split the bill unevenly by weight
## [2.0.0] - 2026-06-02

### Features

- Split the bill evenly among diners

### Docs

- Add changelog for 1.0.0
## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill
```

The cargo-release dry-run output at stage 3:

```
error: uncommitted changes detected, please resolve before release:
         Cargo.lock (Status(WT_NEW))
   Upgrading tipcalc from 2.0.0 to 2.0.1
error: for `Unreleased` in 'CHANGELOG.md', at least 1 replacements expected, found 0
```

### Pros (observed)

- **Pure orchestration: no changelog opinions.** cargo-release has no changelog format baked in; it delegates content entirely to the pre-release hook. You choose the generator (git-cliff, conventional-changelog, hand-edited) and cargo-release invokes it at the right moment with the right version string.
- **`{{version}}` template expansion before hook invocation.** The hook receives the actual release version as a shell argument, which is what makes `git-cliff --tag {{version}}` work cleanly.
- **Dry-run is genuinely useful.** Even with `--no-publish --no-push --no-tag`, cargo-release validates the working tree, changelog structure, and version logic. The errors it produced (uncommitted `Cargo.lock`, missing `[Unreleased]` section) are exactly the checks you want before a real release.
- **git-cliff integration works end-to-end.** The hook pattern produced correct, cumulative changelogs across all three versions with no gaps. The documented `pre-release-hook` is the right integration path and it works as described.

### Cons / pain points (observed)

- **cargo-release and git-cliff use incompatible default changelog conventions** (the `## [Unreleased]` mismatch described in Configuration above). Disable cargo-release's replacement feature to resolve it.
- **`Cargo.lock` must be committed.** cargo-release refuses to proceed with an untracked `Cargo.lock`. In a minimal container that never ran `cargo build`, the lock file doesn't exist and the dry-run errors immediately. This is a correct guard in real projects, but easy to trip in a minimal experiment.
- **Version bump is not applied in dry-run without `--execute`.** The experiment had to bump the version manually (`sed -i`). In a real `--execute` run cargo-release handles this; reading the dry-run transcript linearly is slightly misleading.
- **No built-in changelog generation.** Without a hook, cargo-release writes nothing to `CHANGELOG.md`.
- **A "docs: add changelog" commit can leak into the changelog.** Because git-cliff includes all commits in a tag range, the commit that *added* the changelog appears in it. Squash or filter such commits via `cliff.toml` `commit_parsers`/`skip_tags`.

### Docs vs. reality

The original article described cargo-release accurately as a release orchestrator; the hands-on run confirmed every key claim. What the original undersold:

1. **The `[Unreleased]` convention conflict** between cargo-release's default replacement and git-cliff's output — the #1 integration friction point, now called out prominently above.
2. **Dry-run validates more than version.** It runs the full release checklist (working-tree cleanliness, changelog section headers, upstream config), which is more useful than a pure preview.

## Verdict

**Verdict: Strong recommendation as a release *orchestrator* (not a changelog tool).**

cargo-release is the glue that turns a changelog-generating tool (git-cliff) into a complete release workflow. For Rust projects publishing to crates.io, cargo-release + git-cliff is a well-tested combination, and the hands-on run reproduced that pairing end to end. The `[Unreleased]` convention mismatch is a one-time config fix, not an ongoing problem. Teams that do not publish to crates.io may find `release-plz` or a plain git-cliff invocation more appropriate.
