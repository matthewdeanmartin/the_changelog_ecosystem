# versionize experiment notes

Experiment run: 2026-06-02  
Tool version: 2.5.0  
Base image: mcr.microsoft.com/dotnet/sdk:8.0

## Setup notes

- `--no-verify` is **not** a valid flag (the spec mentioned it but versionize does not support it). Removed from the script.
- `--dry-run` / `-d` works fine and prints the proposed changelog section without writing files or committing.
- versionize checks for a dirty git tree before running. The worktree must be clean.
- Starting version in `.csproj` must have `<Version>` element; versionize rewrites it in place.

## Workflow notes

The tool needs at least one commit on top of the most recent version tag to do anything.
In the experiment:
- v1.0.0 was manually tagged after the initial commit.
- A `fix:` commit was added before calling `versionize`, which bumped to 1.0.1.
- `feat:` commit bumped to 1.1.0 (minor, as expected).
- `feat!:` commit bumped to 2.0.0 (major, breaking change, as expected).

Note the version numbers: because the fix commit landed before any feat commit, the
sequence was 1.0.0 -> 1.0.1 -> 1.1.0 -> 2.0.0, not the clean 1 -> 2 -> 3 the spec envisioned.
This is expected behaviour — versionize follows SemVer strictly from the commit types.

## CHANGELOG output format

versionize uses HTML `<a name="..."></a>` anchors (not CommonMark heading IDs) and
a custom header style rather than pure Keep a Changelog format. Example:

```
<a name="2.0.0"></a>
## 2.0.0 (2026-06-02)

### Features

* split the bill unevenly by weight

### Breaking Changes

* split the bill unevenly by weight
```

Breaking-change commits appear in **both** `### Features` and `### Breaking Changes`.
This causes duplication in the output.

## Full transcript

```
tool under test:
2.5.0.0

==================== STAGE 1: v1.0.0 code committed, no changelog yet ====================

git log:
075a8e9 (HEAD -> master, tag: v1.0.0) feat: compute tip for a single bill
(no CHANGELOG.md yet)

==================== STAGE 2: run versionize for the first time -- creates CHANGELOG for v1.0.0 ====================

Discovered 1 versionable projects
  * /work/app/TipCalc.csproj
√ bumping version from 1.0.0 to 1.0.1 in projects
√ updated CHANGELOG.md
√ committed changes in projects and /work/app/CHANGELOG.md
√ tagged release as v1.0.1 against commit with sha 6ad3a1ca18863dbe447223906b442e9e0cc78bed
git log after versionize:
6ad3a1c (HEAD -> master, tag: v1.0.1) chore(release): 1.0.1
51cba87 fix: remove trailing whitespace in output
075a8e9 (tag: v1.0.0) feat: compute tip for a single bill
----- CHANGELOG.md -----
# Change Log

All notable changes to this project will be documented in this file. See [versionize](https://github.com/versionize/versionize) for commit guidelines.

<a name="1.0.1"></a>
## 1.0.1 (2026-06-02)

### Bug Fixes

* remove trailing whitespace in output

------------------------

==================== STAGE 3: implement even split; commit v2 code ====================

program output preview:
Bill:       $45.00
Tip:        $8.10 (18%)
Total:      $53.10
Diners:     3
Per person: $17.70
----- CHANGELOG.md -----
(unchanged from stage 2)

==================== STAGE 4a: run versionize -- feat commit triggers minor bump to 2.0.0 ====================

Discovered 1 versionable projects
  * /work/app/TipCalc.csproj
√ bumping version from 1.0.1 to 1.1.0 in projects
√ updated CHANGELOG.md
√ committed changes in projects and /work/app/CHANGELOG.md
√ tagged release as v1.1.0 against commit with sha 8b396e9a01685cbe580c3faa7028359d06ecd00d
git log after versionize:
8b396e9 (HEAD -> master, tag: v1.1.0) chore(release): 1.1.0
247b6c3 feat: split the bill evenly among diners
6ad3a1c (tag: v1.0.1) chore(release): 1.0.1
51cba87 fix: remove trailing whitespace in output
075a8e9 (tag: v1.0.0) feat: compute tip for a single bill

----- CHANGELOG.md -----
# Change Log

All notable changes to this project will be documented in this file. See [versionize](https://github.com/versionize/versionize) for commit guidelines.

<a name="1.1.0"></a>
## 1.1.0 (2026-06-02)

### Features

* split the bill evenly among diners

<a name="1.0.1"></a>
## 1.0.1 (2026-06-02)

### Bug Fixes

* remove trailing whitespace in output

------------------------

==================== STAGE 4b: implement uneven split, run versionize -- feat! triggers major bump to 3.0.0 ====================

program output preview:
Bill:  $45.00
Tip:   $8.10 (18%)
Total: $53.10

   Alice (weight 2): $17.70
     Bob (weight 3): $26.55
   Carol (weight 1): $8.85
Discovered 1 versionable projects
  * /work/app/TipCalc.csproj
√ bumping version from 1.1.0 to 2.0.0 in projects
√ updated CHANGELOG.md
√ committed changes in projects and /work/app/CHANGELOG.md
√ tagged release as v2.0.0 against commit with sha 55a53a4268a1f7854897343b18f11fa84f47c32a
git log after versionize:
55a53a4 (HEAD -> master, tag: v2.0.0) chore(release): 2.0.0
f77cc2d feat!: split the bill unevenly by weight
8b396e9 (tag: v1.1.0) chore(release): 1.1.0
247b6c3 feat: split the bill evenly among diners
6ad3a1c (tag: v1.0.1) chore(release): 1.0.1
51cba87 fix: remove trailing whitespace in output
075a8e9 (tag: v1.0.0) feat: compute tip for a single bill

----- CHANGELOG.md -----
# Change Log

All notable changes to this project will be documented in this file. See [versionize](https://github.com/versionize/versionize) for commit guidelines.

<a name="2.0.0"></a>
## 2.0.0 (2026-06-02)

### Features

* split the bill unevenly by weight

### Breaking Changes

* split the bill unevenly by weight

<a name="1.1.0"></a>
## 1.1.0 (2026-06-02)

### Features

* split the bill evenly among diners

<a name="1.0.1"></a>
## 1.0.1 (2026-06-02)

### Bug Fixes

* remove trailing whitespace in output

------------------------

==================== BONUS: versionize --dry-run demo (shows what would happen, no changes) ====================

Discovered 1 versionable projects
  * /work/app/TipCalc.csproj
√ bumping version from 2.0.0 to 2.0.1 in projects

---
<a name="2.0.1"></a>
## 2.0.1 (2026-06-02)

### Bug Fixes

* add end-of-file comment
---

√ updated CHANGELOG.md
(dry-run complete -- no files were changed)

==================== DONE -- copying artifacts to out/ ====================

Artifacts in /work/out:
total 20
drwxrwxrwx 1 root root 4096 Jun  2 14:13 .
drwxr-xr-x 1 root root 4096 Jun  2 14:13 ..
-rw-r--r-- 1 root root  515 Jun  2 14:13 CHANGELOG.md
-rw-r--r-- 1 root root  392 Jun  2 14:13 git-log.txt
-rw-r--r-- 1 root root   28 Jun  2 14:13 git-tags.txt
-rw-r--r-- 1 root root 5363 Jun  2 14:13 transcript.txt
```

## Final git history in container

```
d46812c (HEAD -> master) fix: add end-of-file comment
55a53a4 (tag: v2.0.0) chore(release): 2.0.0
f77cc2d feat!: split the bill unevenly by weight
8b396e9 (tag: v1.1.0) chore(release): 1.1.0
247b6c3 feat: split the bill evenly among diners
6ad3a1c (tag: v1.0.1) chore(release): 1.0.1
51cba87 fix: remove trailing whitespace in output
075a8e9 (tag: v1.0.0) feat: compute tip for a single bill
```

Tags created: v1.0.0 (manual), v1.0.1, v1.1.0, v2.0.0 (all via versionize).
