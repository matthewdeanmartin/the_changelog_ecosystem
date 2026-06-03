Title: commit-and-tag-version (hands-on synthesis)
Date: 2026-06-02
Slug: commit-and-tag-version-v2
Ecosystem: node
Tags: conventional-commits, node, changelog-file, standard-version-fork, hands-on
Tool_URL: https://www.npmjs.com/package/commit-and-tag-version
Tool_Version: 12.5.0
Tool_Status: active
Experiment: examples/node/commit-and-tag-version/
Summary: Hands-on re-review of commit-and-tag-version, the actively maintained standard-version fork.



## What I actually ran

All commands ran inside a `node:20-slim` Docker container with `commit-and-tag-version` installed globally via npm. The experiment used a small "tip calculator" Node app to simulate a realistic release lifecycle:

1. **Stage 1** — made the initial commit with `feat: compute tip for a single bill`.
2. **Stage 2** — ran `commit-and-tag-version --first-release` to bootstrap the changelog and tag `v1.0.0` without bumping the version.
3. **Stage 3** — added an even-split feature (`feat: split the bill evenly among diners`) and previewed the release with `--dry-run`.
4. **Stage 4a** — ran `commit-and-tag-version` with no flags to release `v1.1.0`.
5. **Stage 4b** — introduced a breaking change (`feat!: split the bill unevenly by weight`) and released `v2.0.0`.

The Dockerfile pins `commit-and-tag-version@12.5.0`. The full script is at `examples/node/commit-and-tag-version/run_experiment.sh`.

## Real output

The final `CHANGELOG.md` after all four stages:

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

The version progression was exactly right: `v1.0.0` (first release) → `v1.1.0` (minor/feat) → `v2.0.0` (major/breaking).

## Pros (observed)

**Zero friction on Node 20.** Installation was one command; the binary worked immediately. This alone is the main reason to choose `commit-and-tag-version` over `standard-version` today.

**Dry-run is genuinely useful.** `--dry-run` prints the exact changelog section that would be written, lists every git action that would execute, and then stops — nothing is changed. It is safe to run in CI or before an unfamiliar release.

**Breaking-change detection works correctly.** The `feat!:` bang syntax triggered a major bump and inserted a `⚠ BREAKING CHANGES` section at the top of the release notes without any extra configuration.

**Comparison links are generated automatically.** Each release section heading is a hyperlink to the diff on GitHub (e.g., `v1.0.0...v1.1.0`). The tool derives the URL from the `repository` field in `package.json` — no manual configuration required.

**Clean release commits.** Each release creates a single `chore(release): X.Y.Z` commit that bundles the `package.json` and `CHANGELOG.md` changes together. This is easy to understand in git history and easy to revert if needed.

**`--first-release` works as a proper bootstrap.** It skips the version bump, creates the initial CHANGELOG.md, commits it, and tags the current version. Subsequent runs then pick up from the tag and compute incremental diffs correctly.

## Cons / pain points (observed)

**Confusing ✖ glyph on success.** When `--first-release` skips the bump it prints `✖ skip version bump on first release` — with a red X character that typically signals failure. The behavior is correct; the visual is misleading. First-time users may think something went wrong.

**Still says "master" in push hints.** The post-release message is `Run git push --follow-tags origin master`. Projects on `main` need to mentally substitute. A minor cosmetic issue that has persisted from `standard-version`.

**Internal deprecation warnings from npm.** Installing the package prints deprecation notices for `git-raw-commits` and `git-semver-tags`, which are internal dependencies being replaced by `@conventional-changelog/git-client`. These warnings come from upstream and do not affect functionality, but they can create noise in CI logs.

**No built-in monorepo support.** Like `standard-version`, `commit-and-tag-version` targets single-package repositories. Monorepo workflows require additional tooling or manual configuration of `bumpFiles`.

**Requires conventional commit discipline.** If the team does not use Conventional Commits, the tool produces empty changelogs and cannot determine the correct version bump. This is by design but is a non-trivial prerequisite.

## Docs vs. reality

The existing review (`content/articles/commit-and-tag-version.md`) described the tool as a "maintained continuation of the standard-version style workflow" that "computes the next semver version from Conventional Commits." All of that is accurate.

What the earlier review did not capture, because it was based on reading rather than running:

- The **`--first-release` ✖ cosmetic quirk** is real and will confuse first-time users.
- The **dry-run output format** is better than described — it shows the complete would-be changelog section inline, not just a summary.
- The **comparison link generation** happens automatically from `package.json`; you do not need a `.versionrc` entry for it.
- The **release commit message format** (`chore(release): X.Y.Z`, no `v` prefix in the message but `v` prefix on the tag) is slightly inconsistent in appearance but is the standard-version convention.

The original review's verdict ("Recommended for smaller npm packages and teams migrating away from standard-version") holds up and if anything is underselling the tool. The experiment found zero configuration needed for a correct end-to-end release lifecycle.

## Revised verdict

**Verdict: Recommended — no reservations for single-package npm projects**

`commit-and-tag-version` does exactly what it says on the tin, runs cleanly on Node 20, and requires no configuration to get correct semver bumps, a well-formatted changelog, and properly tagged release commits. If your team already uses Conventional Commits, the operational cost of adopting this tool is near zero.

For teams migrating from `standard-version`, the switch is mechanical: replace the package name and npm script. No CLI flags change. No output format changes.

The tool is appropriately scoped. It does not try to publish to npm, manage GitHub releases, or handle monorepos. If you need those things, look at `release-it` or `semantic-release`. If you want a local, reviewable, push-when-ready release command, `commit-and-tag-version` is the right level of tool.
