# git-chglog Experiment Notes

**Tool:** git-chglog v0.15.4
**Date:** 2026-06-02
**Status:** ARCHIVED — last release 2023-02-15, repository read-only

## Setup

- Language-agnostic fixture: a shell-based tip calculator (`tipcalc.sh`)
- Three versions tagged: v1.0.0, v2.0.0, v3.0.0
- Conventional Commits messages including a breaking change (`feat!:` with `BREAKING CHANGE:` footer)
- Config in `.chglog/config.yml`, template in `.chglog/CHANGELOG.tpl.md`

## Template note

The original 3-capture-group pattern (`Type`, `Scope`, `Subject`) was simplified to a
2-capture-group pattern (`Type`, `Subject`) because git-chglog requires `pattern_maps`
to match the number of capture groups exactly. The scope field is optional in practice
and the simpler config is closer to the minimal working setup users will reach first.

## Full Transcript

```
git-chglog version:
git-chglog version 0.15.4

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: git-chglog for v1.0.0 ====================

⌚  Generating changelog ...
✨  Generate of "CHANGELOG.md" is completed! (6.339062ms)
----- CHANGELOG.md -----

<a name="v1.0.0"></a>
## v1.0.0 (2026-06-02)

### Features

- compute tip for a single bill

------------------------

==================== STAGE 3: implement even split ====================

program output:
Bill: $80.00  Tip: $14.40  Total: $94.40
Split evenly among 4: $23.60 each
----- CHANGELOG.md -----

<a name="v1.0.0"></a>
## v1.0.0 (2026-06-02)

### Features

- compute tip for a single bill

------------------------

==================== STAGE 4a: tag v2.0.0, regenerate changelog ====================

⌚  Generating changelog ...
✨  Generate of "CHANGELOG.md" is completed! (7.321175ms)
----- CHANGELOG.md -----

<a name="v2.0.0"></a>
## [v2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)

### Features

- split the bill evenly among diners


<a name="v1.0.0"></a>
## v1.0.0 (2026-06-02)

### Features

- compute tip for a single bill

------------------------

==================== STAGE 4b: implement uneven split, breaking change ====================

⌚  Generating changelog ...
✨  Generate of "CHANGELOG.md" is completed! (8.608977ms)
----- CHANGELOG.md -----

<a name="v3.0.0"></a>
## [v3.0.0](https://github.com/example/tipcalc/compare/v2.0.0...v3.0.0) (2026-06-02)

### Features

- split the bill unevenly by weight

### BREAKING CHANGE


output format changes — per-person amounts replace single total line


<a name="v2.0.0"></a>
## [v2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)

### Features

- split the bill evenly among diners


<a name="v1.0.0"></a>
## v1.0.0 (2026-06-02)

### Features

- compute tip for a single bill

------------------------

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 16
drwxrwxrwx 1 root root 4096 Jun  2 13:35 .
drwxr-xr-x 1 root root 4096 Jun  2 13:35 ..
-rw-r--r-- 1 root root  509 Jun  2 13:35 CHANGELOG.md
-rw-r--r-- 1 root root  289 Jun  2 13:35 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 13:35 git-tags.txt
-rw-r--r-- 1 root root 2153 Jun  2 13:35 transcript.txt
```

## Final CHANGELOG.md

```markdown

<a name="v3.0.0"></a>
## [v3.0.0](https://github.com/example/tipcalc/compare/v2.0.0...v3.0.0) (2026-06-02)

### Features

- split the bill unevenly by weight

### BREAKING CHANGE


output format changes — per-person amounts replace single total line


<a name="v2.0.0"></a>
## [v2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)

### Features

- split the bill evenly among diners


<a name="v1.0.0"></a>
## v1.0.0 (2026-06-02)

### Features

- compute tip for a single bill
```

## Git log

```
30b2e9e (HEAD -> master) chore(release): 3.0.0
6ea134d (tag: v3.0.0) feat!: split the bill unevenly by weight
0b6a8ff chore(release): 2.0.0
3a7d2d4 (tag: v2.0.0) feat: split the bill evenly among diners
781d2dd docs: add changelog
bebfb1b (tag: v1.0.0) feat: compute tip for a single bill
```

## Observations

1. **Install worked cleanly.** The pre-built Linux amd64 binary extracted and ran without issues.
2. **Single-tag filtering works.** `git-chglog v1.0.0` generated output scoped to that tag only.
3. **Full-history regeneration works.** Running `git-chglog` with no args (after all tags exist) produced a complete three-version changelog in one pass.
4. **Breaking change detected.** The `feat!:` commit with a `BREAKING CHANGE:` footer produced a dedicated `### BREAKING CHANGE` section in the v3.0.0 entry.
5. **Compare links generated.** For v2.0.0 and v3.0.0, the header became a hyperlink with a compare URL; v1.0.0 (no previous tag) was a plain heading — both correct.
6. **Pattern_maps must match capture group count.** The documented 3-group pattern with Scope required a matching three-entry `pattern_maps` list; using a 2-group pattern with a 2-entry list resolved immediately.
7. **No `--init` wizard used.** Config and template were provided directly — the wizard is optional.
8. **Generation is fast.** Sub-10ms for a small repo; no perceptible overhead even via Docker.
9. **docs: commits are silently dropped.** The `docs: add changelog` commit did not appear — consistent with the filter configuration.
