Title: versionize
Date: 2026-05-31
Slug: versionize
Ecosystem: Dotnet
Tags: conventional-commits, dotnet, dotnet-tool, keep-a-changelog, semantic-versioning
Tool_URL: https://www.nuget.org/packages/versionize/
Tool_Version: 2.5.0
Tool_Status: active
Summary: .NET tool for automatic NuGet versioning and CHANGELOG generation from Conventional Commits.



## Overview

`versionize` brings a Conventional Commits release workflow to .NET projects. It determines the next semantic version, updates project/package metadata, and writes `CHANGELOG.md` entries from commit history.

It is a good fit when the team wants a focused version-and-changelog tool rather than a full release publisher.

## Installation

```bash
dotnet tool install -g versionize
```

## What It Does

- Parses Conventional Commits.
- Determines major, minor, and patch version bumps.
- Updates .NET project version metadata.
- Writes or updates `CHANGELOG.md` in a Keep a Changelog-like shape.
- Can tag releases as part of the workflow.

## Configuration

`versionize` can work with minimal configuration when the project already uses Conventional Commits. Optional settings can live in project metadata or command flags depending on the workflow.

```bash
versionize --dry-run
versionize
```

The main setup requirement is commit discipline. Without Conventional Commits, the version bump and changelog categories will be unreliable.

## Output Quality

Generated changelog sections are commit-derived:

```markdown
## [2.5.0] - 2026-02-01

### Features

- add NuGet package provenance support

### Bug Fixes

- preserve prerelease labels during version bump
```

The output is predictable and familiar to .NET package users, but the prose is only as good as the commit messages.

## Ecosystem Fit

`versionize` feels native for .NET libraries because it is distributed as a .NET tool and understands project versioning. It is smaller and easier to adopt than an all-in-one publisher.

It does not replace a GitHub Release uploader, artifact publisher, or NuGet publishing pipeline by itself.

## Maintenance Status

- Latest version: **2.5.0**
- Last release: **2026-02-01**
- GitHub stars: **373**
- Appears actively maintained.
- Repository: <a href="https://github.com/versionize/versionize" target="_blank" rel="noopener noreferrer">https://github.com/versionize/versionize</a>

The release metadata is current enough to treat it as an active .NET option.

## Verdict

**Verdict: Recommended**

Use `versionize` when a .NET project follows Conventional Commits and needs automatic version bumps plus `CHANGELOG.md`. Use `dotnet-releaser` when the desired scope also includes packaging, GitHub Releases, and NuGet publishing.
