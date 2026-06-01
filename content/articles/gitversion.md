Title: GitVersion
Date: 2026-05-31
Slug: gitversion
Ecosystem: Dotnet
Tags: ci-cd, dotnet, dotnet-tool-msbuild
Tool_URL: https://www.nuget.org/packages/GitVersion.Tool/
Tool_Version: 6.7.0
Tool_Status: active
Summary: Git-based semantic version calculator for .NET and CI pipelines.



## Overview

GitVersion calculates semantic versions from Git history, branch names, tags, and configuration rules. It is not a changelog writer; it answers the version-number question for .NET builds and CI pipelines.

It belongs in this comparison because many release workflows need version calculation before changelog generation, packaging, and publication.

## Installation

```bash
dotnet tool install -g GitVersion.Tool
```

## What It Does

- Computes SemVer values from repository history.
- Supports common branching strategies such as mainline and GitFlow-style workflows.
- Exposes version variables to CI systems.
- Integrates through a .NET tool, MSBuild package, and build-server support.

## Configuration

Configuration lives in `GitVersion.yml`. The file controls branch modes, tag prefixes, prerelease labels, and increment behavior.

```yaml
mode: ContinuousDelivery
tag-prefix: "v"
branches:
  main:
    regex: ^main$
    increment: Patch
  feature:
    regex: ^features?[/-]
    label: alpha
```

First-run setup is moderate because the configuration must match how the repository actually branches and tags releases.

## Output Quality

GitVersion produces structured version data, not release prose:

```json
{
  "SemVer": "1.8.0",
  "MajorMinorPatch": "1.8.0",
  "InformationalVersion": "1.8.0+12.Branch.main.Sha.abcdef0"
}
```

That output is excellent for builds, packages, and CI variables, but it does not replace release notes.

## Ecosystem Fit

The fit is very strong for .NET projects, especially libraries that need deterministic assembly, NuGet, and CI versions. It also works outside .NET, but .NET remains its natural home.

Pair it with a changelog generator or release publisher when you need user-facing notes.

## Maintenance Status

- Latest version: **6.7.0**
- Last release: **2026-03-23**
- GitHub stars: **3,118**
- Appears actively maintained.
- Repository: <a href="https://github.com/GitTools/GitVersion" target="_blank" rel="noopener noreferrer">https://github.com/GitTools/GitVersion</a>

GitVersion remains a prominent and actively maintained versioning tool in the .NET ecosystem.

## Verdict

**Verdict: Recommended**

Use GitVersion when the hard problem is deriving correct SemVer from Git history. Do not choose it expecting changelog prose; combine it with another tool for notes and release publication.
