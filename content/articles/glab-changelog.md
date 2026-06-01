Title: glab changelog
Date: 2026-05-31
Slug: glab-changelog
Ecosystem: Cross
Tags: cli, cross, gitlab-integration
Tool_URL: https://gitlab.com/gitlab-org/cli
Tool_Version: unknown
Tool_Status: active
Summary: GitLab CLI command that generates changelogs from project commits using GitLab changelog configuration.



## Overview

`glab changelog` is the GitLab CLI surface for GitLab's built-in changelog generator. It gives maintainers and CI jobs a scriptable way to generate changelog text from commit ranges without hand-calling the REST API.

Use it when GitLab Changelogs are the chosen model and you want a local or CI command to drive them.

## Installation

Install the official GitLab CLI for your platform, then authenticate it against GitLab.com or your self-managed GitLab instance.

```bash
glab auth login
```

## What It Does

- Generates changelog output for a GitLab project.
- Uses the project's GitLab changelog configuration.
- Supports release-oriented ranges such as a version and previous tag.
- Can be used in local release scripts or GitLab CI jobs.

## Configuration

Most behavior comes from GitLab project settings and `.gitlab/changelog_config.yml`, not from a large CLI config file.

```yaml
categories:
  added: Added
  fixed: Fixed
  changed: Changed
```

A typical command supplies the version being released:

```bash
glab changelog generate --version v1.8.0
```

First-run setup depends on whether the repository already uses Git trailers. Without trailers, the command has little structured material to work with.

## Output Quality

The output follows GitLab changelog categories:

```markdown
## v1.8.0

### Added

- Add container image provenance metadata

### Fixed

- Prevent duplicate release links in scheduled pipelines
```

It is clean when the underlying commit messages are clean. The CLI does not add editorial judgment.

## Ecosystem Fit

`glab changelog` is a strong fit for GitLab-hosted projects that already use the official CLI. It is language-neutral and easy to place in CI.

It is not a general-purpose changelog generator for GitHub, Bitbucket, or local-only repositories.

## Maintenance Status

- Latest version: **unknown**
- Last release: **unknown**
- Appears actively maintained.
- Repository: <a href="https://github.com/gitlab-org/cli" target="_blank" rel="noopener noreferrer">https://github.com/gitlab-org/cli</a>

The command is part of the official GitLab CLI, so its health is tied to `glab` and GitLab's changelog API.

## Verdict

**Verdict: Recommended**

For GitLab projects using changelog trailers, `glab changelog` is the practical command-line interface to the platform feature. For forge-neutral changelogs, start with git-cliff or Changie instead.
