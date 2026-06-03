Title: git-changelog-maven-plugin (hands-on synthesis)
Date: 2026-06-02
Slug: git-changelog-maven-plugin-v2
Ecosystem: java
Tags: maven-plugin, java, conventional-commits, templates, git-history, hands-on
Tool_URL: https://github.com/tomasbjerre/git-changelog-maven-plugin
Tool_Version: 2.2.11
Tool_Status: active
Experiment: examples/java/git-changelog-maven-plugin/
Summary: Hands-on re-review after driving git-changelog-maven-plugin through the tip-calculator life cycle.



## What I Actually Ran

The experiment builds a minimal Maven project (`tipcalc`) inside Docker
(`maven:3.9-eclipse-temurin-21-alpine`), creates a real git repository, and walks the plugin
through three tagged releases using conventional commit messages:

- `v1.0.0` — `feat: compute tip for a single bill`
- `v2.0.0` — `feat: split the bill evenly among diners`
- `v3.0.0` — `feat!: split the bill unevenly by weight`

The plugin was bound to the `generate-resources` phase via a single execution block in
`pom.xml`. The changelog was regenerated with `mvn --batch-mode generate-resources` after each
tag. The full experiment source lives at
`examples/java/git-changelog-maven-plugin/`.

The template used:

```xml
<templateContent><![CDATA[
# Changelog

{{#tags}}
## {{name}}
{{#commits}}
- {{messageTitle}}
{{/commits}}

{{/tags}}
]]></templateContent>
```

## Real Output

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

The tag grouping works exactly as expected. Each tagged version gets its own heading, commits
are listed in reverse-chronological tag order, and the commit message title is reproduced
verbatim. The breaking-change marker `feat!:` is passed through unchanged — the plugin does not
interpret Conventional Commits prefixes on its own.

The warm-cache second and third runs each completed in about one second. The first cold run took
roughly 60 seconds to resolve the dependency graph.

## Discovered Issue: Wrong Parameter Name in Documentation

Official documentation and plugin examples show `<toFile>` as the output file parameter.
In version 2.2.11 the actual parameter name is `<file>`. Maven emits a warning but does not
fail:

```
[WARNING] Parameter 'toFile' is unknown for plugin
  'git-changelog-maven-plugin:2.2.11:git-changelog (generate-changelog)'
```

The plugin falls back to writing `CHANGELOG.md` by default, so the misconfiguration does not
break the build — it is silent. Anyone copying the documented example verbatim is running with
an ignored directive and may not notice.

## Pros

- Minimal setup. One plugin block, one template string, bind to a Maven phase. No extra tools
  required.
- Tag grouping comes for free via JGit. The plugin discovers all annotated and lightweight tags
  without any configuration.
- Handlebars templating is expressive. The `{{#tags}}`, `{{#commits}}`, and `{{messageTitle}}`
  variables work as documented and produce readable output.
- Runs entirely within the Maven lifecycle. No separate CLI install, no CI plugin needed.
- Warm runs are fast (~1s). The dependency graph is downloaded once and cached.

## Cons

- `<toFile>` vs `<file>` documentation error. The plugin silently ignores the unknown
  parameter and falls back to a default. This is the kind of mismatch that leads to hours of
  debugging when the output file ends up in an unexpected location.
- No built-in Conventional Commits grouping. The plugin does not parse `feat:`, `fix:`,
  `feat!:`, or `BREAKING CHANGE` tokens natively. Getting a grouped changelog requires writing
  the grouping logic by hand in the Handlebars template, using the plugin's issue-pattern
  matching as a workaround.
- The `{{#issues}}` block documented in the README silently produces no output unless issue
  patterns are configured. A newcomer following the docs will get a working but empty issues
  section and may spend time debugging the template rather than realising a prerequisite is
  missing.
- Heavy transitive dependency graph. The plugin brings in JGit, Handlebars, Jackson, OkHttp,
  Retrofit, Nashorn, and Kotlin stdlib — a lot for a changelog generator. This is a cold-start
  cost and a supply-chain consideration.
- Maven-only. No path to Gradle or non-JVM projects.

## Docs vs. Reality

The plugin works as described for the core workflow: bind a template, run a Maven phase, get a
changelog grouped by tag. The mechanics are sound.

Two documentation gaps caused friction:

1. The `<toFile>` parameter name is wrong in 2.2.11. The parameter is `<file>`. Maven warns but
   does not error, making it easy to miss.

2. Template examples using `{{#issues}}` require `<jiraIssuePattern>` or similar to be set.
   Without it the block iterates zero items. The README does not make this dependency obvious.

The gap between what is documented and what runs is narrow but it sits exactly where new users
will land first.

## Revised Verdict

**Verdict: Recommended with caveats**

The plugin delivers reliable changelog generation inside the Maven lifecycle with minimal
ceremony. Tag grouping works, templates are flexible, and warm runs are fast. For a Maven-native
team that wants `mvn verify` or a release profile to also write a CHANGELOG, this is a practical
option with no close competitors inside the Maven ecosystem.

The caveats are real: fix the `<toFile>` parameter name before copying from the README, do not
expect Conventional Commits grouping without template work, and budget time to understand why
the `{{#issues}}` block renders nothing on a fresh install. None of these are hard problems once
identified, but the documentation leaves the discovery work to the user.

Teams that want zero-config Conventional Commits output — type prefixes automatically mapped to
sections, breaking changes called out, footers parsed — should look at `git-cliff` or
`semantic-release` instead. This plugin is a Handlebars renderer over JGit, not a
Conventional Commits processor.
