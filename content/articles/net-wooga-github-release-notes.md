Title: GitHub Release Notes (net.wooga)
Date: 2026-06-02
Slug: net-wooga-github-release-notes
Ecosystem: Java
Tags: github-integration, gradle-plugin, java, release-notes, github-releases, mature, ci-only, hands-on
Tool_URL: https://plugins.gradle.org/plugin/net.wooga.github-release-notes
Tool_Version: 4.1.1
Tool_Status: mature
Experiment: examples/java/net-wooga-github-release-notes/
Summary: Gradle plugin that builds GitHub Release messages from PR data via the GitHub API; hands-on testing found it cannot be resolved from the standard Gradle Plugin Portal and produces no local changelog artifact.



## Overview

`net.wooga.github-release-notes` is a Gradle plugin from Wooga's Atlas release tooling family. It helps Gradle builds assemble GitHub release-note messages, especially in workflows that publish libraries or packages through GitHub Releases.

This is a narrower and more legacy entry than JetBrains' changelog plugin or DiffPlug's changelog-as-version-source plugin. It is most relevant if a project already uses Wooga Atlas release conventions.

A reproducible hands-on experiment for this tool lives in [`examples/java/net-wooga-github-release-notes/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/java/net-wooga-github-release-notes).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), this plugin could not be driven through any life cycle: applied exactly as the Gradle Plugin Portal documents, every build failed with "Plugin … was not found" because the artifact is not actually distributed through the Plugin Portal — it lives in a Wooga-specific Maven repository that must be added to <code>pluginManagement</code> first. Even once resolved, the plugin is CI-only: it needs live GitHub API access and a <code>GITHUB_TOKEN</code>, and produces no local changelog file. It appears to be internal Wooga tooling made technically public. It is not unusable inside the Wooga ecosystem, but for general adoption you would likely need to fork it and fix the distribution yourself. See the hands-on findings below.
</div>

## Installation

The Gradle Plugin Portal page suggests:

```kotlin
plugins {
    id("net.wooga.github-release-notes") version "4.1.1"
}
```

As the hands-on findings show, this alone does not resolve. The consuming project must also declare the Wooga Maven repository in `settings.gradle.kts`:

```kotlin
pluginManagement {
    repositories {
        maven { url = uri("https://wooga.jfrog.io/wooga/libs-release") }
        gradlePluginPortal()
    }
}
```

## What It Does

Once resolved (inside a properly configured Wooga environment), the plugin:

- Makes GitHub API calls to read pull request titles and labels for commits since the last release.
- Uses that data to construct a GitHub Release message.
- Posts that message to GitHub Releases via the API.

This makes it structurally similar to Release Drafter or `semantic-release` with a GitHub plugin. The entire workflow is CI-centric: authenticate with `GITHUB_TOKEN`, enumerate merged PRs via the GitHub API, post a release note to GitHub Releases. There is no `CHANGELOG.md` output, no offline mode, and nothing a developer can run on a laptop.

## Ecosystem Fit

The plugin is Gradle-native and useful inside the Wooga ecosystem. Outside that context, modern teams are more likely to reach for GitHub's generated release notes, Release Drafter, `org.jetbrains.changelog`, or a general git-based generator.

Its main value is compatibility with an existing Atlas release setup, not broad Java ecosystem leadership.

## Maintenance Status

- Latest version: **4.1.1**
- Last release: **2024-01-16**
- GitHub stars: **0**
- Repository: <a href="https://github.com/wooga/atlas-release" target="_blank" rel="noopener noreferrer">https://github.com/wooga/atlas-release</a>

The plugin has a much narrower ecosystem footprint than the other Java entries here and appears to be Wooga-internal tooling published publicly but not maintained for external use.

---

## Hands-on findings

The Docker experiment (`gradle:8.8-jdk21-alpine`, Gradle 8.8) applied the plugin exactly as the Gradle Plugin Portal page documents and attempted to run every reachable task across five stages. Every invocation failed at the same point — before any user code executed:

```
Plugin [id: 'net.wooga.github-release-notes', version: '4.1.1'] was not found
in any of the following sources:

- Gradle Core Plugins (plugin is not in 'org.gradle' namespace)
- Included Builds (No included builds contain this plugin)
- Plugin Repositories (could not resolve plugin artifact
  'net.wooga.github-release-notes:net.wooga.github-release-notes.gradle.plugin:4.1.1')
  Searched in the following repositories:
    Gradle Central Plugin Repository
```

The pre-experiment hypothesis was that the plugin would apply and then fail at runtime when making GitHub API calls without a token. The reality is harder: the plugin is **listed** on the Plugin Portal but its artifacts are not **distributed** there — they live in a Wooga-specific Maven repository. Any consuming project must add that repository to `pluginManagement` before the plugin can be resolved at all. This requirement is not surfaced on the Plugin Portal page or in any obvious public documentation.

No tasks were ever registered, no version line printed, and `out/` contains only the failure transcript.

### Secondary finding: CI-only by design

Even if the plugin resolved, it would still be CI-only. It reads PR labels and titles via the GitHub API and POSTs to the GitHub Releases API — both require `GITHUB_TOKEN` and an actual GitHub remote, neither available in a local or offline context. There is zero local changelog use case.

### Practical alternatives

For teams that actually want GitHub Release notes generated from PR labels:

- **Release Drafter** (GitHub Action) — purpose-built, well-documented, widely adopted.
- **GitHub's native auto-generated release notes** — zero configuration, built into the Releases UI and API.
- **`org.jetbrains.changelog`** — Gradle-native, produces `CHANGELOG.md`, no GitHub API required.
- **`git-cliff`** — fast, configurable, local, no GitHub credentials needed.

## Verdict

**Verdict: Wooga-internal tooling; does not work out of the box and has no local use case.**

`net.wooga.github-release-notes` is not a general-purpose Java changelog tool. It is Wooga internal CI tooling accidentally visible on the Gradle Plugin Portal: it cannot be installed without custom Maven repository configuration, requires a live GitHub API connection for every meaningful operation, produces no local changelog artifact, and has zero community adoption.

It is not unusable inside the Wooga Atlas release pipeline. But if you are not already inside that pipeline, there is nothing here for you — and getting it working for general use would mean forking it and fixing its distribution and documentation yourself. For a new Java changelog workflow, start with `org.jetbrains.changelog`, DiffPlug's changelog-as-source approach, Release Drafter, or a more general release-note generator.
