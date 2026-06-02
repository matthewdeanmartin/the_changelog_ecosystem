Title: standard-version (hands-on synthesis)
Date: 2026-06-02
Slug: standard-version-v2
Ecosystem: node
Tags: conventional-commits, node, changelog-file, unmaintained, hands-on
Tool_URL: https://www.npmjs.com/package/standard-version
Tool_Version: 9.5.0
Tool_Status: unmaintained
Experiment: examples/node/standard-version/
Summary: Hands-on re-review of standard-version 9.5.0 on Node 20 — documenting whether it still functions and confirming the migration recommendation.

## What I actually ran

The experiment ran inside a `node:20-slim` Docker container. The script walked through four stages:

1. Initial commit with a `feat:` message, no release yet.
2. `standard-version --first-release` — tag v1.0.0 without bumping the version.
3. A second `feat:` commit, `standard-version --dry-run` to preview, then no-op.
4. `standard-version` to release v1.1.0 from the `feat:` commit.
5. A `feat!:` (breaking change) commit, then `standard-version` to release v2.0.0.

Source: `examples/node/standard-version/`

## Real output

The tool ran cleanly. Every stage produced the expected result. This is the final CHANGELOG.md:

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

## Pros (observed)

- **Works on Node 20 without modification.** No compatibility errors, no runtime exceptions, no monkey-patching required. Four years after its last release, standard-version 9.5.0 still runs cleanly.
- **Accurate semver inference.** `feat:` produced a minor bump (1.0.0 → 1.1.0); `feat!:` produced a major bump (1.1.0 → 2.0.0). The breaking-change section in the CHANGELOG was generated automatically from the `!` marker.
- **Useful dry-run.** `--dry-run` showed a clean diff of what the next CHANGELOG entry would look like, then exited without writing. The output was easy to read and accurate.
- **`--first-release` is a thoughtful flag.** It lets a project adopt standard-version mid-life without an unwanted version bump.
- **Zero configuration needed for the basic workflow.** A single global install and a git repo with conventional commits is enough to start.

## Cons / pain points (observed)

- **Unmaintained since 2022.** The npm install printed deprecation warnings for four of its own transitive dependencies: `git-raw-commits`, `git-semver-tags`, `q`, and `stringify-package`. These packages are themselves abandoned. Any future Node.js breaking change in that dependency tree has no upstream path to a fix.
- **Release commit format is not configurable without extra configuration.** The `chore(release): X.Y.Z` commit message is hard-coded as the default. Teams with non-standard conventions need to dig into lifecycle scripts.
- **Suggests `git push --follow-tags origin master`** in its output — the branch name `master` is baked into the hint text. Cosmetic, but notable for repositories using `main`.
- **No GitHub Actions integration or CI-first mode.** There is no built-in mechanism to run standard-version in CI and publish automatically. You have to wire that yourself.
- **The ecosystem has explicitly moved on.** The standard-version repository is archived. The maintainers themselves recommend migrating to `commit-and-tag-version` or `release-it`.

## Docs vs. reality

The original article described output that matches what was observed. The versioning logic, CHANGELOG format, and CLI flags all behave as documented. The v1 article was accurate — it just lacked the hands-on confirmation that the tool still works on current Node.

One difference: the original article showed a hypothetical `9.5.0` entry in the CHANGELOG example. The real experiment produced entries keyed to the fixture app's versions (1.0.0 through 2.0.0), which demonstrates correct version-read-from-package.json behaviour rather than any hard-coded default.

## Revised verdict

**standard-version 9.5.0 works correctly on Node 20.** The experiment produced no errors, no workarounds, and a well-formed CHANGELOG across three releases including a breaking-change major bump.

The recommendation to avoid it for new projects stands — but the reason is not that it breaks on modern Node. It is that:

1. The repository is archived. There will be no security patches, no Node 22+ compatibility fixes, and no bug fixes.
2. Its own transitive dependencies are deprecated and abandoned.
3. A drop-in maintained replacement (`commit-and-tag-version`) exists with the same API.

For projects already using standard-version: it is not an emergency. If it works in CI today, it will likely continue working until something in its abandoned dependency tree breaks on a future Node release or npm audit threshold. The right time to migrate is at your next quiet release cycle, not in a panic.

For new projects: use `commit-and-tag-version` (same CLI, maintained), `release-it` (more flexible, active), or `semantic-release` (fully automated, CI-first). Do not start new projects on standard-version.
