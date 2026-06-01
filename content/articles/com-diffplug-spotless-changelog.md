Title: com.diffplug.spotless-changelog
Date: 2026-05-31
Slug: com-diffplug-spotless-changelog
Ecosystem: Java
Tags: gradle-plugin, java, keep-a-changelog, validation, version-compute, release-commit, git-tag, changelog-source-of-truth
Tool_URL: https://plugins.gradle.org/plugin/com.diffplug.spotless-changelog
Tool_Version: 3.1.2
Tool_Status: active
Summary: Gradle plugin that checks Keep a Changelog compliance and can compute release versions from the changelog.



## Overview

`com.diffplug.spotless-changelog` is a Gradle plugin from DiffPlug that treats `CHANGELOG.md` as the release source of truth. It validates Keep a Changelog-style structure, computes the next version from changelog sections, and can drive release commits and tags.

This is almost the inverse of commit-derived changelog generators. Instead of asking git history what changed, it asks the changelog what version should be released.

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

## Output Quality

The plugin does not generate prose; it protects and operationalizes hand-written changelog prose:

```markdown
## [1.4.0] - 2026-05-31

### Added

- Add Gradle validation for changelog-backed release versions.

### Fixed

- Keep README version badges aligned after release tagging.
```

Output quality is therefore as good as the humans maintaining `CHANGELOG.md`. The plugin's value is that it makes the changelog harder to forget or drift from the release.

## Ecosystem Fit

This is a niche but very Gradle-native tool. It fits teams that already like explicit changelogs and want Gradle to enforce them as part of the release process.

It is not a good match for teams that want release notes generated from commits, pull requests, or Jira tickets. It is strongest when the changelog is deliberately written first and automation follows.

## Maintenance Status

- Latest version: **3.1.2**
- Last release: **unknown**
- GitHub stars: **48**
- Appears actively maintained.
- Repository: <a href="https://github.com/diffplug/spotless-changelog" target="_blank" rel="noopener noreferrer">https://github.com/diffplug/spotless-changelog</a>

The repository documents the plugin DSL and describes a release workflow built around changelog validation, computed versions, release commits, and tags.

## Verdict

**Verdict: Situational**

Use `com.diffplug.spotless-changelog` when you want the changelog to control release versioning in a Gradle project. It is opinionated, but that opinion is coherent: write the changelog first, then let Gradle enforce and release from it.
