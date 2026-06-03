Title: standard-version
Date: 2026-06-02
Slug: standard-version
Ecosystem: Node
Tags: conventional-commits, keep-a-changelog, node, npm-cli, semantic-versioning, git-tags, changelog-file, legacy, unmaintained, hands-on
Tool_URL: https://www.npmjs.com/package/standard-version
Tool_Version: 9.5.0
Tool_Status: unmaintained
Experiment: examples/node/standard-version/
Summary: The classic Conventional Commits release helper; hands-on testing confirms it still runs cleanly on Node 20 and produces correct semver and changelogs, but it is archived/unmaintained and a drop-in maintained replacement exists.

> **Note:** This tool is considered legacy and is no longer maintained; the repository is archived. It still works (see hands-on findings), but new projects should prefer its maintained drop-in replacement, `commit-and-tag-version`.

A reproducible hands-on experiment for this tool lives in [`examples/node/standard-version/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/node/standard-version).

## Overview

`standard-version` was the classic npm release helper for Conventional Commits projects: bump the version, update `CHANGELOG.md`, create a release commit, and tag it. It shaped a lot of Node release habits.

Today it is mainly important as legacy context. Projects that still use it can keep working, but new projects should usually choose `commit-and-tag-version`, release-it, or semantic-release.

## Installation

```bash
npm install --save-dev standard-version
```

Note: npm install prints deprecation warnings for several abandoned transitive dependencies (`git-raw-commits`, `git-semver-tags`, `q`, `stringify-package`). These do not affect runtime behavior but signal the tool's age.

## What It Does

- Determines semver bumps from Conventional Commits.
- Updates `package.json` and related version files.
- Generates a changelog through conventional-changelog.
- Commits release changes and creates a git tag.
- Supports custom presets and lifecycle scripts.

## Configuration

The old standard setup is an npm script:

```json
{
  "scripts": {
    "release": "standard-version"
  },
  "standard-version": {
    "preset": "conventionalcommits"
  }
}
```

First-run setup is easy — the hands-on run needed zero configuration beyond a git repo with conventional commits — but the maintenance posture changes the recommendation.

## Output Quality

Output is conventional-changelog style, with auto-generated comparison links and a `⚠ BREAKING CHANGES` section for breaking commits. See the hands-on section for the exact output the experiment produced. The output remains useful; the tool is simply no longer the preferred implementation of this workflow.

## Ecosystem Fit

Historically, standard-version fit npm packages very well. It is still common in older repositories, docs, and copy-pasted release scripts.

For new work, `commit-and-tag-version` preserves the same mental model with active maintenance — and, per the hands-on experiments, identical output and CLI behavior.

## Maintenance Status

- Latest version tested: **9.5.0**
- Last release: **2022-05-15**
- Tool status in this survey: **unmaintained** (repository archived)
- Repository: <a href="https://github.com/conventional-changelog/standard-version" target="_blank" rel="noopener noreferrer">https://github.com/conventional-changelog/standard-version</a>

Treat this as legacy release infrastructure: no security patches, no future Node compatibility fixes, no bug fixes.

---

## Hands-On Findings

This section is grounded in actually running `standard-version@9.5.0` on Node 20, not reading its docs.

### What I actually ran

The experiment ran inside a `node:20-slim` Docker container across four stages:

1. Initial commit with a `feat:` message, no release yet.
2. `standard-version --first-release` — tag v1.0.0 without bumping.
3. A second `feat:` commit, `standard-version --dry-run` to preview, then no-op.
4. `standard-version` to release v1.1.0 from the `feat:` commit.
5. A `feat!:` (breaking change) commit, then `standard-version` to release v2.0.0.

### Real output

The tool ran cleanly. Every stage produced the expected result. Final CHANGELOG.md:

```markdown
# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [2.0.0](https://github.com/example/tipcalc/compare/v1.1.0...v2.0.0) (2026-06-02)


### ⚠ BREAKING CHANGES

* split the bill unevenly by weight

### Features

* split the bill unevenly by weight ([8d92d76](https://github.com/example/tipcalc/commit/8d92d763984301823936e58ba056e4da455c2162))

## [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([8280282](https://github.com/example/tipcalc/commit/82802828f0f2e48a7e38ff7348c0ddbdb7820343))

## 1.0.0 (2026-06-02)


### Features

* compute tip for a single bill ([117f27f](https://github.com/example/tipcalc/commit/117f27f258fc028768af7aab5c5fec3c795ec8cc))
```

Git tags produced: `v1.0.0`, `v1.1.0`, `v2.0.0`. The git log shows `chore(release): X.Y.Z` commits created automatically for each release.

### Pros (observed)

- **Works on Node 20 without modification.** No compatibility errors, no runtime exceptions, no monkey-patching. Four years after its last release, standard-version 9.5.0 still runs cleanly.
- **Accurate semver inference.** `feat:` produced a minor bump (1.0.0 → 1.1.0); `feat!:` produced a major bump (1.1.0 → 2.0.0), with the breaking-change section generated automatically from the `!` marker. (Notably, this `!` handling works here even though release-it's angular-preset plugin and conventional-changelog-cli both mishandled it — see those reviews.)
- **Useful dry-run.** `--dry-run` showed a clean, accurate diff of the next CHANGELOG entry, then exited without writing.
- **`--first-release` is a thoughtful flag.** It tags without bumping — exactly what you want when a project already at v1.0.0 adopts the tool mid-life.
- **Zero configuration needed** for the basic workflow.

### Cons / pain points (observed)

- **Unmaintained since 2022.** npm install printed deprecation warnings for four of its own transitive dependencies (`git-raw-commits`, `git-semver-tags`, `q`, `stringify-package`), themselves abandoned. Any future Node.js breaking change in that tree has no upstream fix path.
- **Release commit format is baked in.** The `chore(release): X.Y.Z` message is hard-coded; teams wanting a different convention must dig into lifecycle scripts or wrap the tool.
- **Suggests `git push --follow-tags origin master`** — `master` is baked into the hint text. Cosmetic, but dated for repos on `main`.
- **No GitHub Actions integration or CI-first mode.** You wire CI publishing yourself.
- **The ecosystem has explicitly moved on.** The repository is archived; the maintainers recommend migrating to `commit-and-tag-version` or `release-it`.

### Docs vs. reality

The v1 article described output that matches what was observed — versioning logic, CHANGELOG format, and CLI flags all behave as documented. The v1 article was accurate; it simply lacked hands-on confirmation that the tool still works on current Node.

One difference: the v1 article showed a hypothetical `9.5.0` entry in its CHANGELOG example. The real experiment produced entries keyed to the fixture app's versions (1.0.0 through 2.0.0), demonstrating correct version-read-from-`package.json` behavior rather than any hard-coded default.

## Verdict

**Verdict: Works correctly, but unmaintained — prefer the maintained drop-in for new projects**

standard-version 9.5.0 works correctly on Node 20. The experiment produced no errors, no workarounds, and a well-formed CHANGELOG across three releases including a breaking-change major bump. The recommendation to avoid it for *new* projects stands — but the reason is not that it breaks on modern Node. It is that:

1. The repository is archived: no security patches, no Node 22+ compatibility fixes, no bug fixes.
2. Its own transitive dependencies are deprecated and abandoned.
3. A drop-in maintained replacement (`commit-and-tag-version`) exists with the same API.

For projects already using standard-version: it is not an emergency. If it works in CI today, it will likely keep working until something in its abandoned dependency tree breaks on a future Node release or an npm audit threshold. The right time to migrate is your next quiet release cycle, not a panic. If you ever do need to keep it alive past an upstream break, the door is open to fork it — but `commit-and-tag-version` already is, in effect, that maintained fork.

For new projects: use `commit-and-tag-version` (same CLI, maintained), `release-it` (more flexible, active), or `semantic-release` (fully automated, CI-first).
