Title: Nerdbank.GitVersioning
Date: 2026-05-31
Slug: nerdbank-gitversioning
Ecosystem: Dotnet
Tags: ci-cd, dotnet, nuget-msbuild-dotnet-tool
Tool_URL: https://www.nuget.org/packages/Nerdbank.GitVersioning/
Tool_Version: 3.10.44-alpha-g09c6831bf9
Tool_Status: active
Summary: Microsoft/dotnet project for stamping assemblies, NuGet packages, VSIX, and other artifacts with Git-derived SemVer information.



## Overview

Nerdbank.GitVersioning stamps .NET builds with Git-derived version information. It focuses on making assembly versions, NuGet package versions, VSIX versions, and related artifacts reproducible from repository state.

Like GitVersion, it is version infrastructure rather than a changelog writer.

## Installation

```bash
dotnet add package Nerdbank.GitVersioning
dotnet tool install -g nbgv
```

## What It Does

- Computes versions from Git commits and tags.
- Integrates with MSBuild so projects are stamped during normal builds.
- Produces NuGet package and assembly version metadata.
- Supports CI scenarios where build artifacts need deterministic versions.
- Provides the `nbgv` CLI for inspection and release tasks.

## Configuration

Configuration lives in `version.json` at the repository root or project scope.

```json
{
  "version": "1.8",
  "publicReleaseRefSpec": [
    "^refs/heads/main$",
    "^refs/tags/v\\d+\\.\\d+"
  ],
  "cloudBuild": {
    "buildNumber": {
      "enabled": true
    }
  }
}
```

First-run setup is reasonable for SDK-style .NET projects, but teams must understand how public release branches and tags affect version labels.

## Output Quality

The output is version metadata, not changelog text:

```text
Version: 1.8.42
AssemblyVersion: 1.8.0.0
NuGetPackageVersion: 1.8.42-gabcdef0123
```

That makes it valuable for build correctness. It has no opinion about release-note wording.

## Ecosystem Fit

The fit is excellent for .NET libraries, Visual Studio extensions, and Microsoft-style build pipelines that need version stamping built into MSBuild. It can be lighter than GitVersion when you want project-integrated version metadata rather than a separate branching model engine.

It should be paired with a changelog or release-note tool for publication.

## Maintenance Status

- Latest version: **3.10.44-alpha-g09c6831bf9**
- Last release: **1900-01-01**
- GitHub stars: **1,563**
- Last release was over 2 years ago - check if still maintained.
- Repository: <a href="https://github.com/dotnet/Nerdbank.GitVersioning" target="_blank" rel="noopener noreferrer">https://github.com/dotnet/Nerdbank.GitVersioning</a>

The package version in the site metadata looks current despite the placeholder-like last-release date. Verify NuGet and repository activity before making a final adoption call.

## Verdict

**Verdict: Recommended**

Use Nerdbank.GitVersioning when .NET build artifacts need Git-derived versions baked in through MSBuild. Do not treat it as a release-note generator; it is best paired with a separate changelog process.
