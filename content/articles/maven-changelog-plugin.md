Title: maven-changelog-plugin
Date: 2026-06-02
Slug: maven-changelog-plugin
Ecosystem: Java
Tags: java, maven-plugin, maven-site, scm-report, developer-activity, file-activity, legacy, hands-on
Tool_URL: https://maven.apache.org/plugins/maven-changelog-plugin/
Tool_Version: 2.3
Tool_Status: mature
Experiment: examples/java/maven-changelog-plugin/
Summary: Apache Maven SCM site-report plugin (changelog/dev-activity/file-activity HTML), not a CHANGELOG.md generator; hands-on testing found it broken against modern Git because the bundled maven-scm provider calls the removed `git whatchanged`.



## Overview

Apache Maven Changelog Plugin is a Maven reporting plugin for SCM activity reports. It generates Maven Site pages that show recent commits, developer activity, and file activity.

This is not a modern user-facing release-note generator. It belongs in the survey because older Maven projects may still associate "changelog" with Maven Site reports, but its output is closer to developer audit reporting than a polished release announcement.

A reproducible hands-on experiment for this tool lives in [`examples/java/maven-changelog-plugin/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/java/maven-changelog-plugin).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), this plugin did not work at all against a modern Git. Every report goal and <code>mvn site</code> failed because the bundled <code>maven-scm</code> <code>gitexe</code> provider invokes <code>git whatchanged</code>, which current Git versions block (<code>fatal: refusing to run without --i-still-use-this</code>). The plugin has no way to pass that flag and no configuration can fix it. It appears unmaintained for modern toolchains — it is not unusable, but you would likely need to pin an old Git binary, find a maintained fork, or patch the maven-scm provider yourself. See the hands-on findings below.
</div>

## Installation

Add to the `reporting` section of `pom.xml`:

```xml
<reporting>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-changelog-plugin</artifactId>
      <version>2.3</version>
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
      <version>2.3</version>
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

## What the plugin is designed to produce

When it does work (older Git, older Maven environments), the plugin generates HTML inside a Maven site:

- **`target/site/changelog.html`** — a time-range report of commits, listing author, date, message, and files changed. Configurable by date range, tag-to-tag, or commit count.
- **`target/site/dev-activity.html`** — per-author summary of commit count and files touched.
- **`target/site/file-activity.html`** — per-file summary of revision count.

These are HTML files rendered inside a Maven site, not standalone documents. There is no `CHANGELOG.md`, no text output, and no structured data format — the output is HTML designed for human viewing in a browser, not for parsing or further processing. The plugin reads raw SCM history and presents it verbatim; it does not reformat commit messages, group by type, or annotate by user impact. The result is closer to an audit trail than a product changelog.

## Ecosystem Fit

The plugin is Maven-native and historically fits Maven Site generation. For Java projects that still publish Maven-generated project sites, it can be a useful audit report.

For modern release notes, it is usually the wrong tool. GitHub Releases, GitLab Releases, release-please, `git-cliff`, or a Keep a Changelog workflow will produce better reader-facing output.

| Dimension | maven-changelog-plugin | Typical changelog tools |
|---|---|---|
| Output format | HTML inside Maven site | Markdown or text file |
| Audience | Developers browsing project site | Users reading release notes |
| Lifecycle integration | `mvn site` phase | Standalone CLI or CI step |
| Content grouping | By date range or SCM tag | By semantic version or release |
| Requires Maven | Yes | No |

## Maintenance Status

- Tested version: **2.3** (released ~2013)
- Milestone **3.0.0-M1** exists but has no GA follow-up.
- Docs/site: <a href="https://maven.apache.org/plugins/maven-changelog-plugin/" target="_blank" rel="noopener noreferrer">https://maven.apache.org/plugins/maven-changelog-plugin/</a>

The plugin remains documented by Apache Maven, but its model is mature and site-report oriented rather than an actively evolving release-note workflow.

---

## Hands-on findings

I built a Docker container from `maven:3.9-eclipse-temurin-21-alpine` (Maven 3.9.16, JDK 21, modern Alpine Git) with a fresh git repository containing a small Java project (`tipcalc`), then attempted across five stages: `changelog:changelog` after each of three commits/tags, `changelog:dev-activity`, and finally `mvn site` as a fallback. The `pom.xml` used `scm:git:file:///work/app` as the SCM connection.

### Real output: every invocation failed

```
[INFO] Executing: /bin/sh -c cd /work/app \
  && git whatchanged '--since=2026-05-03 12:40:42 +0000' \
               '--until=2026-06-03 12:40:42 +0000' \
  --date=iso -- /work/app
[ERROR] Provider message:
[ERROR] The git-log command failed.
[ERROR] Command output:
[ERROR] 'git whatchanged' is nominated for removal.
...
fatal: refusing to run without --i-still-use-this
```

No HTML was produced. `target/site/` was never created. The build terminated with `BUILD FAILURE` each time, including the `mvn site` fallback (which invokes the same plugin).

**Root cause:** `maven-changelog-plugin 2.3` depends on `maven-scm 1.8` (~2012), whose `gitexe` provider enumerates commits by calling `git whatchanged`. Modern Git has deprecated and then hard-blocked that subcommand unless the caller passes `--i-still-use-this`. The plugin constructs the git subprocess internally and exposes no parameter to pass that flag, so **no `pom.xml` change can fix it.** The SCM URL parsing succeeded — the failure is purely in the launched git subprocess. Even a failed run downloads dozens of maven-scm provider JARs (Bazaar, Perforce, StarTeam, Synergy, VSS) most projects never use.

### Docs vs. reality

The documentation describes configuring the `<scm>` element and `<reporting>` block, then running `mvn site`. In theory this is straightforward. In practice, the docs predate the Git deprecation story entirely and make no reference to compatibility with recent Git versions. A reader following them in 2025–2026 hits a hard failure with no obvious path forward.

## Verdict

**Verdict: Appears unmaintained for modern toolchains; does not currently work as tested.**

maven-changelog-plugin is not a changelog generator in the modern sense — it produces HTML site reports, not `CHANGELOG.md` files or release notes. Even setting that aside, it is functionally broken with any Git installation from roughly 2024 onward because of the `git whatchanged` dependency.

It is not unusable in principle. If you genuinely need SCM activity reports in a Maven site, the realistic paths are: pin to an old Git binary, find a maintained fork or updated maven-scm, build a patched `gitexe` provider, or replace the reports with `git log --stat` output in CI. For the broader problem of generating user-facing changelogs from git history, reach for a tool designed for that — `git-cliff`, `conventional-changelog`, `release-please`, or `git-changelog-maven-plugin` if you want to stay inside Maven.
