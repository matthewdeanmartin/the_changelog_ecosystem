Title: git-changelog-maven-plugin
Date: 2026-06-02
Slug: git-changelog-maven-plugin
Ecosystem: Java
Tags: java, maven-plugin, release-notes, git-history, jira, custom-templates, changelog-file, conventional-commits, templates, hands-on
Tool_URL: https://github.com/tomasbjerre/git-changelog-maven-plugin
Tool_Version: 2.2.11
Tool_Status: active
Experiment: examples/java/git-changelog-maven-plugin/
Summary: Maven plugin that renders changelogs from git history and tags via Handlebars templates; hands-on testing confirms reliable tag grouping, with documentation gaps around parameter names and Conventional Commits.



## Overview

`git-changelog-maven-plugin` is the Maven wrapper around the `git-changelog` generator by Tomas Bjerre. It reads git history, applies configured issue and commit parsing rules, and renders changelogs or release notes with templates.

Compared with Apache Maven Changelog Plugin, this is much closer to a modern release-note generator. It is still Maven-native, but its output is intended to be customized and published rather than only embedded as an SCM report in a Maven Site.

A reproducible hands-on experiment for this tool lives in [`examples/java/git-changelog-maven-plugin/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/java/git-changelog-maven-plugin). The notes below the configuration section are grounded in that run.

## Installation

Add to `pom.xml`:

```xml
<plugin>
  <groupId>se.bjurr.gitchangelog</groupId>
  <artifactId>git-changelog-maven-plugin</artifactId>
  <version>2.2.11</version>
</plugin>
```

## What It Does

- Generates changelog or release-note files from git commits and tags.
- Supports Handlebars-style templating through the underlying git-changelog engine.
- Can link commits and issues to hosting or tracker URLs.
- Includes Jira-aware configuration for teams that use ticket IDs in commits.
- Runs as a Maven plugin goal, so it can be part of `mvn verify`, `mvn site`, or a release profile.

## Configuration

Configuration is Maven XML inside the plugin declaration. Real projects usually define a template, output file, tag or revision range, and issue-linking rules.

```xml
<plugin>
  <groupId>se.bjurr.gitchangelog</groupId>
  <artifactId>git-changelog-maven-plugin</artifactId>
  <version>2.2.11</version>
  <configuration>
    <file>CHANGELOG.md</file>
    <templateContent><![CDATA[
# Changelog

{{#tags}}
## {{name}}
{{#commits}}
- {{messageTitle}}
{{/commits}}

{{/tags}}
]]></templateContent>
    <jiraIssuePattern>PROJ-([0-9]+)</jiraIssuePattern>
  </configuration>
</plugin>
```

Note the output parameter is `<file>`, not `<toFile>` — see the hands-on findings below. First-run setup is moderate; the template and issue parsing need deliberate tuning before output feels like release notes rather than a filtered commit list.

## Ecosystem Fit

This is a strong fit for Maven projects that want changelog generation inside the Maven lifecycle, especially enterprise Java projects where Jira IDs and Maven release profiles are already central.

Gradle projects should look elsewhere, and teams that want broader cross-language tooling may prefer `git-cliff`. But for Maven-first release automation, this is one of the better Java-specific entries.

## Maintenance Status

- Latest version: **2.2.11**
- Last release: **2025-07-29**
- GitHub stars: **93**
- Appears actively maintained.
- Repository: <a href="https://github.com/tomasbjerre/git-changelog-maven-plugin" target="_blank" rel="noopener noreferrer">https://github.com/tomasbjerre/git-changelog-maven-plugin</a>

The plugin remains published in Maven Central and the GitHub repository is active enough to consider for current Maven projects.

---

## Hands-on findings

The experiment builds a minimal Maven project (`tipcalc`) inside Docker (`maven:3.9-eclipse-temurin-21-alpine`, Maven 3.9.16, JDK 21), creates a real git repository, and walks the plugin through three tagged releases using conventional commit messages:

- `v1.0.0` — `feat: compute tip for a single bill`
- `v2.0.0` — `feat: split the bill evenly among diners`
- `v3.0.0` — `feat!: split the bill unevenly by weight`

The plugin was bound to the `generate-resources` phase and the changelog regenerated with `mvn --batch-mode generate-resources` after each tag. The underlying `git-changelog-lib` resolved was 2.6.1.

### Real output

After all three releases the generated `CHANGELOG.md` was:

```markdown
# Changelog

## v3.0.0
- feat!: split the bill unevenly by weight

## v2.0.0
- feat: split the bill evenly among diners

## v1.0.0
- feat: compute tip for a single bill
```

Tag grouping works exactly as expected: each tagged version gets its own heading, commits are listed in reverse-chronological tag order, and the commit message title is reproduced verbatim. Critically, the breaking-change marker `feat!:` is passed through **unchanged** — the plugin does not interpret Conventional Commits prefixes on its own.

The cold first run took roughly 60 seconds to resolve the dependency graph from Maven Central; warm second and third runs each completed in about one second.

### Discovered issue: wrong parameter name in documentation

Official documentation and plugin examples show `<toFile>` as the output file parameter. In version 2.2.11 the actual parameter name is `<file>`. Maven emits a warning but does not fail:

```
[WARNING] Parameter 'toFile' is unknown for plugin
  'git-changelog-maven-plugin:2.2.11:git-changelog (generate-changelog)'
```

The plugin falls back to writing `CHANGELOG.md` by default, so the misconfiguration does not break the build — it is silent. Anyone copying the documented example verbatim is running with an ignored directive and may not notice.

### Pros (observed)

- **Minimal setup.** One plugin block, one template string, bind to a Maven phase. No extra tools.
- **Tag grouping comes for free** via JGit — annotated and lightweight tags are discovered without configuration.
- **Handlebars templating is expressive.** The `{{#tags}}`, `{{#commits}}`, and `{{messageTitle}}` variables work as documented and produce readable output.
- **Runs entirely within the Maven lifecycle.** No separate CLI install, no CI plugin needed.
- **Warm runs are fast (~1s).** The dependency graph is downloaded once and cached.

### Cons / pain points (observed)

- **`<toFile>` vs `<file>` documentation error.** The plugin silently ignores the unknown parameter and falls back to a default. This is the kind of mismatch that leads to hours of debugging when output lands in an unexpected location.
- **No built-in Conventional Commits grouping.** The plugin does not parse `feat:`, `fix:`, `feat!:`, or `BREAKING CHANGE` tokens natively. A grouped changelog (Features / Breaking Changes / Bug Fixes) requires writing the grouping logic by hand in the template.
- **The `{{#issues}}` block silently renders nothing** unless issue patterns (`<jiraIssuePattern>` or similar) are configured. A newcomer following the docs gets a working but empty issues section and may debug the template instead of realising a prerequisite is missing.
- **Heavy transitive dependency graph.** The plugin pulls in JGit, Handlebars, Jackson, OkHttp, Retrofit, Nashorn, and Kotlin stdlib — a lot for a changelog generator. A cold-start cost and a supply-chain consideration.
- **Maven-only.** No path to Gradle or non-JVM projects.

### Docs vs. reality

The plugin works as described for the core workflow: bind a template, run a Maven phase, get a changelog grouped by tag. The mechanics are sound. Two documentation gaps caused friction, and both sit exactly where new users land first:

1. The `<toFile>` parameter name is wrong in 2.2.11; the parameter is `<file>`. Maven warns but does not error.
2. Template examples using `{{#issues}}` require issue patterns to be configured, or the block iterates zero items.

## Verdict

**Verdict: Recommended with caveats.**

The plugin delivers reliable changelog generation inside the Maven lifecycle with minimal ceremony. Tag grouping works, templates are flexible, and warm runs are fast. For a Maven-native team that wants `mvn verify` or a release profile to also write a `CHANGELOG.md`, this is a practical option with no close competitors inside the Maven ecosystem.

The caveats are real: fix the `<toFile>` parameter name before copying from the README, do not expect Conventional Commits grouping without template work, and budget time to understand why the `{{#issues}}` block renders nothing on a fresh install. None of these are hard problems once identified, but the documentation leaves the discovery work to the user.

Teams that want zero-config Conventional Commits output — type prefixes automatically mapped to sections, breaking changes called out, footers parsed — should look at `git-cliff` or `semantic-release` instead. This plugin is a Handlebars renderer over JGit, not a Conventional Commits processor.
