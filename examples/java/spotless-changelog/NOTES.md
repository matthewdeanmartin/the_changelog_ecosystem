# Experiment Notes: com.diffplug.spotless-changelog 3.1.2

**Run date:** 2026-06-02  
**Environment:** gradle:8.8-jdk21-alpine (Docker)  
**Gradle:** 8.8  
**Java:** OpenJDK 21.0.3

## What was tested

A three-version tip-calculator scenario driven through
`changelogCheck`, `changelogBump`, `changelogPrint`, and `changelogPush`.

## Task names (discovered at runtime)

```
Changelog tasks
changelogBump               - updates the changelog on disk with the next version and the current UTC date
changelogCheck              - checks that the changelog is formatted according to your rules
changelogPrint              - prints the last published version and the calculated next version
changelogPush               - commits the bumped changelog, tags it, and pushes
changelogInternalPushWillRun  (internal, not for direct use)
```

Note: the task listed in some documentation as `printLastChangelog` does not exist.
The correct task name is `changelogPrint`.

## Stage-by-stage transcript

### Stage 1 — v1 code, no changelog

```
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)
```

### Stage 2 — add CHANGELOG.md, changelogCheck, changelogBump

Seed changelog with `## [Unreleased]` / `### Added` content:

```
> Task :changelogCheck
BUILD SUCCESSFUL in 6s

> Task :changelogPrint
tipcalc null -> 0.1.0

> Task :changelogCheck
> Task :changelogBump
BUILD SUCCESSFUL in 6s
```

Resulting CHANGELOG.md after bump:

```markdown
## [Unreleased]

## [0.1.0] - 2026-06-02

### Added
- Compute tip for a restaurant bill at 18% rate
- Print bill, tip amount, and total to stdout
```

Key observations:
- With no prior version, `changelogPrint` reports `null -> 0.1.0`.
- The plugin starts from an implicit `0.0.0` base; a `### Added` section triggers a minor bump to `0.1.0`, not `1.0.0`.
- After `changelogBump`, an empty `## [Unreleased]` placeholder remains at the top of the file.
  This is intentional — the plugin always keeps a placeholder so the file stays structurally valid.

### Stage 3 — v2 even split, inject new [Unreleased] content

The empty `## [Unreleased]` left by `changelogBump` must be populated before the next bump.
In this experiment, a Python `re.sub` replaces the empty block with the new section.

```
> Task :changelogPrint
tipcalc 0.1.0 -> 0.2.0
```

`### Added` triggered a minor bump: `0.1.0 -> 0.2.0`.

### Stage 4b — v3 weighted split with **BREAKING** marker

Changelog content:

```markdown
## [Unreleased]

### Changed
- **BREAKING** Split API now accepts per-person weights instead of equal split

### Added
- Weighted bill split (Ada:3, Linus:2, Grace:3, Dennis:2)
```

Result:

```
> Task :changelogPrint
tipcalc 0.2.0 -> 0.3.0
```

**Finding:** The `**BREAKING**` token inside a `### Changed` bullet did NOT trigger a major
bump. The plugin only scanned for the default `ifFoundBumpBreaking` pattern, which requires
the exact text `**BREAKING**` to appear in a line that matches the configured search pattern.
By default `ifFoundBumpBreaking` looks for `**BREAKING**` anywhere in the unreleased block,
but a `### Changed` section heading is not separately configured.

After investigation, the default `ifFoundBumpBreaking` configuration (`['**BREAKING**']`)
should match any line containing that literal text. The bump produced `0.3.0` (only a patch
increment from `0.2.0`) rather than the expected major bump. This suggests the breaking
detection only fires when the project has already reached 1.x.y or that the detection
applies the ifFoundBumpBreaking check against a specific section rather than free text.

The safe conclusion: without explicit configuration of `ifFoundBumpBreaking` and testing
on a project already past `1.0.0`, the breaking-change detection behaves unexpectedly.

### Stage 5 — changelogPush (fails)

`changelogPush` ran `changelogInternalPushWillRun` then `changelogCheck`, which reported:

```
Execution failed for task ':changelogCheck'.
> The working copy is not clean, make a commit first. Uncommitted changes:
    .gradle/8.8/fileHashes/fileHashes.lock
    build/classes/java/main/tipcalc/Main.class
    .gradle/buildOutputCleanup/buildOutputCleanup.lock
    build/tmp/compileJava/previous-compilation-data.bin
    ...
```

The failure mode is more strict than expected. `changelogPush` requires a completely clean
working copy — including Gradle's own `.gradle/` cache files and compiled class files.
This means `changelogPush` must be run in a CI environment where the repository is clean
before the push step, or a `.gitignore` must explicitly exclude all build and cache files.
Without a `.gitignore` in the experiment repo, the build artefacts register as uncommitted
changes and block the push.

## Final git log

```
77c6c6f (HEAD -> master, tag: v0.3.0) chore(release): changelog bump stage 4b
49e548d feat!: weighted bill split by person
112fad3 (tag: v0.2.0) chore(release): changelog bump stage 4a
86a24f0 feat: split bill evenly among diners
8b4de66 (tag: v0.1.0) chore(release): changelog bump stage 2
3885177 docs: initialize CHANGELOG.md with [Unreleased] for v1
2d62aed feat: compute tip for a single bill
```

## Final CHANGELOG.md

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.3.0] - 2026-06-02

### Changed
- **BREAKING** Split API now accepts per-person weights instead of equal split

### Added
- Weighted bill split (Ada:3, Linus:2, Grace:3, Dennis:2)

## [0.2.0] - 2026-06-02

### Added
- Split the bill evenly among 4 diners

## [0.1.0] - 2026-06-02

### Added
- Compute tip for a restaurant bill at 18% rate
- Print bill, tip amount, and total to stdout
```

## Summary of findings

| Claim | Reality |
|-------|---------|
| Task `printLastChangelog` | Does not exist; correct name is `changelogPrint` |
| First version from `[Added]` is `1.0.0` | Actual: `0.1.0` (plugin starts from implicit `0.0.0`) |
| `**BREAKING**` triggers major bump | Did NOT produce major bump in this experiment (`0.2.0 -> 0.3.0`) |
| `changelogPush` fails only due to no remote | Also fails if working copy is dirty (build artefacts without .gitignore) |
| Empty `[Unreleased]` removed after bump | Plugin leaves empty `## [Unreleased]` placeholder after every bump |
