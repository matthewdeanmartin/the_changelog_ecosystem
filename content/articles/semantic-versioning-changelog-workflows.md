Title: Semantic Versioning and Changelog Workflows
Date: 2026-06-01
Slug: semantic-versioning-changelog-workflows
Ecosystem: Cross
Tags: semantic-versioning, version-bump, changelog, release-automation
Tool_Status: research
Summary: Stub article on how semantic versioning interacts with changelog entries and release automation.

## Overview

[Semantic Versioning](https://semver.org/) gives a version number three slots — `MAJOR.MINOR.PATCH` — with a contract: increment MAJOR for incompatible API changes, MINOR for backward-compatible additions, PATCH for backward-compatible fixes. Changelog workflows lean on this contract because the changelog and the version number are answering the same question from two directions. The changelog says *what* changed; the version number says *how much it matters*. Automation tries to derive the second from the first.

The mapping is clean on paper. A changelog organized by Keep a Changelog sections lines up with SemVer almost directly:

| Changelog content | Implied SemVer bump |
|---|---|
| `Removed`, breaking `Changed`, breaking API change | MAJOR |
| `Added`, non-breaking `Changed`, `Deprecated` | MINOR |
| `Fixed`, `Security` (non-breaking) | PATCH |

**Breaking-change detection** is where the clean mapping meets reality. A tool can only detect a breaking change if it was *declared* — via a Conventional Commits `!`/`BREAKING CHANGE:` footer, a `major`-tagged changelog fragment, or a `breaking` PR label. Nothing in commit text reliably reveals an *undeclared* breaking change (a subtly changed return value, a tightened input validation). So automated SemVer is only as correct as the contributor's labelling discipline; the version number inherits the changelog's blind spots.

**Prereleases** are SemVer's pressure valve. Identifiers after a hyphen (`2.0.0-rc.1`, `1.5.0-beta.2`) sort before the final release and let a project publish an unstable MAJOR for testing before committing to it. Changelog tools handle this by accumulating entries under an `[Unreleased]` or prerelease heading and only finalizing the section when the stable version is cut.

**Automated release decisions** chain these together: collect changes since the last tag → classify each → take the highest implied bump → compute the next version → write the changelog section under that version → tag and publish. semantic-release, release-please, and standard-version all implement this pipeline. The differences are in *where* the classification comes from (commits vs. fragments vs. labels) and how much human approval sits in the loop — which is the subject of the tensions below.

## Key Tensions

- Human judgment versus commit-derived bumping.
- Libraries versus applications.
- Monorepos and independent package versions.
- Backports, maintenance branches, and prerelease channels.

## Related Tools

- [semantic-release]({filename}semantic-release.md)
- [release-please]({filename}release-please.md)
- [standard-version]({filename}standard-version.md)
