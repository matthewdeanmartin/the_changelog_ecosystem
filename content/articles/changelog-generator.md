Title: changelog-generator
Date: 2026-05-31
Slug: changelog-generator
Ecosystem: Go
Tags: conventional-commits, go, go-cli-library, release-notes, github-action, commit-history, ci-cd
Tool_URL: https://github.com/gabe565/changelog-generator
Tool_Version: 1.1.5
Tool_Status: active
Summary: Configurable commit-based changelog generator that groups commits since the previous release.



## Overview

`changelog-generator` is a focused Go CLI and library for generating release-note text from commits since the previous release. It intentionally resembles GoReleaser's changelog output, making it useful when a project wants GoReleaser-style notes without adopting the full GoReleaser artifact pipeline.

It is a narrower tool than GoReleaser and a smaller ecosystem player than `git-cliff` or Changie. Its best niche is projects that already have another build or publish system but want a lightweight, Go-native changelog step.

## Installation

```bash
# See https://github.com/gabe565/changelog-generator for installation options
# (binary releases, Homebrew, package managers)
```

## What It Does

- Finds commits since the previous release.
- Filters and groups commits into release-note sections.
- Produces GoReleaser-like changelog output.
- Can run as a CLI, a Go library, or a GitHub Action.
- Supports configuration file paths and CI-friendly outputs.

## Configuration

The GitHub Action accepts a config path, and the CLI/library can use project configuration to control grouping and filtering. A typical workflow is lightweight:

```yaml
name: release-notes
on:
  workflow_dispatch:

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gabe565/changelog-generator-action@v1
        with:
          config: .github/changelog.yml
```

First-run setup is low if the default grouping matches the project. It becomes more useful once commit filtering and section names are tuned to the team's commit style.

## Output Quality

The output is commit-derived and compact:

```markdown
## Changelog

### Features

- add release-note preview command

### Bug Fixes

- skip generated dependency update commits
```

It is readable, but it inherits the usual limitation of commit-based tools: commit titles need to be written with release notes in mind.

## Ecosystem Fit

The Go fit is pragmatic. It is available as a Go package and GitHub Action, and it is useful for projects that want GoReleaser-like changelog behavior while using another build system.

It is not broad enough to replace GoReleaser for Go CLI releases, and it is not as mature or configurable as `git-cliff` for complex historical changelogs. Treat it as a small, focused generator.

## Maintenance Status

- Latest version: **1.1.5**
- Last release: **2025-03-02**
- GitHub stars: **4**
- Appears actively maintained.
- Repository: <a href="https://github.com/gabe565/changelog-generator" target="_blank" rel="noopener noreferrer">https://github.com/gabe565/changelog-generator</a>

The project is small but current, with docs for GitHub Action usage, configuration, installation, and library/CLI entry points.

## Verdict

**Verdict: Situational**

Use `changelog-generator` when you want a lightweight Go-native generator that produces GoReleaser-like release notes without adopting GoReleaser itself. For flagship Go CLI release pipelines, start with GoReleaser; for highly customized commit parsing, compare it with `git-cliff`.
