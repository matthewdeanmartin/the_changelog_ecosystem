# conventional-changelog-cli Experiment Notes

## Environment
- Base image: node:20-slim (Debian bookworm)
- Tool version: 5.0.0
- Run date: 2026-06-01

## Observations

### What worked
- Zero-config startup: `conventional-changelog -p angular -i CHANGELOG.md -s -r 0` generated a well-formed
  CHANGELOG.md from the first commit with no config files.
- Incremental append worked correctly in stages 2 and 4a. Running `-p angular -i CHANGELOG.md -s` (without
  `-r 0`) prepended only the new release block while preserving the existing history.
- The `-u` flag ("unreleased preview") worked fine in v5.0.0. Stage 3 used
  `conventional-changelog -p angular -u` to preview work-in-progress commits before tagging, and it emitted
  valid markdown to stdout without touching CHANGELOG.md.
- Commit links were generated automatically using the `repository.url` from package.json. Short SHAs are
  hyperlinked to the (placeholder) GitHub URL.
- The `vX.Y.Z` tag format was recognized without any extra configuration.

### What failed / friction
- **Breaking-change commit silently drops its body.** In stage 4b, the commit
  `feat!: split the bill unevenly by weight` was tagged as v3.0.0. The CHANGELOG.md entry for 3.0.0 was
  generated but the "Features" section under it was empty — the entry header appeared with no content
  underneath it. The v3.0.0 heading and the v2.0.0 heading ran together without a blank line, producing
  malformed markdown. The `BREAKING CHANGE` footer was not surfaced at all (no "Breaking Changes" section).
- **Tool is deprecated.** npm printed a deprecation warning at install time:
  `conventional-changelog-cli@5.0.0: This package is no longer maintained. Please use the conventional-changelog package instead.`
  The maintainers have consolidated into the `conventional-changelog` monorepo package. Using this CLI in a
  new project carries maintenance risk.
- **`chore(release):` commits are suppressed.** The release-bump commits are correctly hidden, which is
  desirable — but it is non-obvious to newcomers why those commits don't appear.
- **Repo URL must be set in package.json.** The tool does not attempt to detect it from the git remote.
  If `repository.url` is absent, commit links are omitted and the release header URL is broken.

### Surprising findings
- The `-u` flag, which is sometimes documented as unstable or missing, worked correctly in v5.0.0 and
  produced a complete release block with a dummy next-version number inferred from conventional commit types.
- The angular preset groups commits as "Features" and "Bug Fixes" by default. A `feat!:` (breaking change
  indicator via `!` suffix) was not given its own "BREAKING CHANGES" section under the angular preset —
  it was treated as a regular feature commit but then the content went missing entirely. This suggests the
  `!` breaking-change shorthand is not fully supported in the angular preset at v5.0.0; a full
  `BREAKING CHANGE:` footer in the commit body is likely required.
- The tool printed no errors or warnings when the v3.0.0 content was silently dropped. Silent data loss
  in a changelog tool is a notable footgun.

## Full transcript

```
tool under test:
5.0.0

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: generate CHANGELOG.md from v1.0.0 history ====================

----- CHANGELOG.md -----

# [1.0.0](https://github.com/example/tipcalc/compare/12ea504fb1898ff97805ad9724ea3f409daa3d5a...v1.0.0) (2026-06-02)


### Features

* compute tip for a single bill ([12ea504](https://github.com/example/tipcalc/commit/12ea504fb1898ff97805ad9724ea3f409daa3d5a))
------------------------

==================== STAGE 3: implement even split ====================

program output:
Bill: $80.00  Tip: $14.40  Total: $94.40
Split evenly among 4: $23.60 each
--- preview unreleased (since v1.0.0) ---
# [2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)


### Features

* split the bill evenly among diners ([5aac67e](https://github.com/example/tipcalc/commit/5aac67e0c22c97d00385335867c41fb1de472da2))
----- CHANGELOG.md -----

# [1.0.0](https://github.com/example/tipcalc/compare/12ea504fb1898ff97805ad9724ea3f409daa3d5a...v1.0.0) (2026-06-02)


### Features

* compute tip for a single bill ([12ea504](https://github.com/example/tipcalc/commit/12ea504fb1898ff97805ad9724ea3f409daa3d5a))
------------------------

==================== STAGE 4a: update CHANGELOG and tag v2.0.0 ====================

----- CHANGELOG.md -----
# [2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)


### Features

* split the bill evenly among diners ([5aac67e](https://github.com/example/tipcalc/commit/5aac67e0c22c97d00385335867c41fb1de472da2))

# [1.0.0](https://github.com/example/tipcalc/compare/12ea504fb1898ff97805ad9724ea3f409daa3d5a...v1.0.0) (2026-06-02)


### Features

* compute tip for a single bill ([12ea504](https://github.com/example/tipcalc/commit/12ea504fb1898ff97805ad9724ea3f409daa3d5a))
------------------------

==================== STAGE 4b: implement uneven split, release v3.0.0 ====================

----- CHANGELOG.md -----
# [3.0.0](https://github.com/example/tipcalc/compare/v2.0.0...v3.0.0) (2026-06-02)
# [2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)


### Features

* split the bill evenly among diners ([5aac67e](https://github.com/example/tipcalc/commit/5aac67e0c22c97d00385335867c41fb1de472da2))

# [1.0.0](https://github.com/example/tipcalc/compare/12ea504fb1898ff97805ad9724ea3f409daa3d5a...v1.0.0) (2026-06-02)


### Features

* compute tip for a single bill ([12ea504](https://github.com/example/tipcalc/commit/12ea504fb1898ff97805ad9724ea3f409daa3d5a))
------------------------

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 16
drwxrwxrwx 1 root root 4096 Jun  2 03:38 .
drwxr-xr-x 1 root root 4096 Jun  2 03:38 ..
-rw-r--r-- 1 root root  577 Jun  2 03:38 CHANGELOG.md
-rw-r--r-- 1 root root  298 Jun  2 03:38 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:38 git-tags.txt
-rw-r--r-- 1 root root 2798 Jun  2 03:38 transcript.txt
```
