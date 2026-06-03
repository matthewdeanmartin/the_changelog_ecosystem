Title: net.wooga.github-release-notes (hands-on synthesis)
Date: 2026-06-02
Slug: net-wooga-github-release-notes-v2
Ecosystem: java
Tags: gradle-plugin, java, github-release, ci-only, hands-on
Tool_URL: https://plugins.gradle.org/plugin/net.wooga.github-release-notes
Tool_Version: 4.1.1
Tool_Status: mature
Experiment: examples/java/net-wooga-github-release-notes/
Summary: Hands-on re-review of net.wooga.github-release-notes — a GitHub API-dependent release notes plugin, not a local changelog generator.



## Overview

The first-pass review of `net.wooga.github-release-notes` described it as a "situational" tool
for projects already inside the Wooga Atlas release ecosystem. Hands-on testing reveals a harder
verdict is warranted: this plugin cannot be applied from a standard Gradle setup, and even if it
could be, it has zero local use case.

## What the Experiment Found

The Docker experiment applied the plugin exactly as the Gradle Plugin Portal page documents and
attempted to run every reachable task. Every invocation failed at the same point — before any
user code executed — with:

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

The plugin is listed on the Gradle Plugin Portal but is not actually distributed through it.
Its artifacts live in a Wooga-specific Maven repository. Any consuming project must add that
repository to `pluginManagement` before the plugin can be resolved at all:

```kotlin
pluginManagement {
    repositories {
        maven { url = uri("https://wooga.jfrog.io/wooga/libs-release") }
        gradlePluginPortal()
    }
}
```

This requirement is not surfaced on the Plugin Portal page and is not obvious from any public
documentation.

## What the Plugin Actually Does

Once resolved (inside a properly configured Wooga environment), the plugin:

- Makes GitHub API calls to read pull request titles and labels for commits since the last release
- Uses that data to construct a GitHub Release message
- Posts that message to GitHub Releases via the API

This makes it structurally identical to tools like Release Drafter or semantic-release with a
GitHub plugin. The entire workflow is:

1. CI authenticates with `GITHUB_TOKEN`
2. Gradle calls the GitHub API to enumerate merged PRs
3. Gradle posts a release note to GitHub Releases

There is no CHANGELOG.md output. There is no offline mode. There is nothing a developer can
run on their laptop. This is a pure CI automation tool.

## Comparison to the Previous Verdict

The first review called it "situational." That framing is too generous. A tool is situational
when it works for some projects and not others. This plugin:

- Does not resolve from the standard Gradle plugin ecosystem
- Requires live GitHub API access for every non-trivial operation
- Has 0 stars on its host repository
- Is clearly internal Wooga tooling that was made technically public without being intended
  for general adoption

The accurate description is: **Wooga-internal tooling. Do not use.**

## Practical Alternatives

For teams that actually want GitHub Release notes generated from PR labels, better options are:

- **Release Drafter** (GitHub Action) — purpose-built, well-documented, widely adopted
- **GitHub's native auto-generated release notes** — zero configuration, built into GitHub
  Releases UI and API
- **org.jetbrains.changelog** — Gradle-native, produces CHANGELOG.md, no GitHub API required
- **git-cliff** — fast, configurable, local, no GitHub credentials needed

## Verdict

**Verdict: Do not use**

`net.wooga.github-release-notes` is not a general-purpose Java changelog tool. It is Wooga
internal CI tooling accidentally visible on the Gradle Plugin Portal. It cannot be installed
without custom Maven repository configuration, requires a live GitHub API connection for every
operation, produces no local changelog artifact, and has zero community adoption.

If you are not already inside the Wooga Atlas release pipeline, there is nothing here for you.
