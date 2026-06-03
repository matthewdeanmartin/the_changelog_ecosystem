Title: cargo-smart-release
Date: 2026-06-02
Slug: cargo-smart-release
Ecosystem: Rust
Tags: cargo-subcommand, rust, workspace, release-orchestration, crates-io, changelog-scaffolding, simulation, conventional-commits, hands-on
Tool_URL: https://crates.io/crates/cargo-smart-release
Tool_Version: 0.21.11
Tool_Status: active
Experiment: examples/rust/cargo-smart-release/
Summary: Hands-on-grounded review of cargo-smart-release, a Gitoxide workspace release tool whose changelog generator works well in its intended context but is opinionated, with non-trivial build prerequisites.



## Overview

`cargo-smart-release` is a Rust workspace release tool from the Gitoxide ecosystem. It is designed for maintainers who need to release multiple interdependent crates without manually reasoning through dependency order, version bumps, publish order, and release notes.

Its changelog feature is intentionally semi-manual: it can scaffold changelog material from commits, but the workflow expects maintainers to polish that text before publishing. That makes it a good fit for teams that dislike raw generated changelogs but still want release automation to carry the tedious parts.

A reproducible hands-on experiment for this tool lives in [`examples/rust/cargo-smart-release/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-smart-release).

## Installation

```bash
cargo install cargo-smart-release --locked
```

There is no pre-built binary; `cargo install` is the only distribution method. In the experiment this exposed a non-trivial dependency chain (see hands-on findings): the tool's transitive dependencies require rustc ≥ 1.88, and `openssl-sys` needs `pkg-config` and `libssl-dev`, none of which are present in a standard `rust:*-slim` image.

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

For a workspace, the key setup is agreeing on release policy and changelog locations. First-run complexity is moderate because the tool is solving workspace release order, not just changelog formatting. Note the hands-on caveat: the crate must be publishable (no `publish = false`) and there must be at least one commit beyond the latest tag, or `cargo changelog` will refuse to run.

## Output Quality

Treat the generated text as scaffolding. The format is distinctive and opinionated — it embeds machine-readable `<csr-id-SHA/>` sentinels and `<csr-read-only-do-not-edit/>` blocks. (The original version of this article showed a small *imagined* changelog block here; it has been replaced by the real generated output in the hands-on section below.)

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

---

## Hands-on findings

This section is grounded in *running* cargo-smart-release in a container, not reading its docs. The reproducible experiment lives in [`examples/rust/cargo-smart-release/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-smart-release).

### What we ran

- **Base image:** `rust:1.89-slim` (upgraded from 1.87 — the tool's transitive dependencies require rustc ≥ 1.88; also added `pkg-config` and `libssl-dev` for `openssl-sys`)
- **Tool version:** `cargo-smart-release 0.21.11` (installed via `cargo install --locked`)
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog.
  2. `cargo changelog --write tipcalc` — fails at HEAD == tag (expected); succeeds after the next commit.
  3. Implement an even-split feature; regenerate changelog.
  4. `cargo smart-release --bump minor tipcalc` dry-run; repeat the loop for v3.0.0.

### Real output

`CHANGELOG.md` after stage 3 (after the v2 commit, before tagging):

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### New Features

 - <csr-id-d06d146c707f0c7014233426b2a54f127e548bca/> split the bill evenly among diners

### Commit Statistics

<csr-read-only-do-not-edit/>

 - 1 commit contributed to the release.
 - 1 commit was understood as [conventional](https://www.conventionalcommits.org).
 - 0 issues like '(#ID)' were seen in commit messages

### Commit Details

<csr-read-only-do-not-edit/>

<details><summary>view details</summary>

 * **Uncategorized**
    - Split the bill evenly among diners (d06d146)
</details>

## v1.0.0 (2026-06-02)

### New Features

 - <csr-id-d5aaa0959ee9d44457c0362c6bfa795b4253836a/> compute tip for a single bill
```

After the v3 breaking-change commit, breaking changes are promoted into their own section:

```markdown
## Unreleased

### New Features (BREAKING)

 - <csr-id-a0d84ac688ad27405aad2c46c47c600f8c067c90/> split the bill unevenly by weight

### New Features

 - <csr-id-d06d146c707f0c7014233426b2a54f127e548bca/> split the bill evenly among diners
```

The `cargo smart-release` dry-run (stage 4a):

```
[INFO ] Manifest version of provided package 'tipcalc' at 2.0.0 is sufficient,
        creating a new release 🎉, ignoring computed version 2.1.0
[INFO ] WOULD modify existing changelog for 'tipcalc'.
[WARN ] To create github releases, please install the 'gh' program and try again
Error: Cannot push in uninitialized repo
```

### Pros (observed)

- **Incremental, non-destructive, idempotent changelog generation.** Reruns append new sections without clobbering existing content; the `<csr-id-SHA/>` sentinels track which commits are already represented. Genuinely useful where changelog commits happen between releases.
- **Breaking changes are first-class.** The `feat!:` commit was correctly separated into `### New Features (BREAKING)` above the regular features, with no `cliff.toml`-style config needed — `!`-suffix handling is built in.
- **Richer output than most tools.** Each section includes "Commit Statistics" (count, conventional ratio, issue links) and an expandable "Commit Details" block with short SHAs — useful for changelogs that double as audit trails.
- **Respects `Cargo.toml` version.** With `--bump minor` it computed 2.1.0 but deferred to the already-bumped 2.0.0 in `Cargo.toml`, preventing accidental double-bumps in human-in-the-loop workflows.

### Cons / pain points (observed)

- **Three Dockerfile fixes required before the tool even installs:** rustc ≥ 1.88 (the slim 1.87 base failed), plus `pkg-config` and `libssl-dev` for `openssl-sys`. The Rust version requirement in particular can be a silent surprise for `cargo install` users.
- **`cargo changelog` refuses to run at HEAD == tag.** Immediately after tagging v1.0.0 it errors with `didn't change and no changelog could be generated`. You cannot backfill a changelog for an already-released commit — there must be a new commit beyond the tag.
- **`publish = false` blocks changelog generation.** The tool checks crates.io publishability before proceeding (`Skipping 'tipcalc' as it won't be published`). For private/local-only crates this is a hard blocker, and the error doesn't suggest the fix.
- **`--allow-dirty` required throughout.** `Cargo.lock` regeneration between stages leaves the tree dirty and the tool refuses to proceed without the flag.
- **`cargo smart-release` dry-run fails without a remote** (`Error: Cannot push in uninitialized repo`). There is no `--local`/`--no-push` path that makes the dry-run fully offline — so the *release simulation* half of the tool could not be completed in the container, even though `cargo changelog` (the changelog half) worked.
- **Chore commits leak into changelogs.** The v2.0.0 section includes `chore: update changelog for 2.0.0` as its own entry; the tool does not strip its own housekeeping commits.
- **`<csr-id-SHA/>` and `<csr-read-only-do-not-edit/>` markers** make the raw file hard to read and effectively prohibit manual curation, despite being clever for idempotency.

### Docs vs. reality

The original article described the tool's workspace focus and changelog scaffolding accurately; the run confirmed both. What it did not address:

1. **Build prerequisites are non-trivial** (recent toolchain, OpenSSL headers, pkg-config).
2. **The `publish = false` gate is a real usability cliff** — likely the first error private-crate users hit, with an unhelpful message.
3. **The changelog format is distinctive and opinionated** — the `<csr-id-…/>` sentinel system is not prominently documented and surprises anyone expecting plain Keep a Changelog Markdown.

## Verdict

**Verdict: Works well in its intended context — multi-crate Gitoxide-style workspaces publishing to crates.io.**

With the correct build environment (rust 1.89, libssl-dev, pkg-config), cargo-smart-release generates changelogs that are *more* structured than git-cliff's default output: breaking changes are promoted, commit statistics are included, and generation is idempotent. The tool is opinionated in ways that suit large public workspaces and will frustrate users of private or single-crate projects who hit the publish-gate and remote-validation walls (the latter prevented the release-simulation step from completing offline in our run). For the narrow use case it targets it is capable and the `<csr-id/>` system genuinely prevents duplicate entries. For everyone else, `git-cliff` offers more flexibility with less friction.
