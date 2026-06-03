Title: commit-and-tag-version
Date: 2026-06-02
Slug: commit-and-tag-version
Ecosystem: Node
Tags: conventional-commits, keep-a-changelog, node, npm-cli, semantic-versioning, git-tags, changelog-file, standard-version-fork, hands-on
Tool_URL: https://www.npmjs.com/package/commit-and-tag-version
Tool_Version: 12.5.0
Tool_Status: active
Experiment: examples/node/commit-and-tag-version/
Summary: Maintained standard-version drop-in for Conventional Commits release workflows; hands-on testing drove a full multi-release life cycle with zero configuration and correct semver, including breaking-change detection.



A reproducible hands-on experiment for this tool lives in [`examples/node/commit-and-tag-version/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/node/commit-and-tag-version).

## Overview

`commit-and-tag-version` is a maintained continuation of the standard-version style workflow: analyze Conventional Commits, bump versions, update `CHANGELOG.md`, create a release commit, and tag it.

It is intentionally simpler than semantic-release. A maintainer runs a command, reviews the diff, and pushes the result.

## Installation

```bash
npm install --save-dev commit-and-tag-version
```

## What It Does

- Computes the next semver version from Conventional Commits.
- Updates package metadata such as `package.json` and lockfiles.
- Generates or updates `CHANGELOG.md`.
- Creates a release commit and git tag.
- Supports configuration inherited from the standard-version/conventional-changelog ecosystem.

## Configuration

Most projects add an npm script:

```json
{
  "scripts": {
    "release": "commit-and-tag-version"
  },
  "commit-and-tag-version": {
    "preset": "conventionalcommits",
    "tagPrefix": "v"
  }
}
```

First-run setup is low for single-package repositories. Workspaces and nonstandard version files need more configuration. In the hands-on run, a correct end-to-end release life cycle needed *zero* configuration beyond a `repository` field in `package.json` (used for comparison links).

## Output Quality

The changelog output follows conventional-changelog patterns, with auto-generated comparison links and a `⚠ BREAKING CHANGES` section for breaking commits. See the hands-on section below for the exact output the experiment produced.

## Ecosystem Fit

This fits npm packages that want an explicit local release command and a committed changelog. It is less ambitious than release-it and less automated than semantic-release, which is a virtue for some teams.

It is also a practical migration path for projects that used standard-version and want a maintained equivalent — the CLI flags, output format, and `chore(release)` commit style are unchanged; migration amounts to renaming the package.

## Maintenance Status

- Latest version tested: **12.5.0**
- Appears actively maintained.
- Repository: <a href="https://github.com/absolute-version/commit-and-tag-version" target="_blank" rel="noopener noreferrer">https://github.com/absolute-version/commit-and-tag-version</a>

The project exists largely to keep the standard-version-style workflow alive with current dependencies and maintenance. (Note: npm install prints deprecation warnings for internal dependencies `git-raw-commits` and `git-semver-tags`, being superseded by `@conventional-changelog/git-client`. Upstream noise; no functional impact.)

---

## Hands-On Findings

This section is grounded in actually running `commit-and-tag-version@12.5.0`, not reading its docs.

### What I actually ran

All commands ran inside a `node:20-slim` Docker container with the tool installed globally. The experiment used a small "tip calculator" Node app to simulate a realistic release life cycle:

1. **Stage 1** — initial commit `feat: compute tip for a single bill`.
2. **Stage 2** — `commit-and-tag-version --first-release` to bootstrap the changelog and tag `v1.0.0` without bumping.
3. **Stage 3** — added an even-split feature (`feat: split the bill evenly among diners`) and previewed with `--dry-run`.
4. **Stage 4a** — `commit-and-tag-version` (no flags) to release `v1.1.0`.
5. **Stage 4b** — introduced a breaking change (`feat!: split the bill unevenly by weight`) and released `v2.0.0`.

### Real output

The final `CHANGELOG.md` after all stages:

```markdown
# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## [2.0.0](https://github.com/example/tipcalc/compare/v1.1.0...v2.0.0) (2026-06-02)


### ⚠ BREAKING CHANGES

* split the bill unevenly by weight

### Features

* split the bill unevenly by weight ([c9df1b9](https://github.com/example/tipcalc/commit/c9df1b99779c58ad1da61b7dfb17af58fa169149))

## [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([297060d](https://github.com/example/tipcalc/commit/297060d1dab2258fb959e85fe1b24e7fbda3d3f1))

## 1.0.0 (2026-06-02)


### Features

* compute tip for a single bill ([76c6882](https://github.com/example/tipcalc/commit/76c688276f171877294be96a5954fbe38ffb4e5d))
```

Git log after all stages:

```
f2582e5 (HEAD -> master, tag: v2.0.0) chore(release): 2.0.0
c9df1b9 feat!: split the bill unevenly by weight
9787d81 (tag: v1.1.0) chore(release): 1.1.0
297060d feat: split the bill evenly among diners
bc48912 (tag: v1.0.0) chore(release): 1.0.0
76c6882 feat: compute tip for a single bill
```

The version progression was exactly right: `v1.0.0` (first release) → `v1.1.0` (minor/feat) → `v2.0.0` (major/breaking). The experiment ran end to end with no intervention and no errors.

### Pros (observed)

**Zero friction on Node 20.** Installation was one command; the binary worked immediately. This alone is the main reason to choose `commit-and-tag-version` over `standard-version` today.

**Dry-run is genuinely useful.** `--dry-run` prints the exact changelog section that would be written, lists every git action that would execute, then stops — nothing changes. Safe to run in CI or before an unfamiliar release.

**Breaking-change detection works correctly.** The `feat!:` bang syntax triggered a major bump and inserted a `⚠ BREAKING CHANGES` section without any extra configuration. (Worth highlighting because not all tools in this family handle `!` — see the release-it and conventional-changelog-cli reviews.)

**Comparison links are generated automatically** from the `repository` field in `package.json` — no manual configuration.

**Clean release commits.** Each release creates a single `chore(release): X.Y.Z` commit bundling the `package.json` and `CHANGELOG.md` changes — easy to read and easy to revert.

**`--first-release` works as a proper bootstrap.** Skips the version bump, creates the initial CHANGELOG.md, commits, and tags the current version.

### Cons / pain points (observed)

**Confusing ✖ glyph on success.** `--first-release` prints `✖ skip version bump on first release` — a red X that usually signals failure. The behavior is correct; the visual is misleading and may alarm first-time users.

**Still says "master" in push hints.** The post-release hint is `git push --follow-tags origin master`. Projects on `main` must mentally substitute. A cosmetic carry-over from `standard-version`.

**Internal deprecation warnings from npm.** Install prints notices for `git-raw-commits` and `git-semver-tags`. Upstream noise; no functional impact, but it adds CI log clutter.

**No built-in monorepo support.** Like `standard-version`, it targets single-package repositories. Monorepos need additional tooling or manual `bumpFiles` configuration.

**Requires Conventional Commit discipline.** Without conventional commits the tool produces empty changelogs and cannot determine the bump. By design, but a non-trivial prerequisite.

### Docs vs. reality

The v1 review described the tool as a "maintained continuation of the standard-version style workflow" that "computes the next semver version from Conventional Commits" — all accurate. What reading rather than running missed:

- The `--first-release` ✖ cosmetic quirk is real and will confuse first-time users.
- The dry-run output is better than described — it shows the complete would-be changelog section inline, not just a summary.
- Comparison-link generation happens automatically from `package.json`; no `.versionrc` entry is needed.
- The release commit format (`chore(release): X.Y.Z` message, `v`-prefixed tag) is slightly inconsistent in appearance but is the standard-version convention.

The v1 verdict ("Recommended for smaller npm packages and teams migrating away from standard-version") holds up and if anything undersold the tool — the experiment found zero configuration needed for a correct end-to-end release life cycle.

## Verdict

**Verdict: Recommended — no reservations for single-package npm projects**

`commit-and-tag-version` does exactly what it says, runs cleanly on Node 20, and requires no configuration to get correct semver bumps, a well-formatted changelog, and properly tagged release commits. If your team already uses Conventional Commits, the operational cost of adopting it is near zero.

For teams migrating from `standard-version`, the switch is mechanical: replace the package name and npm script. No CLI flags change, no output format changes.

The tool is appropriately scoped. It does not publish to npm, manage GitHub releases, or handle monorepos. If you need those, look at `release-it` or `semantic-release`. If you want a local, reviewable, push-when-ready release command, `commit-and-tag-version` is the right level of tool.
