Title: maven-changelog-plugin
Date: 2026-05-31
Slug: maven-changelog-plugin
Ecosystem: Java
Tags: java, maven-plugin, maven-site, scm-report, developer-activity, file-activity, legacy
Tool_URL: https://maven.apache.org/plugins/maven-changelog-plugin/
Tool_Version: 3.0.0-M1
Tool_Status: unmaintained
Summary: Apache Maven plugin that generates SCM change reports for Maven sites, including changelog and activity reports.



## Overview

Apache Maven Changelog Plugin is a Maven reporting plugin for SCM activity reports. It generates Maven Site pages that show recent commits, developer activity, and file activity.

This is not a modern user-facing release-note generator. It belongs in the survey because older Maven projects may still associate “changelog” with Maven Site reports, but its output is closer to developer audit reporting than a polished release announcement.

## Installation

Add to the `reporting` section of `pom.xml`:

```xml
<reporting>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-changelog-plugin</artifactId>
      <version>3.0.0-M1</version>
    </plugin>
  </plugins>
</reporting>
```

## What It Does

- Generates `changelog:changelog`, a report of SCM revisions including dates, files, authors, and messages.
- Generates `changelog:dev-activity`, a report summarizing commits and changed files by developer.
- Generates `changelog:file-activity`, a report listing revised files by activity.
- Integrates with Maven Site reporting rather than GitHub/GitLab release publishing.
- Supports selecting which reports to generate through Maven report sets.

## Configuration

Configuration is normal Maven XML. Teams usually configure it inside `<reporting>` and optionally restrict report types or commit ranges.

```xml
<reporting>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-changelog-plugin</artifactId>
      <version>3.0.0-M1</version>
      <reportSets>
        <reportSet>
          <id>release-audit</id>
          <configuration>
            <type>range</type>
            <range>30</range>
          </configuration>
          <reports>
            <report>changelog</report>
            <report>file-activity</report>
          </reports>
        </reportSet>
      </reportSets>
    </plugin>
  </plugins>
</reporting>
```

First-run setup is straightforward if the project already uses Maven Site and SCM metadata. It is awkward if the goal is only to publish release notes.

## Output Quality

The output is useful for internal traceability:

```text
2026-05-31  alice
  src/main/java/example/ReleaseService.java
  Fix release-note report date range

2026-05-30  bob
  pom.xml
  Update Maven reporting plugin configuration
```

That is not the same as a reader-friendly changelog. It shows what changed in SCM, but it does not group by user impact or rewrite entries for release consumers.

## Ecosystem Fit

The plugin is Maven-native and historically fits Maven Site generation. For Java projects that still publish Maven-generated project sites, it can be a useful audit report.

For modern release notes, it is usually the wrong tool. GitHub Releases, GitLab Releases, release-please, `git-cliff`, or a Keep a Changelog workflow will produce better reader-facing output.

## Maintenance Status

- Latest version: **3.0.0-M1**
- Last release: **unknown**
- Maven Plugin docs list Maven 3.6.3 and JDK 8 as minimum requirements for the current milestone.
- Repository/docs: <a href="https://maven.apache.org/plugins/maven-changelog-plugin/" target="_blank" rel="noopener noreferrer">https://maven.apache.org/plugins/maven-changelog-plugin/</a>

The plugin remains documented by Apache Maven, but its model is mature and site-report oriented rather than an actively evolving release-note workflow.

## Verdict

**Verdict: Situational**

Use Apache Maven Changelog Plugin only when you specifically want Maven Site SCM reports. Avoid treating it as a product changelog or release-note solution; it is better as supporting evidence for developers than as communication for users.
