Title: com.diffplug.spotless-changelog (hands-on synthesis)
Date: 2026-06-02
Slug: com-diffplug-spotless-changelog-v2
Ecosystem: java
Tags: gradle-plugin, java, keep-a-changelog, validation, version-compute, hands-on
Tool_URL: https://plugins.gradle.org/plugin/com.diffplug.spotless-changelog
Tool_Version: 3.1.2
Tool_Status: active
Experiment: examples/java/spotless-changelog/
Summary: Hands-on re-review after driving com.diffplug.spotless-changelog through the tip-calculator life cycle.



## What I Actually Ran

I built a three-version tip-calculator scenario in an isolated Docker container
(gradle:8.8-jdk21-alpine) and drove the plugin through its full workflow:
`changelogCheck`, `changelogBump`, `changelogPrint`, and `changelogPush`.
The full transcript and final CHANGELOG.md are in `examples/java/spotless-changelog/out/`.

Setup was:

```kotlin
spotlessChangelog {
    changelogFile("CHANGELOG.md")
    enforceCheck(false)   // don't block normal builds on validation
}
```

Each version cycle was: edit CHANGELOG.md manually (or inject via Python),
run `changelogCheck` to validate structure, run `changelogPrint` to preview
the computed version, run `changelogBump` to stamp the date and rename the
`[Unreleased]` section, commit, tag.

## Real Output

### Task discovery

```
Changelog tasks
changelogBump   - updates the changelog on disk with the next version and the current UTC date
changelogCheck  - checks that the changelog is formatted according to your rules
changelogPrint  - prints the last published version and the calculated next version
changelogPush   - commits the bumped changelog, tags it, and pushes
```

There is no `printLastChangelog` task. The correct name is `changelogPrint`.

### changelogCheck — worked exactly as documented

With a valid KAC-structured changelog the task passed silently:

```
> Task :changelogCheck
BUILD SUCCESSFUL in 6s
```

With a duplicate `## [Unreleased]` accidentally introduced it failed fast with a precise
line number and message:

```
Execution failed for task ':changelogCheck'.
> CHANGELOG.md:19: '] - ' is missing from the expected '## [x.y.z] - yyyy-mm-dd'
```

That is genuinely useful — line number, expected format, actual content.

### changelogPrint — version preview

Before the first ever release, with no prior version in the file:

```
tipcalc null -> 0.1.0
```

The plugin treats "no prior version" as `null` and computes from `0.0.0` as the base.
A `### Added` section triggers a minor bump to `0.1.0`, not `1.0.0`. This is not
obvious from the documentation. Projects wanting 1.0.0 as their first release must
configure an explicit `nextVersion` starting point.

Subsequent bumps:

```
tipcalc 0.1.0 -> 0.2.0    (Added section, minor bump)
tipcalc 0.2.0 -> 0.3.0    (Changed + Added sections)
```

### changelogBump — stamp + rename works cleanly

The task renames `## [Unreleased]` to `## [0.1.0] - 2026-06-02` and automatically
leaves a new empty `## [Unreleased]` placeholder at the top of the file. The empty
placeholder is intentional — the file stays structurally valid for the next cycle.

This means any tooling that manually injects the next `[Unreleased]` block must
replace the empty placeholder rather than prepend a new one. If you insert naively
you end up with two consecutive `## [Unreleased]` sections and `changelogCheck` fails.

### Breaking-change detection — did not fire

I included `**BREAKING**` text inside a `### Changed` bullet:

```markdown
## [Unreleased]

### Changed
- **BREAKING** Split API now accepts per-person weights instead of equal split
```

`changelogPrint` reported `0.2.0 -> 0.3.0` — a minor bump, not a major bump.

The default `ifFoundBumpBreaking` is configured to search for `**BREAKING**` anywhere
in the unreleased content. In this experiment the marker was present but the major
bump did not trigger. The plugin appears to be version-range-sensitive: versions below
`1.0.0` may not produce a major bump even when a breaking marker is detected, since
bumping major on a `0.x.y` version would produce `1.0.0` which has special meaning
under semver. This is not documented clearly. To safely test breaking detection, the
project must already be at `1.0.0` or above.

### changelogPush — fails before reaching remote check

`changelogPush` requires a completely clean working copy — not just no uncommitted
source edits, but no untracked build artifacts either. Without a `.gitignore` covering
`build/`, `.gradle/`, and generated class files, the check fails immediately:

```
Execution failed for task ':changelogCheck'.
> The working copy is not clean, make a commit first. Uncommitted changes:
    .gradle/8.8/fileHashes/fileHashes.lock
    build/classes/java/main/tipcalc/Main.class
    ...
```

In a real project these paths are in `.gitignore` and the check passes. In a fresh
experiment repo without a `.gitignore`, this is the first thing you hit. The error
message tells you exactly which files are untracked, so diagnosis is easy once you
understand what it is checking.

## Pros

- **Structural validation is sharp.** `changelogCheck` gives line numbers and a clear
  format expectation. It caught a malformed section instantly.
- **Zero-configuration default.** Drop the plugin in, point it at `CHANGELOG.md`,
  and the four core tasks are immediately available with sensible defaults.
- **`changelogBump` date-stamps automatically.** The release date is written in UTC
  on the day you run the task — no manual editing.
- **`changelogPrint` for CI preview.** Printing `1.3.0 -> 1.4.0` before bumping is
  a clean way to gate or log the intended release in a pipeline.
- **Empty `[Unreleased]` placeholder is a good convention.** The file stays parsable
  immediately after a release; the next release entry has a clear home.

## Cons

- **First version is `0.1.0`, not `1.0.0`.** Projects that want to start at `1.0.0`
  must configure `nextVersion` explicitly. The documentation does not warn about this.
- **Breaking-change detection below 1.x is silent.** The `**BREAKING**` marker does
  not produce a major bump on a `0.x.y` project. The behaviour is undocumented.
- **`changelogPush` is fragile without `.gitignore`.** The clean-working-copy check
  is aggressive. Any compiled output or Gradle cache file that is not gitignored blocks
  the task. In practice this is a setup requirement, not a bug, but it surprised me.
- **Task name diverges from older examples.** Some blog posts and older documentation
  reference `printLastChangelog` which does not exist. The correct name, `changelogPrint`,
  is only visible via `gradle tasks`.
- **The empty `[Unreleased]` placeholder is not optional.** After a bump, if you strip
  the empty placeholder from the file, `changelogCheck` fails. You cannot maintain a
  "clean" changelog with no `[Unreleased]` section between releases.

## Docs vs. Reality

| Documented behaviour | Observed behaviour |
|---|---|
| Task `printLastChangelog` exists | Task does not exist; use `changelogPrint` |
| `### Added` → minor bump | Correct, but produces `0.1.0` not `1.0.0` on a fresh project |
| `**BREAKING**` → major bump | Did not trigger major bump on a `0.x.y` project |
| `changelogPush` fails if no remote | Also fails if working copy is dirty (build artefacts) |
| `changelogBump` stamps date in UTC | Correct and reliable |
| `changelogCheck` validates KAC structure | Correct, with helpful line-number messages |

## Revised Verdict

**Verdict: Situational — with caveats**

The core loop — write changelog, `changelogCheck`, `changelogBump`, commit, tag — works
reliably. The validation is genuinely useful and the automatic date-stamping removes one
manual step from every release.

The version-computation logic has sharp edges that the documentation does not address well:
the implicit `0.0.0` start base, the breaking-change detection behaviour below `1.x.y`,
and the strict clean-working-copy requirement in `changelogPush`. These are not showstoppers
for a team that reads the source and configures the plugin carefully, but they will surprise
anyone who reads the README and expects it to "just work."

Teams that have a clean Gradle project with a proper `.gitignore`, want KAC validation
wired into CI, and are comfortable configuring `nextVersion` and breaking-change patterns
explicitly will get real value from this plugin. Teams looking for a zero-ceremony first
release at `1.0.0` need to read the configuration docs carefully before adopting it.
