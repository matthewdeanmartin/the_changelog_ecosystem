Title: github_changelog_generator
Date: 2026-05-31
Slug: github-changelog-generator
Ecosystem: Ruby
Tags: backfill, github-integration, keep-a-changelog, ruby, ruby-gem-cli
Tool_URL: https://rubygems.org/gems/github_changelog_generator
Tool_Version: 1.18.0
Tool_Status: unmaintained
Summary: Ruby CLI/gem that generates CHANGELOG.md from GitHub tags, issues, labels, and merged pull requests.



## Overview

`github_changelog_generator` is the classic Ruby gem for generating `CHANGELOG.md` from GitHub issues, pull requests, labels, and tags. It became popular before GitHub had built-in generated release notes and before many newer release automation tools existed.

It is still useful for backfilling historical changelogs from GitHub metadata, but it should be evaluated carefully for new workflows.

## Installation

```bash
gem install github_changelog_generator
```

## What It Does

- Generates changelog entries from GitHub issues and merged pull requests.
- Groups entries by labels such as bugs, enhancements, and breaking changes.
- Uses tags to separate releases.
- Can backfill a full `CHANGELOG.md` from existing GitHub history.
- Supports many command-line options for filtering and formatting.

## Configuration

Configuration can be passed as command flags or stored in a config file such as `.github_changelog_generator`.

```text
user=example
project=my-gem
future-release=v1.18.0
exclude-labels=question,duplicate,invalid
```

First-run setup is moderate because the output depends heavily on GitHub labels, tag history, and API token access.

## Output Quality

The output is issue and PR oriented:

```markdown
## [1.18.0](https://github.com/example/my-gem/tree/v1.18.0)

**Merged pull requests:**

- Add release note grouping by label [#214](https://github.com/example/my-gem/pull/214)

**Closed issues:**

- Fix changelog generation for renamed default branches [#207](https://github.com/example/my-gem/issues/207)
```

It is excellent for historical audits, but it can read like a GitHub activity report rather than curated release notes.

## Ecosystem Fit

The gem is easy for Ruby projects to install, but its core dependency is GitHub metadata rather than Ruby-specific package publishing. It can be used for any GitHub repository if Ruby is available.

For new GitHub projects, compare it with GitHub generated release notes, Release Drafter, release-please, or git-cliff before adopting it.

## Maintenance Status

- Latest version: **1.18.0**
- Last release: **2026-03-18**
- GitHub stars: **7,525**
- Appears actively maintained.
- Repository: <a href="https://github.com/github-changelog-generator/github-changelog-generator" target="_blank" rel="noopener noreferrer">https://github.com/github-changelog-generator/github-changelog-generator</a>

The site marks the tool as unmaintained, but the captured release metadata shows a recent gem release. Verify repository activity before treating it as abandoned or current.

## Verdict

**Verdict: Situational**

Use `github_changelog_generator` for backfilling or maintaining GitHub-issue-based changelogs, especially in Ruby environments. For a new release process, newer GitHub-native or commit-derived tools usually provide a cleaner path.
