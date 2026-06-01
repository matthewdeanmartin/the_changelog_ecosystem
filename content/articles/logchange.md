Title: logchange
Date: 2026-05-31
Slug: logchange
Ecosystem: Cross
Tags: cli, cross, keep-a-changelog, news-fragments, release-notes
Tool_URL: https://github.com/logchange/logchange
Tool_Version: 1.19.15
Tool_Status: active
Summary: Tool that stores each change in a separate YAML file to reduce changelog merge conflicts and generate CHANGELOG.md during release.



## Overview

`logchange` is a fragment-based changelog tool: every change is recorded in its own YAML file, then assembled into `CHANGELOG.md` during release. It is aimed at teams that dislike merge conflicts in one shared changelog file but still want curated release notes instead of commit-message scraping.

It sits closer to Towncrier, Scriv, and Changie than to semantic-release or Release Drafter.

## Installation

```bash
# See https://github.com/logchange/logchange for installation options.
```

## What It Does

- Stores unreleased changes as individual YAML fragments.
- Groups fragments by change type when generating a release.
- Writes or updates `CHANGELOG.md`.
- Can produce release-note text for hosted release pages.
- Reduces conflicts when many contributors add release-note entries in parallel.

## Configuration

Projects configure the changelog file, fragment directory, and categories used for output. A small setup usually defines the release sections the project wants to expose.

```yaml
changelog: CHANGELOG.md
changes: .changes
categories:
  added: Added
  fixed: Fixed
  changed: Changed
```

First-run complexity is moderate because the team must decide where fragments live and how contributors should name categories. After that, each change is a small file rather than an edit to the main changelog.

## Output Quality

Fragment workflows produce more intentional prose than commit scraping:

```markdown
## 1.19.15 - 2026-05-13

### Added

- Add support for release-note generation in CI.

### Fixed

- Preserve existing changelog headings when rendering a new version.
```

The result is usually good when pull requests include meaningful fragments. It can become noisy if fragment categories are too broad or entries are written as internal implementation notes.

## Ecosystem Fit

`logchange` is cross-language and works well in repositories where contributors can add small metadata files. It is a good fit for libraries, CLIs, and monorepos that want release notes reviewed with the code change.

It is less native than ecosystem-specific tools for Python or Node, and less automated than Conventional Commits workflows.

## Maintenance Status

- Latest version: **1.19.15**
- Last release: **2026-05-13**
- GitHub stars: **71**
- Appears actively maintained.
- Repository: <a href="https://github.com/logchange/logchange" target="_blank" rel="noopener noreferrer">https://github.com/logchange/logchange</a>

Recent release metadata is healthy, though the project is smaller than Changie, Towncrier, or git-cliff.

## Verdict

**Verdict: Situational**

Use `logchange` when a fragment workflow matches the team's review habits and you want a lightweight cross-language tool. If broad community adoption matters more, compare it with Changie, Towncrier, or Scriv first.
