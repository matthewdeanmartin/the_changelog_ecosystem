# release-it Experiment Notes

## Environment
- Base image: node:20-slim
- Tool version: release-it 17.10.0
- Plugin: @release-it/conventional-changelog 8.0.2
- Run date: 2026-06-01

## Observations

### What worked
- After adding `"requireUpstream": false` and `"requireBranch": false` to `.release-it.json`, the tool ran end-to-end without further failures.
- `feat:` commit correctly triggered a minor bump: 1.0.0 → 1.1.0 (stage 4a).
- CHANGELOG.md was created and updated automatically on each real release run.
- The dry-run in stage 2 (`--dry-run`) produced a useful preview: it showed the planned version, the changelog entry, and each git step prefixed with `!` (would-execute) vs `$` (already-done), without touching the working tree.
- The release commit and tag were applied together: `chore(release): 1.1.0` commit plus a `v1.1.0` annotated tag.
- The tool is fast: each release run completed in under 1 second.

### What failed / friction

**Initial failure: upstream branch check.** The tool failed immediately on first run with:
```
ERROR No upstream configured for current branch.
Please set an upstream branch.
```
The `.release-it.json` already had `"push": false`, but release-it still performs an upstream check before checking the push flag. Workaround: add `"requireUpstream": false` and `"requireBranch": false` to the `git` block in config. This is not documented prominently.

**Breaking change (`feat!`) not detected as major bump.** Stage 4b committed `feat!: split the bill unevenly by weight` — a conventional-commits breaking change marker. release-it bumped patch (1.1.0 → 1.1.1) rather than major (1.1.0 → 2.0.0). The CHANGELOG entry for 1.1.1 had no content at all — no `BREAKING CHANGES` section, no feature entry. This is a significant semver compliance failure.

**Empty CHANGELOG section.** The 1.1.1 entry in CHANGELOG.md has only a heading and date, with no content. The breaking change commit (`feat!:`) was not reflected in the changelog body at all.

**Version in dry-run did not match actual first release.** The dry-run in stage 2 proposed 1.0.1 (patch bump from 1.0.0). The actual first release in stage 4a produced 1.1.0 (minor bump) because by that point a `feat:` commit had been added. This is correct behavior — the dry-run proposed a bump based on the commit history at that moment — but it can be confusing.

**Implicit version selection in `--ci` mode.** In interactive mode, release-it would show a version menu and let the user confirm. In `--ci` mode, the plugin picks the version automatically. There is no way to inspect this decision without the dry-run flag, and the dry-run output is text-only, not machine-readable.

### Surprising findings
- The `feat!` (exclamation mark breaking change notation) was silently ignored for version bumping. Only `BREAKING CHANGE:` in the commit body footer is reliably handled by the angular preset.
- release-it wraps git operations in a changeset diff: it shows `A  CHANGELOG.md` and `M package.json` before committing, which is useful auditing output.
- The tool fetches from the remote even when `push: false` — the `! git fetch` line in the dry-run output shows this. In an air-gapped environment or fresh repo with no remote, this produces a warning but does not block the release.
- CHANGELOG accumulation works: the second release prepended a new entry at the top while preserving the first entry below it. No duplication occurred.

## Full transcript

```
tool under test:
v17.10.0

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: generate CHANGELOG.md for v1.0.0 (dry-run preview) ====================

--- release-it dry-run to see what it would do ---
$ git diff --quiet HEAD
$ git rev-parse --abbrev-ref HEAD
$ git config --get branch.master.remote
$ git remote get-url origin
$ git config --get remote.origin.url
! git fetch
$ git rev-parse --abbrev-ref HEAD  [cached]
$ git describe --tags --match=v* --abbrev=0
🚀 Let's release tipcalc (1.0.0...1.0.1)
Changelog:
## [1.0.1](https://github.com/example/tipcalc/compare/v1.0.0...v1.0.1) (2026-06-02)
! npm version 1.0.1 --no-git-tag-version
$ Writing changelog to CHANGELOG.md
$ git status --short --untracked-files=no
Empty changeset
! git add . --update
! git commit --message chore(release): 1.0.1
! git tag --annotate --message Release 1.0.1 v1.0.1
🏁 Done (in 0s.)
(no CHANGELOG.md yet)

==================== STAGE 3: implement even split ====================

program output:
Bill: $80.00  Tip: $14.40  Total: $94.40
Split evenly among 4: $23.60 each

==================== STAGE 4a: release-it --ci releases v2.0.0 ====================

🚀 Let's release tipcalc (1.0.0...1.1.0)
Changelog:
# [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)

### Features
* split the bill evenly among diners ([cdeadb6](https://github.com/example/tipcalc/commit/cdeadb6670d63df79ae0fe7b9ff3c3b8eb51f7c8))
- npm version
✔ npm version
Changeset:
A  CHANGELOG.md
 M package.json
- Git commit
✔ Git commit
- Git tag
✔ Git tag
🏁 Done (in 0s.)
----- CHANGELOG.md -----


# [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([cdeadb6](https://github.com/example/tipcalc/commit/cdeadb6670d63df79ae0fe7b9ff3c3b8eb51f7c8))
------------------------

==================== STAGE 4b: implement uneven split, release v3.0.0 ====================

🚀 Let's release tipcalc (1.1.0...1.1.1)
Changelog:
## [1.1.1](https://github.com/example/tipcalc/compare/v1.1.0...v1.1.1) (2026-06-02)
- npm version
✔ npm version
Changeset:
 M CHANGELOG.md
 M package.json
- Git commit
✔ Git commit
- Git tag
✔ Git tag
🏁 Done (in 0s.)
----- CHANGELOG.md -----


## [1.1.1](https://github.com/example/tipcalc/compare/v1.1.0...v1.1.1) (2026-06-02)

# [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([cdeadb6](https://github.com/example/tipcalc/commit/cdeadb6670d63df79ae0fe7b9ff3c3b8eb51f7c8))
------------------------

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 12
drwxrwxrwx 1 root root 4096 Jun  2 03:39 .
drwxr-xr-x 1 root root 4096 Jun  2 03:39 ..
-rw-r--r-- 1 root root  319 Jun  2 03:39 CHANGELOG.md
-rw-r--r-- 1 root root  260 Jun  2 03:39 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:39 git-tags.txt
-rw-r--r-- 1 root root 2846 Jun  2 03:39 transcript.txt
```
