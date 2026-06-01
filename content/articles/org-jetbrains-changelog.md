Title: org.jetbrains.changelog
Date: 2026-05-31
Slug: org-jetbrains-changelog
Ecosystem: Java
Tags: gradle-plugin, java, kotlin, keep-a-changelog, release-notes, intellij-plugin, ci-cd
Tool_URL: https://plugins.gradle.org/plugin/org.jetbrains.changelog
Tool_Version: 2.5.0
Tool_Status: active
Summary: JetBrains Gradle plugin with tasks and helpers for working with Keep a Changelog style changelogs.



## Overview

`org.jetbrains.changelog` is JetBrains' Gradle plugin for maintaining and extracting changelog content from a Keep a Changelog-style file. It is especially common in IntelliJ Platform plugin projects, where the release process needs a formatted changelog section for plugin XML, Marketplace release notes, or publishing tasks.

This is not a commit-history generator. It assumes the changelog is a maintained source file, then gives Gradle tasks and helper APIs to validate, patch, and reuse the right release section.

## Installation

Add to `build.gradle.kts`:

```kotlin
plugins {
    id("org.jetbrains.changelog") version "2.5.0"
}
```

## What It Does

- Reads and manages Keep a Changelog-style release sections.
- Provides Gradle tasks such as extracting changelog content for the current version.
- Patches the changelog when a release is cut, moving unreleased content into a versioned section.
- Exposes helper methods for wiring changelog text into other Gradle tasks.
- Fits IntelliJ Platform plugin release workflows where plugin metadata needs change notes.

## Configuration

Configuration lives in the Gradle build script through the `changelog` extension. A minimal setup points the plugin at the changelog file and declares project metadata.

```kotlin
changelog {
    version.set(project.version.toString())
    path.set("${project.projectDir}/CHANGELOG.md")
    header.set(provider { "[${project.version}] - 2026-05-31" })
    groups.set(listOf("Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"))
}

tasks.patchChangelog {
    releaseNote.set("Release ${project.version}")
}
```

First-run setup is modest if the project already follows Keep a Changelog. The main decision is whether the changelog remains the release source of truth, because this plugin works best when humans maintain the entries.

## Output Quality

Output quality is high when the source `CHANGELOG.md` is good, because the plugin extracts hand-written prose rather than synthesizing commit summaries:

```markdown
## [2.5.0] - 2026-05-31

### Added

- Add Marketplace release-note extraction for the current plugin version.

### Fixed

- Preserve Markdown links when patching the changelog during release.
```

The plugin helps keep release sections predictable and reusable, but it will not improve vague or missing changelog entries.

## Ecosystem Fit

The fit is strongest for Gradle, Kotlin, and IntelliJ Platform plugin projects. It integrates naturally with Gradle tasks and can feed changelog text into broader publishing workflows.

For ordinary Java libraries that generate release notes from commits, `git-changelog-maven-plugin`, `git-cliff`, or Release Drafter may be a better match. For manually maintained Gradle changelogs, this is one of the most relevant Java ecosystem tools.

## Maintenance Status

- Latest version: **2.5.0**
- Last release: **2025-11-25**
- GitHub stars: **297**
- Appears actively maintained.
- Repository: <a href="https://github.com/JetBrains/gradle-changelog-plugin" target="_blank" rel="noopener noreferrer">https://github.com/JetBrains/gradle-changelog-plugin</a>

The Gradle Plugin Portal shows current 2.x releases, and the source repository remains active under JetBrains.

## Verdict

**Verdict: Recommended**

Use `org.jetbrains.changelog` when a Gradle or IntelliJ plugin project treats `CHANGELOG.md` as a maintained artifact and needs Gradle tasks to extract, patch, and publish release notes. It is not a generator from git history, and that is part of its appeal: the changelog remains intentionally written.
