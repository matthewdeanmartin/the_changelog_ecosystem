Title: auto-changelog
Date: 2026-05-31
Slug: auto-changelog
Ecosystem: Node
Tags: backfill, conventional-commits, git-tags, node, npm-cli, templates, unmaintained
Tool_URL: https://www.npmjs.com/package/auto-changelog
Tool_Version: 2.6.0
Tool_Status: unmaintained
Summary: Command-line tool that generates changelogs from git tags and commit history.



## Overview

`auto-changelog` is a simple Node CLI for generating a `CHANGELOG.md` from git tags, commits, and optionally GitHub metadata. It is useful for backfilling a changelog in an older repository or maintaining a lightweight generated log.

The project is mature rather than current. It still does the basic job, but new projects should compare it with `git-cliff`, `conventional-changelog`, or release-it plugins before adopting it.

## Installation

```bash
npm install --save-dev auto-changelog
```

## What It Does

- Generates changelog entries from git tags and commit history.
- Can backfill older releases.
- Supports templates for changing output style.
- Can link commits, issues, and compare URLs for GitHub-hosted projects.
- Can write directly to `CHANGELOG.md`.

## Configuration

Configuration can be expressed as CLI flags or in `package.json`. A minimal setup is often just an npm script:

```json
{
  "scripts": {
    "changelog": "auto-changelog -p"
  },
  "auto-changelog": {
    "output": "CHANGELOG.md",
    "template": "keepachangelog",
    "unreleased": true,
    "commitLimit": false
  }
}
```

First-run setup is low. The main tuning is choosing template, tag range, and commit filtering.

## Output Quality

Output is tag-and-commit driven:

```markdown
## v2.6.0

- Add unreleased section support
- Fix GitHub compare link generation
- Update changelog template defaults
```

It is readable for simple projects, but it can feel mechanical compared with Changesets or hand-maintained Keep a Changelog entries.

## Ecosystem Fit

`auto-changelog` fits older npm-script workflows and quick changelog backfills. It does not own versioning, publishing, or release PRs.

In 2026 it is best viewed as a mature utility rather than a strategic release platform.

## Maintenance Status

- Latest version: **2.6.0**
- Tool status in this survey: **unmaintained**
- Repository: <a href="https://github.com/CookPete/auto-changelog" target="_blank" rel="noopener noreferrer">https://github.com/CookPete/auto-changelog</a>

Check maintenance expectations carefully before adopting it for new release infrastructure.

## Verdict

**Verdict: Situational**

Use `auto-changelog` for simple generated changelogs or backfills. For new automated release workflows, prefer more active tools with stronger CI and package-publishing stories.
