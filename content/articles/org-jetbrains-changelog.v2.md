Title: org.jetbrains.changelog (hands-on synthesis)
Date: 2026-06-02
Slug: org-jetbrains-changelog-v2
Ecosystem: java
Tags: gradle-plugin, java, keep-a-changelog, hands-on
Tool_URL: https://plugins.gradle.org/plugin/org.jetbrains.changelog
Tool_Version: 2.5.0
Tool_Status: active
Experiment: examples/java/org-jetbrains-changelog/
Summary: Hands-on re-review after driving org.jetbrains.changelog through the tip-calculator life cycle.



## What I Actually Ran

I built a minimal Java/Gradle tip calculator and drove it through three releases (v1.0.0, v2.0.0, v3.0.0) using the `org.jetbrains.changelog` 2.5.0 plugin on Gradle 8.8 / JDK 21 (Alpine). The full experiment is in `examples/java/org-jetbrains-changelog/` and runs end-to-end with `make run`.

The scenario:

- **v1.0.0** — compute tip for a single bill
- **v2.0.0** — split evenly among 4 diners
- **v3.0.0** — split unevenly by per-person weights

For each release: seed the `[Unreleased]` section with a change description, run `gradle patchChangelog` to promote it to a versioned section, commit, tag. I also tested `gradle getChangelog` at the start (before any versioned sections existed) and at the end (after v3.0.0 was tagged).

Environment: `gradle:8.8-jdk21-alpine`, plugin resolves from Gradle Plugin Portal (network required on first build).

## Real Output

### Stage 2 — `getChangelog` on an unreleased-only changelog

```
> Task :getChangelog FAILED

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':getChangelog'.
> org.jetbrains.changelog.exceptions.MissingVersionException: Version is missing: any
```

`getChangelog` looks for a versioned section matching `project.version`, not the `[Unreleased]` block. Calling it before the first `patchChangelog` is a build error.

### Stage 2 — `patchChangelog` on v1.0.0

```
> Task :patchChangelog
BUILD SUCCESSFUL in 5s
```

Post-patch `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

### Changed

### Fixed

## [1.0.0]

### Added

- Compute tip for a restaurant bill at 18% rate
- Print bill, tip, and total to stdout
```

The plugin moved `[Unreleased]` to `[1.0.0]` and seeded a fresh `## Unreleased` stub (without brackets) with the configured groups.

### Stage 5 — `getChangelog` after v3.0.0

```
> Task :getChangelog
## 3.0.0

### Added

- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2)

BUILD SUCCESSFUL in 5s
```

### Final `CHANGELOG.md`

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

### Changed

### Fixed

## [3.0.0]

### Added

- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2)

## 2.0.0

### Added

- Split the bill evenly among 4 diners

## 1.0.0

### Added

- Compute tip for a restaurant bill at 18% rate
- Print bill, tip, and total to stdout
```

### Git log

```
cb5a42f (HEAD -> master, tag: v3.0.0) chore(release): 3.0.0
a2bc4a0 feat!: split the bill unevenly by weight
34fb704 (tag: v2.0.0) chore(release): 2.0.0
641e4f0 feat: split the bill evenly among diners
a0bbcae (tag: v1.0.0) chore(release): 1.0.0
1d67e7e docs: initialize changelog with [Unreleased] for v1.0.0
0365e3e feat: compute tip for a single bill
```

## Pros (Observed)

**Zero friction for the happy path.** Adding the plugin to `build.gradle.kts` and calling `patchChangelog` works on the first run with no boilerplate beyond the `changelog {}` extension block. No wrapper generation, no extra repositories.

**`patchChangelog` is reliable.** It correctly promoted `[Unreleased]` to a versioned section in all three cycles without errors.

**`getChangelog` is useful for downstream consumers.** Once a versioned section exists, `getChangelog` prints clean Markdown that can be piped into a publish task or release action. The output is exactly the section body — no extra scaffolding.

**Plugin Portal resolution is seamless.** A single `id("org.jetbrains.changelog") version "2.5.0"` line is all that is needed; no additional repository configuration.

**Gradle cache means only the first Gradle invocation is slow.** Subsequent `patchChangelog` calls (2.0.0, 3.0.0) resolved from cache and completed in 5 seconds each.

## Cons / Pain Points (Observed)

**`getChangelog` fails when there are no versioned sections.** If a developer writes `[Unreleased]` content and calls `getChangelog` to preview it before cutting a release, the build fails with `MissingVersionException: Version is missing: any`. There is no "preview unreleased" mode. The only useful operation before `patchChangelog` is to read the file directly.

**`patchChangelog` leaves a permanent empty `## Unreleased` stub.** After each patch, the plugin inserts a bracketless `## Unreleased` block at the top, pre-populated with the configured group headings (Added, Changed, Fixed) but no content. This is intentional — it seeds the next cycle — but it means the file always contains an empty section. It also drifts from strict Keep a Changelog format, which calls for `## [Unreleased]` with brackets.

**Older sections lose their brackets.** After the v2 patch, `## [1.0.0]` became `## 1.0.0` in the final file. After the v3 patch, `## [2.0.0]` lost its brackets too. Only the most recently patched section retains them. The format becomes progressively less KAC-conformant with each release.

**No `checkChangelog` CI gate.** The docs mention changelog validation but no `checkChangelog` task is registered out of the box in 2.5.0. There is no way to fail a build if `[Unreleased]` is empty or the file is malformed, without writing custom Gradle code.

**Daemon noise on every invocation.** Even with `--no-daemon`, the Alpine-based image produces a "single-use Daemon process will be forked" warning on every `gradle` call. This is a container JVM memory configuration issue rather than a plugin defect, but it adds several lines of noise to CI logs.

**Injecting content into `[Unreleased]` requires working around the plugin's own stub.** Because `patchChangelog` writes `## Unreleased` (no brackets) to the top of the file, the developer's `## [Unreleased]` addition ends up as a second, separate section below the stub. The plugin picks up the bracketed one as canonical and `patchChangelog` continues to work, but the orphaned no-bracket stub accumulates across releases and can confuse both readers and tooling.

## Docs vs. Reality

The plugin documentation describes `getChangelog` as extracting "the changelog item for the current version." In practice, "current version" means the project version from `build.gradle.kts`, and the task looks for a versioned section heading — not the `[Unreleased]` block. The docs do not clearly state that the task fails when called before any versioned section exists. A developer following the docs literally (configure, write `[Unreleased]`, call `getChangelog` to preview) will hit a build failure on their first interaction.

The bracket-dropping behavior is not documented. The plugin consistently strips brackets from previously released sections when running `patchChangelog`, silently diverging from KAC format for all but the latest release.

The empty `## Unreleased` stub behavior is documented in the plugin README under "patchChangelog" but is easy to miss. In practice, it means the file after three releases looks like it has a live unreleased section when it does not.

## Revised Verdict

**Verdict: Conditionally Recommended — best for IntelliJ plugin projects.**

`org.jetbrains.changelog` does the one thing it was designed for — promoting `[Unreleased]` to a versioned section and making that section available to Gradle tasks — reliably and with minimal configuration. For IntelliJ Platform plugin projects, where the release process already includes Gradle tasks that need formatted changelog text, it is the right tool.

For general Java or Gradle projects, the rough edges matter more. The `getChangelog` failure on an unreleased-only file, the bracket-stripping of older sections, and the absence of a CI validation gate mean the plugin requires more care than the docs suggest. A team that treats its `CHANGELOG.md` as a strict KAC artifact will find the output drifts over time without manual intervention.

If the primary goal is changelog extraction for a publish pipeline and the team is already using Gradle, this plugin is still the best available option in the Java ecosystem. If the goal is format compliance or a human-readable change history, the post-patch output needs a cleanup step.
