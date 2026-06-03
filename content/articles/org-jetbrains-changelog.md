Title: org.jetbrains.changelog (Gradle Changelog Plugin)
Date: 2026-06-02
Slug: org-jetbrains-changelog
Ecosystem: Java
Tags: gradle-plugin, java, kotlin, keep-a-changelog, release-notes, intellij-plugin, ci-cd, hands-on
Tool_URL: https://plugins.gradle.org/plugin/org.jetbrains.changelog
Tool_Version: 2.5.0
Tool_Status: active
Experiment: examples/java/org-jetbrains-changelog/
Summary: JetBrains Gradle plugin for validating, patching, and extracting Keep a Changelog sections; hands-on testing confirms the patch/extract loop is reliable, with bracket-stripping and a fragile getChangelog preview as rough edges.



## Overview

`org.jetbrains.changelog` is JetBrains' Gradle plugin for maintaining and extracting changelog content from a Keep a Changelog-style file. It is especially common in IntelliJ Platform plugin projects, where the release process needs a formatted changelog section for plugin XML, Marketplace release notes, or publishing tasks.

This is not a commit-history generator. It assumes the changelog is a maintained source file, then gives Gradle tasks and helper APIs to validate, patch, and reuse the right release section.

A reproducible hands-on experiment for this tool lives in [`examples/java/org-jetbrains-changelog/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/java/org-jetbrains-changelog). The notes below the configuration section are grounded in that run.

## Installation

Add to `build.gradle.kts`:

```kotlin
plugins {
    id("org.jetbrains.changelog") version "2.5.0"
}
```

## What It Does

- Reads and manages Keep a Changelog-style release sections.
- Provides Gradle tasks such as `getChangelog` to extract changelog content for the current version.
- `patchChangelog` promotes unreleased content into a versioned section when a release is cut.
- Exposes helper methods for wiring changelog text into other Gradle tasks.
- Fits IntelliJ Platform plugin release workflows where plugin metadata needs change notes.

## Configuration

Configuration lives in the Gradle build script through the `changelog` extension. A minimal setup points the plugin at the changelog file and declares project metadata.

```kotlin
changelog {
    version.set(project.version.toString())
    path.set("${project.projectDir}/CHANGELOG.md")
    header.set(provider { "[${project.version}] - 2026-06-02" })
    groups.set(listOf("Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"))
}

tasks.patchChangelog {
    releaseNote.set("Release ${project.version}")
}
```

First-run setup is modest if the project already follows Keep a Changelog. The main decision is whether the changelog remains the release source of truth, because this plugin works best when humans maintain the entries.

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

---

## Hands-on findings

I built a minimal Java/Gradle tip calculator and drove it through three releases (v1.0.0, v2.0.0, v3.0.0) using `org.jetbrains.changelog` 2.5.0 on Gradle 8.8 / JDK 21 (Alpine). For each release: seed the `[Unreleased]` section with a change description, run `gradle patchChangelog` to promote it to a versioned section, commit, tag. I also exercised `gradle getChangelog` before any versioned section existed and after v3.0.0. The plugin resolves from the Gradle Plugin Portal with no extra repository configuration (network required on first build only).

### `getChangelog` on an unreleased-only changelog — fails

```
> Task :getChangelog FAILED

* What went wrong:
Execution failed for task ':getChangelog'.
> org.jetbrains.changelog.exceptions.MissingVersionException: Version is missing: any
```

`getChangelog` looks for a versioned section matching `project.version`, not the `[Unreleased]` block. Calling it before the first `patchChangelog` is a build error — there is no "preview unreleased" mode.

### `patchChangelog` — reliable

The task moved `[Unreleased]` to `[1.0.0]` and seeded a fresh `## Unreleased` stub (note: bracketless) pre-populated with the configured groups. It worked cleanly across all three cycles.

### `getChangelog` after v3.0.0 — clean extraction

```
> Task :getChangelog
## 3.0.0

### Added

- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2)

BUILD SUCCESSFUL in 5s
```

### Real final `CHANGELOG.md`

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

### Changed

### Fixed

## [3.0.0]

### Added

- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2)

## 2.0.0

### Added

- Split the bill evenly among 4 diners

## 1.0.0

### Added

- Compute tip for a restaurant bill at 18% rate
- Print bill, tip, and total to stdout
```

Note that only `[3.0.0]` keeps its brackets — `2.0.0` and `1.0.0` lost theirs during patching.

### Pros (observed)

- **Zero friction for the happy path.** A `plugins {}` line plus a `changelog {}` block is all it takes; `patchChangelog` works on the first run with no wrapper generation or extra repositories.
- **`patchChangelog` is reliable.** It correctly promoted `[Unreleased]` to a versioned section in all three cycles.
- **`getChangelog` is useful downstream.** Once a versioned section exists, it prints clean Markdown that can be piped into a publish task or release action — exactly the section body, no scaffolding.
- **Plugin Portal resolution is seamless.** A single `id("org.jetbrains.changelog") version "2.5.0"` line; no additional repository configuration.
- **Gradle cache means only the first invocation is slow.** Subsequent `patchChangelog` calls completed in 5 seconds each.

### Cons / pain points (observed)

- **`getChangelog` fails when there are no versioned sections.** Previewing `[Unreleased]` before cutting a release throws `MissingVersionException: Version is missing: any`. The only useful pre-release operation is reading the file directly.
- **`patchChangelog` leaves a permanent empty `## Unreleased` stub** (bracketless, pre-seeded with group headings). Intentional — it seeds the next cycle — but it means the file always carries an empty section and drifts from strict KAC, which calls for `## [Unreleased]` with brackets.
- **Older sections lose their brackets.** After each patch, previously versioned headings drop their brackets (`## [1.0.0]` → `## 1.0.0`). Only the most recently patched section keeps them, so the file grows progressively less KAC-conformant.
- **No `checkChangelog` CI gate.** The docs mention validation, but no `checkChangelog` task is registered in 2.5.0. There is no built-in way to fail a build on an empty or malformed changelog without custom Gradle code.
- **Daemon noise on every invocation.** Even with `--no-daemon`, the Alpine image emits a "single-use Daemon process will be forked" warning each call — a container JVM memory issue, not a plugin defect, but it clutters CI logs.
- **Injecting `[Unreleased]` content means working around the plugin's own stub.** Because `patchChangelog` writes a bracketless `## Unreleased`, a hand-written `## [Unreleased]` lands as a second section below it. The plugin treats the bracketed one as canonical so it still works, but the orphaned stub accumulates across releases and can confuse readers and tooling.

### Docs vs. reality

The docs describe `getChangelog` as extracting "the changelog item for the current version." In practice "current version" means the project version from `build.gradle.kts`, and the task looks for a versioned heading — not `[Unreleased]`. The docs do not clearly state it fails before any versioned section exists, so a developer following them literally (configure, write `[Unreleased]`, call `getChangelog` to preview) hits a build failure on first interaction. The bracket-stripping of older sections is undocumented. The empty `## Unreleased` stub is documented under `patchChangelog` but easy to miss.

## Verdict

**Verdict: Conditionally recommended — best for IntelliJ plugin projects.**

`org.jetbrains.changelog` does the one thing it was designed for — promoting `[Unreleased]` to a versioned section and making that section available to Gradle tasks — reliably and with minimal configuration. For IntelliJ Platform plugin projects, where the release process already includes Gradle tasks that need formatted changelog text, it is the right tool.

For general Java or Gradle projects, the rough edges matter more: the `getChangelog` failure on an unreleased-only file, the bracket-stripping of older sections, and the absence of a CI validation gate all mean the plugin needs more care than the docs suggest. A team that treats `CHANGELOG.md` as a strict KAC artifact will find the output drifts without manual cleanup.

If the primary goal is changelog extraction for a publish pipeline and the team already uses Gradle, this remains the best available option in the Java ecosystem. If the goal is strict format compliance or a human-readable change history, budget a cleanup step after each patch.
