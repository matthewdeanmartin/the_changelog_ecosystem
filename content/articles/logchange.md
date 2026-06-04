Title: logchange
Date: 2026-05-31
Modified: 2026-06-03
Slug: logchange
Ecosystem: Cross
Tags: cli, cross, keep-a-changelog, news-fragments, release-notes, hands-on
Tool_URL: https://github.com/logchange/logchange
Tool_Version: 1.19.15
Tool_Status: active
Experiment: examples/cross/logchange/
Summary: Tool that stores each change in a separate YAML file to reduce changelog merge conflicts and generate CHANGELOG.md during release. Hands-on verified.



## Overview

`logchange` is a fragment-based changelog tool: every change is recorded in its own YAML file, then assembled into `CHANGELOG.md` during release. It is aimed at teams that dislike merge conflicts in one shared changelog file but still want curated release notes instead of commit-message scraping.

It sits closer to Towncrier, Scriv, and Changie than to semantic-release or Release Drafter.

> **Hands-on note.** This review is grounded in actually driving `logchange` through a full
> three-release changelog life cycle in a container — see
> [`examples/cross/logchange/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/cross/logchange).
> The output and behavior below are observed, not paraphrased from docs. Tool under test:
> the `logchange/logchange:1.19.15` Docker image (a GraalVM native image on Alpine, Java 21).
> The whole life cycle ran with **no network and no token** — `logchange` is genuinely local.

## Installation

The published artifact is a GraalVM-native binary. The two practical install paths:

```bash
# Homebrew (macOS / Linux)
brew install logchange/tap/logchange

# Docker — the image used for this review
docker run --rm -v "$PWD:/code" logchange/logchange:1.19.15 <command>
```

There are also Maven and Gradle plugins for JVM projects. Note that `logchange -V` reports
`Logchange version: null` — the native binary does not embed its own version, so pin and
track the **image tag**, not the CLI's self-report.

## What It Does

- Stores unreleased changes as individual YAML fragments in `changelog/unreleased/`.
- Groups fragments by change type when generating a release.
- Writes or updates `CHANGELOG.md` (`logchange generate`).
- "Releases" by moving fragments from `unreleased/` into a `vX.Y.Z/` directory.
- Lints fragments and config as a CI gate (`logchange lint`).
- Reduces conflicts when many contributors add release-note entries in parallel.

The core commands observed: `init`, `add`/`example`, `lint`, `generate`, and
`release --versionToRelease X --releaseDate Y`. `generate` is **non-destructive** (it just
re-renders the changelog, with pending entries under `[unreleased]`); `release` is the
step that actually moves files and stamps the version.

## Configuration

`logchange init` lays down `changelog/logchange-config.yml` and the `changelog/unreleased/`
directory. The config defines the entry types and the labels each renders to:

```yaml
changelog:
  labels:
    types:
      added: Added
      changed: Changed
      fixed: Fixed
      deprecated: Deprecated
      removed: Removed
      security: Security
      dependency_update: Dependency updates
```

A single change is one small YAML file — `title` and `type` are the only required fields,
with optional `authors`, `issues`, `merge_requests`, `links`, `important_notes`, and
`configurations`:

```yaml
title: "Split the bill unevenly using per-person weights"
type: changed
important_notes:
  - "Output shape changed: totals are now printed one line per diner."
```

First-run complexity is moderate, but lower than expected in practice: `init` generates a
complete default config, so a team mostly just decides which entry types it cares about.

## Output Quality

Fragment workflows produce more intentional prose than commit scraping. Here is the
**actual** `CHANGELOG.md` after walking three releases (header banner trimmed):

```markdown
[unreleased]
------------


[3.0.0] - 2026-03-01
--------------------

### Important notes

- Output shape changed: totals are now printed one line per diner.

### Changed (1 change)

- Split the bill unevenly using per-person weights


[2.0.0] - 2026-02-01
--------------------

### Added (1 change)

- Split the bill evenly among a fixed number of diners


[1.0.0] - 2026-01-01
--------------------

### Added (1 change)

- Compute the tip for a single bill and print the total
```

Two things the docs undersell. First, the format is logchange's **own dialect**: setext
`----` underlines (not Keep-a-Changelog's `## x.y.z`), section labels carry a change count
(`### Added (1 change)`), and the file is topped with a loud "DO NOT MODIFY THIS FILE"
banner and emoji comments. It is Keep-a-Changelog-*ish*, not byte-for-byte KAC — relevant
if a downstream parser expects strict KAC. Second, the `important_notes` field renders as a
dedicated `### Important notes` section, a clean affordance for breaking/operational
callouts that most fragment tools leave to free prose.

The result is good when pull requests include meaningful fragments, and the per-type
grouping is automatic. (Minor wart: `generate` writes a stray `version-summary.md` into
`changelog/unreleased/`, which gets swept along on the next release.)

## Ecosystem Fit

`logchange` is cross-language and works well in repositories where contributors can add
small metadata files. It is a good fit for libraries, CLIs, and monorepos that want release
notes reviewed with the code change. The version is supplied as a CLI flag
(`--versionToRelease`), so it is decoupled from any ecosystem's project file — the run here
used a Python app, but nothing about it was Python-specific.

Its standout trait among the "cross" tools is that it is **fully local and offline** — no
GitHub/GitLab token, no API — unlike platform-bound options such as glab, Release Drafter,
or release-please. It is less native than ecosystem-specific tools for Python or Node, and
less automated than Conventional Commits workflows.

## Maintenance Status

- Latest version: **1.19.15**
- Last release: **2026-05-13**
- GitHub stars: **71**
- Appears actively maintained.
- Repository: <a href="https://github.com/logchange/logchange" target="_blank" rel="noopener noreferrer">https://github.com/logchange/logchange</a>

Recent release metadata is healthy, though the project is smaller than Changie, Towncrier, or git-cliff.

## Verdict

**Verdict: Situational**

Hands-on confirms the original assessment, with more confidence. `logchange` does exactly
what it claims, runs the entire life cycle offline, and has a clean lint gate; the friction
is cosmetic (a null self-version, a stray `version-summary.md`, and its own
Keep-a-Changelog-ish dialect) rather than functional. Use it when a fragment workflow
matches the team's review habits and you want a lightweight, platform-independent tool. If
broad community adoption or strict Keep-a-Changelog output matters more, compare it with
Changie, Towncrier, or Scriv first.
