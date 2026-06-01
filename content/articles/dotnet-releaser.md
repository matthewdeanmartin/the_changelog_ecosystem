Title: dotnet-releaser
Date: 2026-05-31
Slug: dotnet-releaser
Ecosystem: Dotnet
Tags: dotnet, dotnet-tool, github-integration, release-notes
Tool_URL: https://www.nuget.org/packages/dotnet-releaser/
Tool_Version: 0.21.0
Tool_Status: active
Summary: All-in-one .NET release CLI for building, testing, packaging, creating release notes from PRs/commits, publishing to NuGet, and creating GitHub releases.



## Overview

`dotnet-releaser` is an all-in-one release runner for .NET projects. It can build, test, pack, collect artifacts, generate release notes, publish to NuGet, and create GitHub Releases from one release configuration.

It is for maintainers who want a cohesive .NET-native release command rather than stitching together separate build, package, changelog, and upload scripts.

## Installation

```bash
dotnet tool install -g dotnet-releaser
```

## What It Does

- Builds and tests .NET projects as part of a release.
- Packs NuGet packages and publishes them.
- Generates release notes from pull requests and commits.
- Creates GitHub Releases and uploads artifacts.
- Supports CI-oriented release orchestration from a single config file.

## Configuration

Projects use a YAML configuration file that describes the solution or projects, package outputs, GitHub release behavior, and NuGet publishing settings.

```yaml
profile: default
projects:
  - src/MyLibrary/MyLibrary.csproj
github:
  owner: example
  repo: my-library
nuget:
  publish: true
```

First-run setup is more involved than a note generator because it covers the whole release path. The payoff is one command that understands common .NET release chores.

## Output Quality

Release notes are typically GitHub-oriented:

```markdown
## 0.21.0

### Changes

- Add deterministic package artifact names
- Fix GitHub release asset upload on retry
```

The notes are serviceable for developer-facing packages, especially when PR titles are curated. Teams with highly polished customer release notes may still want to edit the generated body.

## Ecosystem Fit

The fit is strong for .NET libraries and tools distributed through NuGet and GitHub Releases. It aligns with `dotnet tool`, `.csproj`, NuGet packaging, and CI release jobs.

It is heavier than GitVersion or versionize if you only need version calculation or changelog generation.

## Maintenance Status

- Latest version: **0.21.0**
- Last release: **2026-05-22**
- GitHub stars: **767**
- Appears actively maintained.
- Repository: <a href="https://github.com/xoofx/dotnet-releaser" target="_blank" rel="noopener noreferrer">https://github.com/xoofx/dotnet-releaser</a>

Recent release metadata is healthy, and the scope matches modern .NET package release workflows.

## Verdict

**Verdict: Recommended**

Use `dotnet-releaser` when you want one .NET-native tool to own packaging, notes, GitHub Releases, and NuGet publication. Pick a smaller tool if your pipeline already handles most of those steps.
