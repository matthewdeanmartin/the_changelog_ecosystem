Title: Changelog Validation Boundaries
Date: 2026-06-02
Slug: changelog-validation-boundaries
Ecosystem: Cross
Tags: validation, changelog-schema, ci-cd, keep-a-changelog
Tool_Status: research
Summary: Where structural validation ends and editorial judgment begins — a guide to which changelog checks belong in tooling, which belong in CI policy, and which should be left to human review.

## Overview

Changelog validation is not one thing. There are at least three distinct layers: structural checks (is the file parseable?), release-automation checks (is the pipeline ready to run?), and editorial checks (are the entries useful to readers?). Conflating them leads to CI gates that are either too strict (rejecting valid changes) or too lenient (letting broken releases through).

This article maps each category, identifies which tools enforce which checks, and recommends where each type of check belongs.

## The Three Layers

### Layer 1: Structural Validation

Structural validation asks: *can a machine parse this file reliably?* It operates on the file format, not the content.

For Keep a Changelog Markdown files, structural rules include:

- The file exists.
- Version headings use the required pattern: `## [version] - YYYY-MM-DD` or `## [Unreleased]`.
- Section headings within a release use `###` and are drawn from the permitted set (Added, Changed, Deprecated, Removed, Fixed, Security).
- There is exactly one `[Unreleased]` section, and it is first.
- The comparison-link reference block at the bottom is consistent with the headings above it.
- Version numbers appear in descending order (newest first).
- There are no duplicate version headings.

For fragment-based tools, structural rules apply to the fragment files instead:

- Towncrier: fragment filenames match `{identifier}.{type}` and the type is a configured category.
- Changie: fragment YAML has required keys (`kind`, `body`, `time`) and `kind` is one of the configured kinds.
- Reno: fragment YAML parses without errors and uses valid section keys.

**What fails here is unambiguously a bug.** A malformed version heading, a duplicate release, or an invalid fragment filename indicates a tooling or workflow error, not an editorial choice. These checks should fail CI hard.

### Layer 2: Release Automation Checks

Release automation checks ask: *is the pipeline ready to cut a release?* They sit between structural validity and the actual release command.

Common checks in this layer:

| Check | Tool | Triggered when |
|---|---|---|
| At least one fragment exists for this PR | `towncrier check --compare-with <ref>` | Every PR |
| Unreleased section is non-empty | `keepachangelog show Unreleased` | Pre-release |
| No fragment left unbuilt | `changie latest` exits cleanly | Pre-release |
| No YAML errors in note files | `reno lint` | Every PR or pre-release |
| Commit messages parse as Conventional Commits | `commitlint` | Every push / PR |
| Version in manifest matches tag | Custom script or release-please pre-check | Pre-tag |
| No pre-existing release tag for the proposed version | Custom script | Pre-tag |

**These checks belong in CI, but with escape hatches.** A PR that touches only tests or CI scripts should not be forced to include a changelog fragment. Tools address this in different ways:

- `towncrier check` skips the gate when the PR only modifies the configured changelog output file itself.
- Changie and Reno rely on project convention — teams typically add a label like `no-changelog` or a path-based exemption in GitHub Actions to skip the check.
- commitlint conventionally treats `chore:`, `docs:`, `ci:`, `style:`, and `test:` commits as non-releasing, so downstream tools like semantic-release will not produce a changelog entry for them.

### Layer 3: Editorial Judgment

Editorial checks ask: *are the entries useful to the reader?* These are the hardest to automate and the most valuable when they fire.

Examples:

- An entry that says "fixed a bug" without identifying the bug.
- A `### Added` entry that actually describes a breaking removal.
- An `## [Unreleased]` section with fifty entries and no version bump planned.
- A `### Security` entry that references a CVE but omits the affected versions.
- A comparison link that covers six months of changes with no intermediate releases.

**None of these should fail CI.** They are matters of documentation quality and release strategy, not format compliance. Automating them produces false positives (blocking valid entries), false negatives (passing bad ones that meet the pattern), and maintainer frustration.

Editorial quality is the job of code review. The right place for these checks is a PR template reminder ("does the changelog entry describe user impact?"), not a hard CI gate.

## Tool-by-Tool Enforcement Map

| Tool | Structural | Automation | Editorial |
|---|---|---|---|
| `python-kacl verify` | Yes — full KAC format | Limited | No |
| `brightcove/kacl lint` | Yes | No | No |
| `towncrier check` | Fragment filename validation | Fragment-exists gate | No |
| `reno lint` | YAML parse + section keys | Note attribution | No |
| `changie batch` | YAML key validation | Fragment-exists check | No |
| `commitlint` | Commit message syntax | CC type/scope/breaking | No |
| `keepachangelog show` | KAC heading parse | Non-empty Unreleased | No |
| Custom CI scripts | As written | As written | Occasionally (regex) |

No mainstream changelog tool provides editorial validation. Tools that try (e.g. checking minimum word count on entries) produce too many false positives to be useful in practice.

## Which Checks Belong Where

### In the tool itself (not configurable)

- Malformed YAML in fragment files → parse error, abort.
- Unknown fragment type → error with allowed types listed.
- Invalid date format in version heading → error.
- Duplicate version heading → error.
- Missing required fields in fragment (e.g. Changie `kind`) → error.

### In CI, enforced on every PR

- Fragment exists for the PR (Towncrier `check`, Reno `lint`).
- Commit message matches Conventional Commits format (commitlint).
- Changelog file is structurally valid if touched (python-kacl verify, kacl lint).

### In CI, enforced only pre-release

- Unreleased section is non-empty before cutting a release.
- Proposed version does not already exist as a tag.
- Version in manifest/config files matches the proposed tag.
- All fragment files have been built into the release (no orphaned unreleased fragments).

### Left to code review (not automated)

- Entry prose quality and user-facing clarity.
- Correct section assignment (is this really a "Fixed" or actually a "Changed"?).
- Whether a change is significant enough to warrant its own entry.
- Whether a `### Security` entry has enough detail for users to assess impact.
- Release cadence decisions (how many entries before cutting a release).

## The Exemption Problem

The hardest practical question is not "what to check" but "when to exempt a PR from the changelog gate."

For fragment-based tools, the pattern is straightforward: the check looks at whether the PR touches files outside the configured changelog or fragment directory. If a PR only touches tests or docs, the gate is skipped or overridden via a label.

For accumulated-changelog tools (KAC style), it is harder. `keepachangelog show Unreleased` does not know whether the current PR is the one responsible for the empty Unreleased section; it only knows whether the section has content at the time it runs. Pre-release automation checks (non-empty Unreleased) should run at release time, not on every PR.

A common misconfiguration is running pre-release checks on every PR. This forces contributors to add placeholder entries to `[Unreleased]` and then remove them before release, creating churn with no value.

## Summary

The practical rule of thumb:

1. **Format errors** — fail immediately, in the tool or in CI on every PR.
2. **Fragment-exists gates** — run on every PR, with explicit exemptions for non-user-visible changes.
3. **Release readiness checks** — run only at release time, not on every PR.
4. **Prose quality** — code review only; do not automate.

Changelog tools are responsible for layers 1 and 2. Layer 3 is the responsibility of the team.

## Related Articles

- [Changelog File Schemas]({filename}changelog-file-schemas.md)
- [Change Taxonomies Across Tools]({filename}change-taxonomies-across-tools.md)
- [towncrier]({filename}towncrier.md)
- [reno]({filename}reno.md)
- [changie]({filename}changie.md)
- [keepachangelog]({filename}keepachangelog.md)
- [Version Validation in Release Pipelines]({filename}version-validation-release-pipelines.md)
