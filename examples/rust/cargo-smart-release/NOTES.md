# cargo-smart-release Experiment Notes

## Environment
- Base image: rust:1.89-slim (upgraded from 1.87-slim; dependencies require rustc >= 1.88)
- Tool version: cargo-smart-release 0.21.11 (installed via `cargo install --locked`)
- Run date: 2026-06-01

## Build notes

The Dockerfile originally specified `rust:1.87-slim`. The build failed because
`cargo-smart-release 0.21.11` transitively depends on `cargo-platform 0.3.2`,
`home 0.5.12`, and `smol_str 0.3.5`, which all require rustc >= 1.88 or 1.89.
The base image was updated to `rust:1.89-slim`. Additionally, `pkg-config` and
`libssl-dev` were missing from the apt layer; `openssl-sys` requires them at
compile time. Both were added to the Dockerfile.

`--allow-dirty` was also needed for `cargo changelog --write` and
`cargo smart-release` in the experiment script because version-bump commits
cause Cargo.lock to be regenerated, leaving the working tree dirty.

## Observations

### What worked

- After fixing the Dockerfile (rust 1.89, pkg-config, libssl-dev) the tool
  compiled and installed successfully.
- `cargo changelog --write tipcalc --allow-dirty` successfully created
  CHANGELOG.md in Stage 3 after the first new commit beyond the v1.0.0 tag.
  The generated file uses Keep a Changelog format and includes structured
  "New Features", "Commit Statistics", and expandable "Commit Details" sections.
- Changelog generation is **incremental and non-destructive**: running it again
  in Stage 4b correctly appended new sections for the breaking-change commit
  (`feat!: split the bill unevenly by weight`) while preserving existing content.
- `feat!` commits are correctly classified as "New Features (BREAKING)" — the
  tool understands the Conventional Commits `!` breaking-change suffix.
- The `cargo smart-release` dry-run (Stage 4a) produced useful output despite
  not completing: it showed version detection logic (computed 2.1.0 from the
  bump flag, then deferred to the 2.0.0 already in Cargo.toml) and reported
  what changelog operations WOULD be performed.

### What failed / friction

- **"Crate didn't change" error at HEAD == tag**: Immediately after tagging
  v1.0.0, `cargo changelog` refuses to run — it reports "The given crate
  'tipcalc' didn't change and no changelog could be generated." The tool only
  generates changelogs when there are commits beyond the most recent tag. This
  is an opinionated design: you cannot generate a changelog "from scratch"
  retroactively for an already-released commit.
- **"Won't be published" gate**: The initial error message was
  `[INFO ] Skipping 'tipcalc' as it won't be published.` The tool checks
  `publish = false` in Cargo.toml (or absence of a crates.io publish config)
  before generating changelogs. For local-only or private crates this is a
  hard blocker unless the Cargo.toml is configured for publishing.
- **Fatal error on missing remote**: `cargo smart-release` dry-run exits with
  `Error: Cannot push in uninitialized repo` even in dry-run mode. The tool
  unconditionally validates that a git remote exists, so it cannot be used in
  a fully offline/local repository even for preview purposes.
- **crates.io index dependency**: Two warnings appeared about the crates.io
  index not existing. The tool uses the index to check whether the proposed
  release version has already been published; without it, some version-bump
  logic is degraded.
- **Changelog commits included as "Chore"**: The v2.0.0 section in the final
  CHANGELOG.md includes `chore: update changelog for 2.0.0` as its own entry.
  The tool does not strip its own housekeeping commits from the changelog, which
  creates noise.

### Surprising findings

- **Version detection defers to Cargo.toml**: When `--bump minor` was passed,
  the tool computed version 2.1.0 but then said "Manifest version at 2.0.0 is
  sufficient, creating a new release, ignoring computed version 2.1.0." The tool
  respects the already-bumped Cargo.toml version and does not override it. This
  is sensible for human-in-the-loop workflows but unexpected in automation.
- **`<csr-id-…/>` sentinel tags in the file**: Each changelog entry includes a
  machine-readable `<csr-id-SHA/>` tag inline with the text. These allow the
  tool to deduplicate entries across runs and detect which commits are already
  represented. This is a clever design for idempotent generation, but it makes
  the raw CHANGELOG.md harder to read and edit manually.
- **`<csr-read-only-do-not-edit/>` sections**: Statistics and details blocks
  are marked read-only. If a human edits those blocks the tool may overwrite or
  corrupt them. This restricts manual changelog curation.
- **Designed for gitoxide's own release workflow**: cargo-smart-release is built
  to manage the `gitoxide`/`gix` workspace of 50+ interdependent crates. It
  assumes a crates.io publishing workflow, a GitHub remote, and the `gh` CLI.
  For single-crate or private-registry use it is significantly over-engineered
  and under-documented for simpler scenarios.
- **`gh` required for GitHub releases**: An explicit warning fires:
  "To create github releases, please install the 'gh' program and try again."
  The tool couples changelog generation to GitHub release creation.

## Full transcript

```
tool under test:
cargo-smart-release cargo-smart-release v0.21.11:

==================== STAGE 1: v1.0.0 code, tagged ====================

(no CHANGELOG.md yet)

==================== STAGE 2: cargo changelog --write tipcalc ====================

--- cargo changelog --write tipcalc ---
(Note: immediately after tagging v1.0.0, the tool reports 'no changes' since HEAD == tag)
--- attempting cargo changelog preview (no --write) ---
[INFO ] Skipping 'tipcalc' as it won't be published.
Error: The given crate 'tipcalc' didn't change and no changelog could be generated.
(cargo changelog preview failed — expected: no commits beyond the tag)
(no CHANGELOG.md yet)

==================== STAGE 3: implement even split; add commit ====================

--- cargo changelog --write tipcalc (after new commit) ---
[INFO ] Will write 3 sections to CHANGELOG.md (created)
[INFO ] Wrote 1 changelogs
----- CHANGELOG.md -----
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

### Commit Statistics

<csr-read-only-do-not-edit/>

 - 1 commit contributed to the release.
 - 1 commit was understood as [conventional](https://www.conventionalcommits.org).
 - 0 issues like '(#ID)' were seen in commit messages

### Commit Details

<csr-read-only-do-not-edit/>

<details><summary>view details</summary>

 * **Uncategorized**
    - Compute tip for a single bill (d5aaa09)
</details>

------------------------

==================== STAGE 4a: cargo smart-release --bump minor tipcalc (dry-run) ====================

--- cargo smart-release dry-run ---
[WARN ] Consider running with --update-crates-index to assure bumping on demand uses the latest information
[WARN ] Crates.io index doesn't exist. Consider using --update-crates-index to help determining if release versions are published already
[INFO ] Manifest version of provided package 'tipcalc' at 2.0.0 is sufficient, creating a new release 🎉, ignoring computed version 2.1.0
[INFO ] WOULD modify existing changelog for 'tipcalc'.
[INFO ] Up to 1 changelog would be previewed if the --execute is set and --no-changelog-preview is unset.
[WARN ] To create github releases, please install the 'gh' program and try again
Error: Cannot push in uninitialized repo
(cargo smart-release dry-run output above)
----- CHANGELOG.md -----
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

### Commit Statistics

<csr-read-only-do-not-edit/>

 - 1 commit contributed to the release.
 - 1 commit was understood as [conventional](https://www.conventionalcommits.org).
 - 0 issues like '(#ID)' were seen in commit messages

### Commit Details

<csr-read-only-do-not-edit/>

<details><summary>view details</summary>

 * **Uncategorized**
    - Compute tip for a single bill (d5aaa09)
</details>

------------------------

==================== STAGE 4b: implement uneven split; cargo changelog for v3.0.0 ====================

[INFO ] Will write 4 sections to CHANGELOG.md (modified)
[INFO ] Wrote 1 changelogs
----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### New Features (BREAKING)

 - <csr-id-a0d84ac688ad27405aad2c46c47c600f8c067c90/> split the bill unevenly by weight

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
    - Split the bill unevenly by weight (a0d84ac)
</details>

## 2.0.0 (2026-06-02)

### Chore

 - <csr-id-80c5131b0da60769fcf21365d04f1b22070198e1/> update changelog for 2.0.0

### New Features

 - <csr-id-d06d146c707f0c7014233426b2a54f127e548bca/> split the bill evenly among diners

### Commit Statistics

<csr-read-only-do-not-edit/>

 - 2 commits contributed to the release.
 - 2 commits were understood as [conventional](https://www.conventionalcommits.org).
 - 0 issues like '(#ID)' were seen in commit messages

### Commit Details

<csr-read-only-do-not-edit/>

<details><summary>view details</summary>

 * **Uncategorized**
    - Update changelog for 2.0.0 (80c5131)
    - Split the bill evenly among diners (d06d146)
</details>

## v1.0.0 (2026-06-02)

### New Features

 - <csr-id-d5aaa0959ee9d44457c0362c6bfa795b4253836a/> compute tip for a single bill

### Commit Statistics

<csr-read-only-do-not-edit/>

 - 1 commit contributed to the release.
 - 1 commit was understood as [conventional](https://www.conventionalcommits.org).
 - 0 issues like '(#ID)' were seen in commit messages

### Commit Details

<csr-read-only-do-not-edit/>

<details><summary>view details</summary>

 * **Uncategorized**
    - Compute tip for a single bill (d5aaa09)
</details>

------------------------

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 20
drwxrwxrwx 1 root root 4096 Jun  2 03:17 .
drwxr-xr-x 1 root root 4096 Jun  2 03:17 ..
-rw-r--r-- 1 root root 2106 Jun  2 03:17 CHANGELOG.md
-rw-r--r-- 1 root root  284 Jun  2 03:17 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:17 git-tags.txt
-rw-r--r-- 1 root root 6918 Jun  2 03:17 transcript.txt
```
