Title: git-changelog-maven-plugin
Date: 2026-05-31
Slug: git-changelog-maven-plugin
Ecosystem: Java
Tags: java, maven-plugin, release-notes, git-history, jira, custom-templates, changelog-file
Tool_URL: https://search.maven.org/artifact/se.bjurr.gitchangelog/git-changelog-maven-plugin
Tool_Version: 2.2.11
Tool_Status: active
Summary: Maven plugin that generates changelogs or release notes from a git repository, with issue tracker integration.



## Overview

`git-changelog-maven-plugin` is the Maven wrapper around the `git-changelog` generator by Tomas Bjerre. It reads git history, applies configured issue and commit parsing rules, and renders changelogs or release notes with templates.

Compared with Apache Maven Changelog Plugin, this is much closer to a modern release-note generator. It is still Maven-native, but its output is intended to be customized and published rather than only embedded as an SCM report in a Maven Site.

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

Configuration is Maven XML inside the plugin declaration. Real projects usually define a template file, output file, tag or revision range, and issue-linking rules.

```xml
<plugin>
  <groupId>se.bjurr.gitchangelog</groupId>
  <artifactId>git-changelog-maven-plugin</artifactId>
  <version>2.2.11</version>
  <configuration>
    <file>CHANGELOG.md</file>
    <templateContent>
      <![CDATA[
      # Changelog
      {{#tags}}
      ## {{name}}
      {{#commits}}
      - {{messageTitle}}
      {{/commits}}
      {{/tags}}
      ]]>
    </templateContent>
    <jiraIssuePattern>PROJ-([0-9]+)</jiraIssuePattern>
  </configuration>
</plugin>
```

First-run setup is moderate. The plugin is powerful, but the template and issue parsing need deliberate tuning before the output feels like release notes rather than a filtered commit list.

## Output Quality

With a focused template and disciplined commits, the plugin can produce clean Markdown:

```markdown
# Changelog

## 2.2.11

### Fixed

- PROJ-184 Preserve Jira links in generated release notes.

### Changed

- Update Maven release profile to write CHANGELOG.md during verify.
```

The quality ceiling is higher than Maven's SCM report plugin because templates can be shaped for readers. The usual commit-derived caveat still applies: poor commit messages create poor changelog entries.

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

## Verdict

**Verdict: Recommended**

Use `git-changelog-maven-plugin` when a Maven project wants generated release notes from git history without leaving the Maven build. It needs template work, but it is a much better fit for user-facing changelogs than Apache Maven's older SCM report plugin.
