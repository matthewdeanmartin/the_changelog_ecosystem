Title: Spotless Changelog
Date: 2026-06-02
Slug: com-diffplug-spotless-changelog
Ecosystem: Java
Tags: gradle-plugin, java, keep-a-changelog, validation, version-compute, release-commit, git-tag, changelog-source-of-truth, hands-on
Tool_URL: https://plugins.gradle.org/plugin/com.diffplug.spotless-changelog
Tool_Version: 3.1.2
Tool_Status: active
Experiment: examples/java/spotless-changelog/
Summary: Gradle plugin that validates Keep a Changelog compliance and computes release versions from the changelog; hands-on testing confirms the core loop works, with documented sharp edges.



## Overview

`com.diffplug.spotless-changelog` is a Gradle plugin from DiffPlug that treats `CHANGELOG.md` as the release source of truth. It validates Keep a Changelog-style structure, computes the next version from changelog sections, and can drive release commits and tags.

This is almost the inverse of commit-derived changelog generators. Instead of asking git history what changed, it asks the changelog what version should be released.

A reproducible hands-on experiment for this tool lives in [`examples/java/spotless-changelog/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/java/spotless-changelog). The notes below the configuration section are grounded in that run.

## Installation

Add to `build.gradle.kts`:

```kotlin
plugins {
    id("com.diffplug.spotless-changelog") version "3.1.2"
}
```

## What It Does

- Validates that a changelog stays formatted and structured.
- Computes the next version from changelog content, including breaking, added, and fixed sections.
- Can append `-SNAPSHOT` outside release mode.
- Provides release tasks that commit the changelog, create a git tag, and push release metadata.
- Can be wired to update README badges or other files with the latest version.

## Configuration

Configuration lives in the Gradle `spotlessChangelog` extension. The defaults are opinionated, but projects can configure the changelog file, version schema, tag prefix, commit message, and version bump rules.

```groovy
spotlessChangelog {
  changelogFile 'CHANGELOG.md'
  enforceCheck true
  ifFoundBumpBreaking ['**BREAKING**']
  ifFoundBumpAdded ['### Added']
  tagPrefix 'v'
  commitMessage 'Release {{version}}'
  appendDashSnapshotUnless_dashPrelease = true
}
```

First-run setup is moderate because the project must accept the plugin's philosophy: release versioning flows from the changelog. Once adopted, that can simplify release decisions.

## Ecosystem Fit

This is a niche but very Gradle-native tool. It fits teams that already like explicit changelogs and want Gradle to enforce them as part of the release process.

It is not a good match for teams that want release notes generated from commits, pull requests, or Jira tickets. It is strongest when the changelog is deliberately written first and automation follows.

## Maintenance Status

- Latest version: **3.1.2**
- GitHub stars: **48**
- Appears actively maintained.
- Repository: <a href="https://github.com/diffplug/spotless-changelog" target="_blank" rel="noopener noreferrer">https://github.com/diffplug/spotless-changelog</a>

The repository documents the plugin DSL and describes a release workflow built around changelog validation, computed versions, release commits, and tags.

---

## Hands-on findings

I built a three-version tip-calculator scenario in an isolated Docker container (`gradle:8.8-jdk21-alpine`, Gradle 8.8, OpenJDK 21) and drove the plugin through its full workflow: `changelogCheck`, `changelogBump`, `changelogPrint`, and `changelogPush`. The full transcript and final `CHANGELOG.md` are in [`examples/java/spotless-changelog/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/java/spotless-changelog).

Setup was deliberately minimal:

```kotlin
spotlessChangelog {
    changelogFile("CHANGELOG.md")
    enforceCheck(false)   // don't block normal builds on validation
}
```

Each version cycle was: edit `CHANGELOG.md`, run `changelogCheck` to validate structure, run `changelogPrint` to preview the computed version, run `changelogBump` to stamp the date and rename the `[Unreleased]` section, commit, tag.

### Task discovery

```
Changelog tasks
changelogBump   - updates the changelog on disk with the next version and the current UTC date
changelogCheck  - checks that the changelog is formatted according to your rules
changelogPrint  - prints the last published version and the calculated next version
changelogPush   - commits the bumped changelog, tags it, and pushes
```

There is no `printLastChangelog` task. Some older blog posts and docs reference that name; the correct task is `changelogPrint`.

### `changelogCheck` — worked exactly as documented

With a valid Keep a Changelog structure the task passed silently. With a duplicate `## [Unreleased]` accidentally introduced it failed fast with a precise line number and message:

```
Execution failed for task ':changelogCheck'.
> CHANGELOG.md:19: '] - ' is missing from the expected '## [x.y.z] - yyyy-mm-dd'
```

That is genuinely useful — line number, expected format, actual content.

### `changelogPrint` — version preview (the real output)

This is where the imagined-output expectations diverge from reality. Before the first ever release, with no prior version in the file:

```
tipcalc null -> 0.1.0
```

The plugin treats "no prior version" as `null` and computes from an implicit `0.0.0` base. A `### Added` section triggers a minor bump to **`0.1.0`, not `1.0.0`**. This is not obvious from the documentation. Projects wanting `1.0.0` as their first release must configure an explicit `nextVersion` starting point.

Subsequent bumps:

```
tipcalc 0.1.0 -> 0.2.0    (Added section, minor bump)
tipcalc 0.2.0 -> 0.3.0    (Changed + Added sections)
```

### `changelogBump` — stamp + rename works cleanly

`changelogBump` renames `## [Unreleased]` to `## [0.1.0] - 2026-06-02` (date stamped in UTC on the day you run it) and automatically leaves a new empty `## [Unreleased]` placeholder at the top of the file so it stays structurally valid for the next cycle. The real final file after three releases:

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

Because the empty placeholder is always present, any tooling that injects the next `[Unreleased]` block must replace the placeholder rather than prepend a new one — insert naively and you end up with two `## [Unreleased]` sections and `changelogCheck` fails.

### Breaking-change detection — did not fire below 1.x

I included a `**BREAKING**` marker inside a `### Changed` bullet. `changelogPrint` reported `0.2.0 -> 0.3.0` — a minor bump, not a major bump. The default `ifFoundBumpBreaking` is configured to find `**BREAKING**`, but the major bump did not trigger on a `0.x.y` project (bumping major on `0.x.y` would jump to `1.0.0`, which carries special semver meaning). This is not documented clearly. To exercise breaking detection reliably, the project should already be at `1.0.0` or above.

### `changelogPush` — strict clean-working-copy requirement

`changelogPush` requires a completely clean working copy — not just no uncommitted source edits, but no untracked build artifacts either. Without a `.gitignore` covering `build/`, `.gradle/`, and generated class files, it fails immediately:

```
Execution failed for task ':changelogCheck'.
> The working copy is not clean, make a commit first. Uncommitted changes:
    .gradle/8.8/fileHashes/fileHashes.lock
    build/classes/java/main/tipcalc/Main.class
    ...
```

In a real project these paths are gitignored and the check passes. In a fresh repo it is the first thing you hit. The message names the offending files, so diagnosis is easy once you understand what it checks.

### Docs vs. reality

| Documented behaviour | Observed behaviour |
|---|---|
| Task `printLastChangelog` exists | Does not exist; use `changelogPrint` |
| `### Added` → minor bump | Correct, but produces `0.1.0` not `1.0.0` on a fresh project |
| `**BREAKING**` → major bump | Did not trigger on a `0.x.y` project |
| `changelogPush` fails only if no remote | Also fails if working copy is dirty (build artefacts) |
| `changelogBump` stamps date in UTC | Correct and reliable |
| `changelogCheck` validates KAC structure | Correct, with helpful line-number messages |

## Verdict

**Verdict: Situational — with caveats.**

The core loop — write changelog, `changelogCheck`, `changelogBump`, commit, tag — works reliably, and hands-on testing confirms the validation is genuinely useful and the automatic UTC date-stamping removes a manual step from every release.

The version-computation logic has sharp edges the documentation does not address well: the implicit `0.0.0` start base (first release is `0.1.0`, not `1.0.0`), breaking-change detection that does not fire below `1.x.y`, and the strict clean-working-copy requirement in `changelogPush`. These are not showstoppers for a team that reads the source and configures the plugin carefully, but they will surprise anyone who reads the README and expects it to "just work."

Teams with a clean Gradle project, a proper `.gitignore`, a desire for KAC validation in CI, and willingness to configure `nextVersion` and breaking-change patterns explicitly will get real value here. Teams looking for a zero-ceremony first release at `1.0.0` should read the configuration docs carefully before adopting it.
