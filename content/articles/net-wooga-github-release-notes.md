Title: net.wooga.github-release-notes
Date: 2026-05-31
Slug: net-wooga-github-release-notes
Ecosystem: Java
Tags: github-integration, gradle-plugin, java, release-notes, github-releases, mature
Tool_URL: https://plugins.gradle.org/plugin/net.wooga.github-release-notes
Tool_Version: 4.1.1
Tool_Status: unmaintained
Summary: Gradle plugin providing tasks and conventions for GitHub release-note messages.



## Overview

`net.wooga.github-release-notes` is a Gradle plugin from Wooga's Atlas release tooling family. It helps Gradle builds assemble GitHub release-note messages, especially in workflows that publish libraries or packages through GitHub Releases.

This is a narrower and more mature/legacy entry than JetBrains' changelog plugin or DiffPlug's changelog-as-version-source plugin. It is most relevant if a project already uses Wooga Atlas release conventions.

## Installation

Add to `build.gradle.kts`:

```kotlin
plugins {
    id("net.wooga.github-release-notes") version "4.1.1"
}
```

## What It Does

- Adds Gradle tasks and conventions for GitHub release-note content.
- Works as part of Wooga/Atlas release automation rather than as a standalone changelog system.
- Helps generate or provide release-note messages for GitHub Releases.
- Fits Gradle builds that need release metadata during publication.

## Configuration

Configuration follows Gradle plugin conventions and is best understood as part of the surrounding Atlas release setup. A minimal build applies the plugin and wires release-note output into the release process:

```groovy
plugins {
  id 'net.wooga.github-release-notes' version '4.1.1'
}

githubReleaseNotes {
  // Configure release-note source and GitHub release message conventions here.
}
```

First-run setup is moderate if the project is already using Wooga Atlas release plugins, and high if not. The public documentation surface is much thinner than the larger tools in this survey.

## Output Quality

The plugin's output is GitHub-release-message oriented rather than a durable `CHANGELOG.md` workflow:

```markdown
## Release Notes

- Add Gradle publication metadata for GitHub release assets.
- Fix release-note rendering for snapshot builds.
```

That is useful inside a GitHub Release, but it is less compelling as the central changelog strategy for a Java project.

## Ecosystem Fit

The plugin is Gradle-native and useful in the Wooga ecosystem. Outside that context, modern teams are more likely to reach for GitHub's generated release notes, Release Drafter, `org.jetbrains.changelog`, or a general git-based generator.

Its main value is compatibility with an existing Atlas release setup, not broad Java ecosystem leadership.

## Maintenance Status

- Latest version: **4.1.1**
- Last release: **2024-01-16**
- GitHub stars: **0**
- Project appears mature and low-visibility rather than broadly active.
- Repository: <a href="https://github.com/wooga/atlas-release" target="_blank" rel="noopener noreferrer">https://github.com/wooga/atlas-release</a>

The generated API docs are still available, but the plugin has a narrower ecosystem footprint than the other Java entries here.

## Verdict

**Verdict: Situational**

Use `net.wooga.github-release-notes` only when a Gradle project already depends on Wooga Atlas release tooling or needs this specific GitHub release-note convention. For a new Java changelog workflow, start with JetBrains' changelog plugin, DiffPlug's changelog-as-source approach, or a more general release-note generator.
