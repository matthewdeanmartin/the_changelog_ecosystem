Title: conventional-changelog
Date: 2026-05-31
Slug: conventional-changelog
Ecosystem: Node
Tags: conventional-commits, keep-a-changelog, node, npm-cli-library, release-notes, semantic-versioning, changelog-file
Tool_URL: https://www.npmjs.com/package/conventional-changelog
Tool_Version: 7.2.0
Tool_Status: active
Summary: Core Node ecosystem changelog toolkit for generating changelogs and release notes from commit metadata.



## Overview

`conventional-changelog` is the foundational Node toolkit for turning Conventional Commits into changelog text. It is both a CLI-facing package family and a library layer used by many other release tools.

The tool is best understood as infrastructure. It does not own an entire release workflow the way semantic-release does, but it provides the commit parsing, presets, and writer behavior that power a lot of the Node changelog ecosystem.

## Installation

```bash
npm install --save-dev conventional-changelog
```

## What It Does

- Reads commits since the previous semver tag or a supplied range.
- Parses Conventional Commits into features, fixes, breaking changes, and custom sections.
- Uses presets such as Angular or conventionalcommits to shape output.
- Generates Markdown release notes or updates a `CHANGELOG.md` file.
- Can be embedded in other release tooling through its library API.

## Configuration

Configuration depends on whether the project uses the CLI directly or wraps the library. A simple npm script can generate or append changelog content:

```json
{
  "scripts": {
    "changelog": "conventional-changelog -p conventionalcommits -i CHANGELOG.md -s"
  }
}
```

More advanced users configure parser, writer, and preset behavior in JavaScript. First-run setup is easy if the repository already follows Conventional Commits; otherwise the generated output will be noisy or incomplete.

## Output Quality

Typical output is grouped and concise:

```markdown
## 2.4.0 (2026-05-31)

### Features

* add workspace release-note generation

### Bug Fixes

* preserve changelog links when rewriting sections
```

The quality tracks commit discipline. It is excellent for projects that write user-facing commit titles and breaking-change footers, and weak for repositories with vague merge commits.

## Ecosystem Fit

This is deeply native to Node/npm because so many tools, presets, and commit conventions grew around it. It pairs naturally with commitlint, Commitizen, npm scripts, semantic-release plugins, and older standard-version-style workflows.

For new projects, use it directly when you want a building block. Use semantic-release, release-it, or commit-and-tag-version when you want a complete release command.

## Maintenance Status

- Latest version: **7.2.0**
- Appears actively maintained.
- Repository: <a href="https://github.com/conventional-changelog/conventional-changelog" target="_blank" rel="noopener noreferrer">https://github.com/conventional-changelog/conventional-changelog</a>

The package remains central and current in the conventional-changelog monorepo.

## Verdict

**Verdict: Recommended**

Use `conventional-changelog` as the baseline Node commit-derived changelog engine. It is not the friendliest end-user workflow by itself, but it is the shared machinery behind many of the higher-level tools in this ecosystem.
