Title: git-cliff
Date: 2026-05-31
Slug: git-cliff
Ecosystem: Rust
Tags: backfill, cli, conventional-commits, custom-templates, release-notes, rust, keep-a-changelog, git-tags, ci-cd, github-integration, gitlab-integration
Tool_URL: https://crates.io/crates/git-cliff
Tool_Version: 2.13.1
Tool_Status: active
Summary: Highly customizable changelog generator from git history



## Overview

`git-cliff` is the Rust-written changelog generator that has become a cross-language default. It reads git history, groups commits with Conventional Commits or custom regex parsers, and renders Markdown or other text formats through configurable templates.

For Rust projects, it is often the changelog engine inside a larger release flow: use it directly for `CHANGELOG.md`, call it from `cargo-release`, or let `release-plz` use it under the hood.

## Installation

```bash
cargo install git-cliff
```

## What It Does

- Generates changelog files from tags, commit ranges, or the whole repository history.
- Parses Conventional Commits out of the box and supports custom commit parsers for nonstandard histories.
- Renders output with Tera templates, so teams can target Keep a Changelog, GitHub Releases, AsciiDoc, or local house style.
- Can include remote metadata from supported Git hosting providers, such as pull request numbers and authors.
- Supports backfilling old releases and writing directly to `CHANGELOG.md`.
- Can fail CI when commits do not match configured rules.

## Configuration

`git-cliff --init` creates `cliff.toml`, and Rust projects can also keep configuration in `Cargo.toml`. The config controls tag selection, commit grouping, filtering, preprocessing, and output templates.

```toml
[changelog]
header = "# Changelog\n\n"
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }}\
{% endfor %}
{% endfor %}
"""

[git]
conventional_commits = true
filter_unconventional = true
tag_pattern = "v[0-9]*"

commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Bug Fixes" },
  { message = "^docs", group = "Documentation" },
]
```

First-run setup is easy if the project already uses Conventional Commits. It becomes more involved, but also more powerful, when the team needs custom categories, monorepo-specific scopes, or strict CI filtering.

## Output Quality

Out of the box, `git-cliff` produces readable release-note sections from commit metadata:

```markdown
## [2.4.0] - 2026-05-31

### Features

- Add GitHub PR metadata to release-note templates

### Bug Fixes

- Ignore generated commits when computing the next changelog range
```

The output can be excellent, but the tool cannot turn vague commit messages into good user-facing prose. Its real strength is letting teams encode their release-note structure once and then regenerate consistent output repeatedly.

## Ecosystem Fit

`git-cliff` feels native to Rust because it is available as a Cargo-installed binary, can read `Cargo.toml` configuration, and is widely paired with Rust release tools. It is also intentionally cross-language, which matters for Rust workspaces that include bindings, npm packages, or generated artifacts.

It is the right primitive when the team wants commit-derived changelogs. It is not a fragment workflow like Towncrier or Changesets; the commit history remains the source of truth.

## Maintenance Status

- Latest version: **2.13.1**
- Last release: **2026-04-26**
- GitHub stars: **11,909**
- Appears actively maintained.
- Repository: <a href="https://github.com/orhun/git-cliff" target="_blank" rel="noopener noreferrer">https://github.com/orhun/git-cliff</a>

The official docs are active and cover initialization, configuration, custom templates, custom parsers, GitHub/GitLab metadata, and CI-oriented failure modes.

## Verdict

**Verdict: Recommended**

`git-cliff` is the default Rust-era changelog generator to evaluate first. Use it directly when commits are the source of truth, and pair it with `release-plz`, `cargo-release`, or `cargo-dist` when changelog generation is only one step in a larger release pipeline.
