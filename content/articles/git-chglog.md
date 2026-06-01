Title: git-chglog
Date: 2026-05-31
Slug: git-chglog
Ecosystem: Go
Tags: backfill, conventional-commits, git-tags, go, go-cli, custom-templates, changelog-file, archived
Tool_URL: https://github.com/git-chglog/git-chglog
Tool_Version: 0.15.4
Tool_Status: archived
Summary: Go-based changelog generator that uses git tags and commits with configurable templates.



## Overview

`git-chglog` is a Go-based changelog generator that reads git tags and commits, groups them by configured rules, and renders a changelog through Go templates. Historically, it was one of the stronger standalone choices for Conventional Commits-style changelog generation before `git-cliff` became the more active cross-language default.

Its main value today is existing installations and backfill workflows. It can still generate useful output, but the archived repository status should shape any new adoption decision.

## Installation

```bash
# See https://github.com/git-chglog/git-chglog for installation options
# (binary releases, Homebrew, package managers)
```

## What It Does

- Generates changelogs from git tag ranges such as `v1.0.0..v1.1.0`.
- Supports Conventional Commits-like grouping by type, scope, subject, issues, refs, merges, and reverts.
- Uses YAML configuration in `.chglog/config.yml`.
- Renders output with Go `text/template` plus Sprig-style helper functions.
- Supports custom templates, repository URLs, path filters, and output files.
- Can backfill a `CHANGELOG.md` from existing tag history.

## Configuration

`git-chglog --init` creates `.chglog/config.yml` and a template file. The config is explicit and powerful, but it is more old-school than current `git-cliff` configuration.

```yaml
bin: git
style: github
template: CHANGELOG.tpl.md
info:
  title: CHANGELOG
  repository_url: https://github.com/example/project
options:
  tag_filter_pattern: '^v'
  sort: date
  commits:
    filters:
      Type:
        - feat
        - fix
  commit_groups:
    group_by: Type
    title_maps:
      feat: Features
      fix: Bug Fixes
```

First-run setup is moderate: you need both config and template files, and teams should understand their commit format before relying on the output.

## Output Quality

With good commit messages, `git-chglog` can produce a conventional grouped changelog:

```markdown
## v1.4.0

### Features

- add configuration file discovery

### Bug Fixes

- preserve tag ordering when generating historical sections
```

The output is template-driven and predictable. Like every commit-derived generator, it works best when commit summaries were written for humans and not only for maintainers.

## Ecosystem Fit

The tool is implemented in Go and distributed as a CLI, so it remains easy to install in Go-oriented environments. It is not Go-specific in behavior, though; it is a general git changelog generator.

In new projects, `git-cliff` usually offers a more active path with similar or better flexibility. Existing `git-chglog` users with stable templates can continue using it, but should plan around the archived status.

## Maintenance Status

- Latest version: **0.15.4**
- Last release: **2023-02-15**
- GitHub stars: **2,874**
- **Repository is archived** — no new development expected.
- Repository: <a href="https://github.com/git-chglog/git-chglog" target="_blank" rel="noopener noreferrer">https://github.com/git-chglog/git-chglog</a>

The documentation and repository remain available, but the archived state makes it a maintenance risk for new release infrastructure.

## Verdict

**Verdict: Situational**

Use `git-chglog` only when a project already has working templates or specifically wants this older Go implementation. For new commit-derived changelog workflows, prefer `git-cliff`; for complete Go release automation, prefer GoReleaser.
