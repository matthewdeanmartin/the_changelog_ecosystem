# standard-version Experiment Notes

## Environment
- Base image: node:20-slim (Debian Bookworm)
- Tool version: standard-version 9.5.0 (final release, unmaintained since 2022)
- Node version: 20.x
- Run date: 2026-06-01

## Observations

### What worked
- **Full end-to-end workflow succeeded without errors or workarounds.**
- `standard-version --first-release` created CHANGELOG.md, committed it, and tagged v1.0.0.
- `standard-version --dry-run` previewed the next version bump and changelog diff without writing anything. The dry-run output was clearly delimited and accurate — it correctly predicted 1.0.0 → 1.1.0.
- `standard-version` (no flags) bumped `package.json`, prepended the new section to CHANGELOG.md, committed both files with a `chore(release): X.Y.Z` message, and created an annotated git tag. All three releases completed cleanly.
- Breaking-change detection worked: `feat!:` in the commit message triggered a major bump (1.1.0 → 2.0.0), and the CHANGELOG entry gained a `⚠ BREAKING CHANGES` section automatically.
- The `--no-verify` flag (used to skip git hooks) was accepted silently.
- npm install during Docker build emitted deprecation warnings for several transitive packages (`git-raw-commits`, `q`, `git-semver-tags`, `stringify-package`) — these are noise from the dependency tree but did not affect runtime behaviour.

### What failed / friction
- **Nothing failed.** The tool ran cleanly on Node 20 in every stage.
- The deprecation warnings at install time (`npm warn deprecated …`) are a signal of the tool's age — its transitive dependencies are themselves deprecated and unmaintained.
- The script's Stage 4a label says "v2.0.0" but standard-version produced v1.1.0, because the next commit (`feat:`) only warranted a minor bump. Stage 4b's `feat!:` then produced v2.0.0. This is correct tool behaviour, not a failure.

### Tool status assessment (does it work on Node 20?)
**Yes, standard-version 9.5.0 works correctly on Node 20.** There are no runtime errors, no Node compatibility failures, and no output degradation. The only visible sign of age is install-time deprecation warnings in transitive dependencies.

### Surprising findings
- The tool still works perfectly four years after its last release. This complicates a simple "it's broken, avoid it" narrative — the honest finding is "it works but is a maintenance liability."
- The `--first-release` flag is a nice ergonomic touch: it tags without bumping, which is exactly what you want when a project already at v1.0.0 adopts standard-version mid-life.
- Commit links in CHANGELOG.md are generated from the `repository.url` field in `package.json`, so they look valid even in the isolated Docker environment.
- The release commit message format (`chore(release): X.Y.Z`) is baked in with no easy override — teams that want a different commit style will need to reach for a wrapper or a different tool.

## Full transcript

```
tool under test:
9.5.0

NOTE: standard-version is UNMAINTAINED since 2022.
      The recommended replacement is commit-and-tag-version.

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: standard-version --first-release ====================

✖ skip version bump on first release
✔ created CHANGELOG.md
✔ outputting changes to CHANGELOG.md
✔ committing CHANGELOG.md
✔ tagging release v1.0.0
ℹ Run `git push --follow-tags origin master` to publish
----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## 1.0.0 (2026-06-02)


### Features

* compute tip for a single bill ([117f27f](https://github.com/example/tipcalc/commit/117f27f258fc028768af7aab5c5fec3c795ec8cc))
------------------------

==================== STAGE 3: implement even split ====================

program output:
Bill: $80.00  Tip: $14.40  Total: $94.40
Split evenly among 4: $23.60 each
--- standard-version --dry-run ---
✔ bumping version in package.json from 1.0.0 to 1.1.0
✔ outputting changes to CHANGELOG.md

---
## [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([8280282](https://github.com/example/tipcalc/commit/82802828f0f2e48a7e38ff7348c0ddbdb7820343))
---

✔ committing package.json and CHANGELOG.md
✔ tagging release v1.1.0
ℹ Run `git push --follow-tags origin master && npm publish` to publish
----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## 1.0.0 (2026-06-02)


### Features

* compute tip for a single bill ([117f27f](https://github.com/example/tipcalc/commit/117f27f258fc028768af7aab5c5fec3c795ec8cc))
------------------------

==================== STAGE 4a: standard-version releases v2.0.0 ====================

✔ bumping version in package.json from 1.0.0 to 1.1.0
✔ outputting changes to CHANGELOG.md
✔ committing package.json and CHANGELOG.md
✔ tagging release v1.1.0
ℹ Run `git push --follow-tags origin master && npm publish` to publish
----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([8280282](https://github.com/example/tipcalc/commit/82802828f0f2e48a7e38ff7348c0ddbdb7820343))

## 1.0.0 (2026-06-02)


### Features

* compute tip for a single bill ([117f27f](https://github.com/example/tipcalc/commit/117f27f258fc028768af7aab5c5fec3c795ec8cc))
------------------------

==================== STAGE 4b: implement uneven split, release v3.0.0 ====================

✔ bumping version in package.json from 1.1.0 to 2.0.0
✔ outputting changes to CHANGELOG.md
✔ committing package.json and CHANGELOG.md
✔ tagging release v2.0.0
ℹ Run `git push --follow-tags origin master && npm publish` to publish
----- CHANGELOG.md -----
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
------------------------

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 20
drwxrwxrwx 1 root root 4096 Jun  2 03:38 .
drwxr-xr-x 1 root root 4096 Jun  2 03:38 ..
-rw-r--r-- 1 root root  885 Jun  2 03:38 CHANGELOG.md
-rw-r--r-- 1 root root  290 Jun  2 03:38 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:38 git-tags.txt
-rw-r--r-- 1 root root 4432 Jun  2 03:38 transcript.txt
```
