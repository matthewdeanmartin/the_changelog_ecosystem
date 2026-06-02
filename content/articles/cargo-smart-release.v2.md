Title: cargo-smart-release (hands-on synthesis)
Date: 2026-06-02
Slug: cargo-smart-release-v2
Ecosystem: Rust
Tags: cargo-subcommand, rust, workspace, release-orchestration, crates-io, changelog-scaffolding, simulation, hands-on
Tool_URL: https://crates.io/crates/cargo-smart-release
Tool_Version: 0.21.11
Tool_Status: active
Experiment: examples/rust/cargo-smart-release/
Summary: Hands-on re-review after driving cargo-smart-release through the tip-calculator life cycle — changelog generation works once prerequisites are met, with a distinctive machine-readable format.



## What I actually ran

This is a second-pass review grounded in *running* cargo-smart-release, not reading its docs. The
reproducible experiment lives in [`examples/rust/cargo-smart-release/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-smart-release).

- **Base image:** `rust:1.89-slim` (upgraded from 1.87 — the tool's transitive dependencies require rustc ≥ 1.88; also required `pkg-config` and `libssl-dev` for `openssl-sys`)
- **Tool version:** `cargo-smart-release 0.21.11` (installed via `cargo install --locked`)
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog.
  2. `cargo changelog --write tipcalc` — fails at HEAD==tag (expected); succeeds after next commit.
  3. Implement even-split feature; regenerate changelog.
  4. `cargo smart-release --bump minor tipcalc` dry-run; repeat loop for v3.0.0.

## Real output

CHANGELOG.md after stage 3 (after the v2 commit, before tagging):

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

CHANGELOG.md after stage 4b (v3 breaking-change commit added):

```markdown
## Unreleased

### New Features (BREAKING)

 - <csr-id-a0d84ac688ad27405aad2c46c47c600f8c067c90/> split the bill unevenly by weight

### New Features

 - <csr-id-d06d146c707f0c7014233426b2a54f127e548bca/> split the bill evenly among diners

...

## 2.0.0 (2026-06-02)

### Chore

 - <csr-id-80c5131b0da60769fcf21365d04f1b22070198e1/> update changelog for 2.0.0

### New Features

 - <csr-id-d06d146c707f0c7014233426b2a54f127e548bca/> split the bill evenly among diners
```

The `cargo smart-release` dry-run at stage 4a:

```
[INFO ] Manifest version of provided package 'tipcalc' at 2.0.0 is sufficient,
        creating a new release 🎉, ignoring computed version 2.1.0
[INFO ] WOULD modify existing changelog for 'tipcalc'.
[WARN ] To create github releases, please install the 'gh' program and try again
Error: Cannot push in uninitialized repo
```

## Pros (observed)

**Incremental and non-destructive changelog generation.** Running `cargo changelog --write` multiple times appended new sections without clobbering existing content. The tool tracked which commits were already represented via `<csr-id-SHA/>` sentinel tags, so reruns are idempotent — a genuinely useful property for workflows where changelog commits happen between releases.

**Breaking changes are first-class.** The `feat!:` commit was correctly separated into `### New Features (BREAKING)` above the regular `### New Features` section. No cliff.toml configuration was needed — conventional commit `!` suffix handling is built in.

**Richer output than most tools.** Each release section includes "Commit Statistics" (count, conventional ratio, issue links seen) and an expandable "Commit Details" block with short SHAs. For changelogs that double as developer audit trails, this is valuable information.

**Respects Cargo.toml version.** When `--bump minor` was passed, the tool computed 2.1.0 but deferred to the already-bumped 2.0.0 in Cargo.toml. This prevents accidental double-bumps in human-in-the-loop workflows.

## Cons / pain points (observed)

**Three Dockerfile fixes required before the tool even installs.** The original `rust:1.87-slim` base was insufficient — transitive dependencies require rustc ≥ 1.88. Additionally, `openssl-sys` needs `pkg-config` and `libssl-dev` which are absent from slim images. The tool has no pre-built binary; `cargo install` is the only distribution method, and it exposes this dependency chain to every user.

**`cargo changelog` refuses to run at HEAD == tag.** Immediately after tagging v1.0.0, `cargo changelog --write tipcalc` errors with `The given crate 'tipcalc' didn't change and no changelog could be generated.` You cannot backfill a changelog for an already-released commit — there must be at least one new commit beyond the tag. This is an opinionated design that prevents retroactive changelog generation.

**`publish = false` blocks changelog generation.** The tool checks whether a crate is publishable to crates.io before proceeding. For private or local-only crates, this is a hard blocker unless you remove `publish = false` from Cargo.toml. The error message (`Skipping 'tipcalc' as it won't be published`) doesn't immediately suggest this as the fix.

**`--allow-dirty` required throughout.** Cargo.lock changes between stages leave the working tree dirty. Every `cargo changelog` and `cargo smart-release` call needed `--allow-dirty` added to the script. In real projects, Cargo.lock is committed and this is less of an issue — but the tool's default behavior blocks any workflow where the tree isn't perfectly clean.

**`cargo smart-release` dry-run fails without a remote.** Even in dry-run mode, the tool validates remote configuration and fails with `Error: Cannot push in uninitialized repo`. There is no `--local` or `--no-push` flag that makes the dry-run fully offline.

**Chore commits leak into changelogs.** The v2.0.0 section includes `chore: update changelog for 2.0.0` as its own "Chore" entry. The tool does not strip its own housekeeping commits; every changelog-update commit becomes a changelog entry in the next version.

**`<csr-id-SHA/>` tags are machine-readable noise in human-edited files.** While clever for idempotency, inline `<csr-id-…/>` tags make the raw CHANGELOG.md hard to read. Combined with `<csr-read-only-do-not-edit/>` sections, manual curation of the file is effectively prohibited.

## Docs vs. reality

The original `cargo-smart-release.md` article described the tool as designed for multi-crate workspace management and noted its changelog scaffolding capability. The hands-on run confirms both.

What the original article did not address:

1. **Build prerequisites are non-trivial.** The tool needs a recent Rust toolchain (≥ 1.88), system OpenSSL headers, and pkg-config — none of which are present in a standard slim Docker image. For teams installing via `cargo install`, the Rust version requirement in particular can be a silent surprise.
2. **The `publish = false` gate is a significant usability cliff.** It's likely the first error most users of private crates will hit, and the error message doesn't directly explain the workaround.
3. **The changelog format is distinctive and opinionated.** The `<csr-id-…/>` sentinel system and `<csr-read-only-do-not-edit/>` blocks are not mentioned prominently. Teams expecting a standard KAC Markdown file will be surprised.

## Revised verdict

**Upgrade from "narrow recommendation" to "works well in its intended context."** With the correct Dockerfile (rust 1.89, libssl-dev, pkg-config), cargo-smart-release generates changelogs that are more structured than git-cliff's default output — breaking changes are promoted, commit statistics are included, and generation is idempotent. The tool is opinionated in ways that suit large public workspaces (gitoxide-style) and will frustrate users of private or single-crate projects who hit the publish-gate and remote-validation walls.

For the narrow use case it targets — managing multi-crate workspace releases to crates.io with GitHub releases — cargo-smart-release is capable and the `<csr-id/>` system genuinely prevents duplicate changelog entries. For everyone else, git-cliff offers more flexibility with less friction.
