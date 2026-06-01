Title: Keep a Changelog
Date: 2026-05-31
Slug: keep-a-changelog
Ecosystem: Cross
Tags: keep-a-changelog, node, npm-library, parser, validation-target, manual-authoring
Tool_URL: https://keepachangelog.com/en/1.1.0/
Tool_Version: unknown
Tool_Status: active
Summary: Human-centered changelog format and vocabulary that many tools target or partially implement.



## Overview

Keep a Changelog is a standard, not an app: it defines a human-centered changelog format built around an `[Unreleased]` section, semantic version headings, dates, and familiar change categories such as Added, Changed, Deprecated, Removed, Fixed, and Security.

In this Node page, it matters because many npm libraries and tools either target the format directly or claim compatibility with its structure.

## Installation

_Format standard — no installation required._

For Node automation, parser libraries such as the npm `keep-a-changelog` package can read and write this format.

## What It Does

- Gives maintainers a stable structure for hand-written changelogs.
- Separates unreleased work from versioned releases.
- Encourages user-facing categories instead of raw commit logs.
- Provides a common target for validators, parsers, and release-note extractors.

## Configuration

There is no tool configuration. A minimal file starts like this:

```markdown
# Changelog

## [Unreleased]

### Added

- Add release-note extraction for GitHub Releases.

## [1.0.0] - 2026-05-31
```

The hard part is team discipline, not setup.

## Output Quality

The format is excellent when maintainers write for users:

```markdown
## [1.3.0] - 2026-05-31

### Added

- Add workspace-aware package release notes.

### Fixed

- Preserve comparison links when publishing a GitHub Release.
```

It avoids the most common generated-changelog failure: dumping internal commit history in front of users.

## Ecosystem Fit

Keep a Changelog is ecosystem-neutral. In Node projects it pairs well with manual release workflows, parser libraries, GitHub release extractors, and tools that update `CHANGELOG.md`.

It is not a replacement for publishing automation; it is the format those tools can operate on.

## Maintenance Status

- Latest version: **1.1.0** of the published format.
- Maintained as a public standard at <a href="https://keepachangelog.com/en/1.1.0/" target="_blank" rel="noopener noreferrer">https://keepachangelog.com/en/1.1.0/</a>

## Verdict

**Verdict: Recommended**

Use Keep a Changelog as the baseline for hand-written or human-reviewed changelogs. Even when a project chooses automation, this standard is still a useful rubric for whether the output is readable by real users.
