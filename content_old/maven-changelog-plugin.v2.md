Title: maven-changelog-plugin (hands-on synthesis)
Date: 2026-06-02
Slug: maven-changelog-plugin-v2
Ecosystem: java
Tags: maven-plugin, java, scm-report, maven-site, hands-on
Tool_URL: https://maven.apache.org/plugins/maven-changelog-plugin/
Tool_Version: 2.3
Tool_Status: mature
Experiment: examples/java/maven-changelog-plugin/
Summary: Hands-on re-review of maven-changelog-plugin — an SCM-based site report generator, not a changelog file generator.



## What I actually ran

I built a Docker container from `maven:3.9-eclipse-temurin-21-alpine` with git installed,
initialized a fresh git repository containing a small Java project (tipcalc), and ran:

1. `mvn --batch-mode changelog:changelog` after the first commit
2. `mvn --batch-mode changelog:changelog` after a second commit
3. `mvn --batch-mode changelog:dev-activity` after a third commit
4. `mvn --batch-mode site` as a fallback, which invokes all reporting plugins including
   maven-changelog-plugin

The pom.xml used `scm:git:file:///work/app` as the SCM connection URL — the documented
approach for a local git repository with no remote.

The full run script is at `examples/java/maven-changelog-plugin/run_experiment.sh`.

## Real output

Every invocation failed with an identical error:

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

No HTML was produced. No `target/site/` directory was ever created. The Maven build
terminated with `BUILD FAILURE` each time.

The root cause is that `maven-changelog-plugin 2.3` depends on `maven-scm 1.8`
(released ~2012), whose `gitexe` provider invokes `git whatchanged` to enumerate
commits. Modern Git has deprecated this subcommand and eventually blocked it,
requiring `--i-still-use-this` to bypass the guard. The plugin has no configuration
parameter to pass that flag — it constructs the git subprocess internally. No pom.xml
change can fix it.

There is a known upstream bug: the plugin would need to be updated to use `git log --raw`
instead of `git whatchanged`. There is no patched release of `2.3`. The milestone
`3.0.0-M1` exists but was not tested here; if it ships a newer maven-scm it might
work, though `3.0.0-M1` itself is years old.

## What the plugin is designed to produce

When it does work (older Git, older Maven environments), maven-changelog-plugin generates:

- **`target/site/changelog.html`** — a time-range report of commits, listing author,
  date, message, and files changed. Configurable by date range, tag-to-tag, or commit
  count.
- **`target/site/dev-activity.html`** — per-author summary of commit count and files
  touched.
- **`target/site/file-activity.html`** — per-file summary of revision count.

These are HTML files rendered inside a Maven site, not standalone documents. They are
intended to be part of a `mvn site` publication, typically uploaded to a project hosting
site alongside Javadoc and other generated reports.

There is no CHANGELOG.md, no text output, no structured data format. The output format
is HTML, designed for human viewing in a browser, not for parsing or further processing.

## Fundamental distinction: site report vs. changelog file

This plugin belongs to a category that the rest of the changelog ecosystem does not:
it is a **Maven site reporting plugin**, not a **changelog file generator**.

The difference matters:

| Dimension | maven-changelog-plugin | Typical changelog tools |
|---|---|---|
| Output format | HTML inside Maven site | Markdown or text file |
| Audience | Developers browsing project site | Users reading release notes |
| Lifecycle integration | `mvn site` phase | Standalone CLI or CI step |
| Content grouping | By date range or SCM tag | By semantic version or release |
| Requires Maven | Yes | No |

The plugin reads raw SCM history and presents it verbatim. It does not reformat commit
messages, group by type (feat/fix/chore), or annotate by user impact. The output is
closer to an audit trail than a product changelog.

## Pros

- Zero additional configuration for projects already using Maven site and SCM metadata.
- Supports multiple SCM backends through maven-scm (SVN, Perforce, Bazaar, git).
- Three complementary report types give different views of the same history.
- Integrates naturally with `mvn site` — one command generates all project reports.
- Local `file://` SCM URLs work for projects without a central SCM server.

## Cons

- **Broken with modern Git**: the `git whatchanged` dependency is a hard blocker.
  Any Alpine, Ubuntu, or Debian container with a current Git package will fail.
- Not a user-facing changelog. HTML in a Maven site is not the same as release notes.
- Output is not portable: the generated HTML only makes sense in the context of a
  Maven site with the correct skin and navigation.
- Plugin version `2.3` released in 2013. `3.0.0-M1` is a milestone with no GA follow-up.
- Heavy startup: even a failed run downloads dozens of Maven-SCM provider JARs for
  SCM systems (Bazaar, Perforce, StarTeam, Synergy, VSS) that most projects never use.
- No CHANGELOG.md output. If the goal is a file that can be committed and shipped
  alongside releases, this plugin cannot produce it.

## Docs vs. reality

The official documentation describes configuring the `<scm>` element and the
`<reporting>` block, then running `mvn site`. In theory this is straightforward.
In practice, the docs do not mention the `git whatchanged` dependency, and they
make no reference to compatibility with recent Git versions.

The documentation predates the Git deprecation story entirely. A reader following
the docs in 2025 or 2026 will encounter a hard failure with no obvious path forward.

## Revised verdict

**Verdict: Do not use (compatibility broken)**

maven-changelog-plugin is not a changelog generator in the modern sense. It produces
HTML site reports, not CHANGELOG.md files or release notes. Even setting that aside,
it is functionally broken with any Git installation from approximately 2024 onward,
because the underlying maven-scm `gitexe` provider calls `git whatchanged`, which
modern Git blocks.

For Maven projects that genuinely want SCM activity reports in their Maven site,
the options are: pin to an old Git binary, find a maintained fork or update,
or replace the reports with `git log --stat` output in CI. For the broader problem
of generating user-facing changelogs from git history, use a tool designed for that
purpose — `git-cliff`, `conventional-changelog`, `release-please`, or any of the
other tools in this survey that read git history and produce structured Markdown.
