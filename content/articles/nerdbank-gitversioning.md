Title: Nerdbank.GitVersioning
Date: 2026-06-02
Slug: nerdbank-gitversioning
Ecosystem: Dotnet
Tags: ci-cd, dotnet, nuget-msbuild-dotnet-tool, semver, versioning, hands-on
Tool_URL: https://www.nuget.org/packages/Nerdbank.GitVersioning/
Tool_Version: 3.7.112
Tool_Status: active
Experiment: examples/dotnet/nerdbank-gitversioning/
Summary: Microsoft/dotnet tool for stamping assemblies, NuGet, and VSIX with Git-derived SemVer; hands-on testing confirms reliable commit-height versioning plus a couple of prepare-release gotchas.



## Overview

Nerdbank.GitVersioning (nbgv) stamps .NET builds with Git-derived version information. It focuses on making assembly versions, NuGet package versions, VSIX versions, and related artifacts reproducible from repository state.

Like GitVersion, it is version infrastructure rather than a changelog writer.

A reproducible hands-on experiment for this tool lives in [`examples/dotnet/nerdbank-gitversioning/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/nerdbank-gitversioning).

## Installation

```bash
dotnet add package Nerdbank.GitVersioning
dotnet tool install -g nbgv
```

> **Note (from hands-on testing):** `dotnet tool install -g` places the binary at `~/.dotnet/tools/nbgv`. In Docker/CI you must add that directory to `PATH` (e.g. `ENV PATH="/root/.dotnet/tools:${PATH}"`) or `nbgv` will not be found.

## What It Does

- Computes versions from Git commits and tags (specifically commit *height*).
- Integrates with MSBuild so projects are stamped during normal builds.
- Produces NuGet package and assembly version metadata.
- Supports CI scenarios where build artifacts need deterministic versions.
- Provides the `nbgv` CLI for inspection and release tasks (`prepare-release`, `set-version`, `get-version`).

## Configuration

Configuration lives in `version.json` at the repository root or project scope.

```json
{
  "version": "1.0",
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

First-run setup is reasonable for SDK-style .NET projects, but teams must understand how public release branches and tags affect version labels — and how the `prepare-release` prerelease suffix interacts with `publicReleaseRefSpec` (see the hands-on findings).

## Ecosystem Fit

The fit is excellent for .NET libraries, Visual Studio extensions, and Microsoft-style build pipelines that need version stamping built into MSBuild. It can be lighter than GitVersion when you want project-integrated version metadata rather than a separate branching-model engine.

It should be paired with a changelog or release-note tool for publication — nbgv produces no release prose.

## Maintenance Status

- Version used in testing: **3.7.112** (the installable stable release).
- Latest published metadata also shows a `3.10.x-alpha` build; the site's `1900-01-01` last-release date is a placeholder artifact.
- GitHub stars: **1,563**
- Maintained under the `dotnet` org.
- Repository: <a href="https://github.com/dotnet/Nerdbank.GitVersioning" target="_blank" rel="noopener noreferrer">https://github.com/dotnet/Nerdbank.GitVersioning</a>

The placeholder-like last-release date is a data-quality flag, not a sign of abandonment; the package is active on NuGet.

---

## Hands-on findings

The notes below come from driving `nbgv` 3.7.112 through a real life cycle in an offline Docker container (`mcr.microsoft.com/dotnet/sdk:8.0`). A minimal .NET "tip calculator" was committed across five stages in the container's isolated git repo, exercising `get-version`, `prepare-release`, and `set-version`. The full transcript and JSON artifact are in [`examples/dotnet/nerdbank-gitversioning/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/nerdbank-gitversioning).

nbgv produces **no CHANGELOG.md** — it is version infrastructure. The "output" below is version data at each stage.

### Stage 1 — first commit (`VersionHeight: 1`)

```
Version:                      1.0.1.62732
AssemblyVersion:              1.0.0.0
AssemblyInformationalVersion: 1.0.1+f50c1afe15
NuGetPackageVersion:          1.0.1
```

The third segment is commit height (1). The fourth segment (62732) is a **time-based offset** (minutes since a reference epoch), not a sequential CI build counter. `PublicRelease: true` because `main` matches `publicReleaseRefSpec`.

### Stage 2 — second commit (`VersionHeight: 2`)

```
Version:             1.0.2.8713
NuGetPackageVersion: 1.0.2
```

Height incremented automatically; clean (no prerelease suffix) because `PublicRelease: true`.

### Stage 3 — after `nbgv prepare-release`

```
NuGetPackageVersion: 1.1.1-alpha
```

`prepare-release` printed:

```
v1.0 branch now tracks v1.0 stabilization and release.
main branch now tracks v1.1-alpha development.
```

It created the `v1.0` branch at HEAD and **auto-committed** a `version.json` change on `main` (`"version": "1.1-alpha"`). The `-alpha` suffix now flows into every NuGet version on `main` until removed.

### Stage 5 — after `nbgv set-version 2.0`

```
Version:             2.0.1.10976
NuGetPackageVersion: 2.0.1
VersionHeight:       1
```

Height resets to 1 because the `version.json` change is the new height anchor. Final `get-version -f json` reports `SimpleVersion: 2.0.1`, `MajorMinorVersion: 2.0`, `PublicRelease: true` — within ~100 lines covering NuGet, npm, Chocolatey, assembly, and cloud-build variables.

### Pros (observed)

- **Zero configuration friction for SDK-style projects.** Drop `version.json`, add the package reference, and every `dotnet build` stamps the assembly. The CLI works purely from git history with no build needed.
- **Commit height is automatic** — every commit on the same major.minor bumps the patch segment, preventing "forgot to bump the version" mistakes.
- **`prepare-release` does the whole branching ceremony in one command** (release branch + next dev prerelease on `main` + commit).
- **JSON output is CI-friendly** — every format a pipeline needs in one blob; parsing `SimpleVersion`/`NuGetPackageVersion` is trivial.
- **`PublicRelease` is driven by branch/tag patterns,** so feature-branch CI artifacts get prerelease+hash suffixes automatically, avoiding version collisions.

### Cons / pain points (observed)

- **`prepare-release` auto-commits.** It commits the `version.json` bump on `main` itself, so a script that tries to `git commit` afterward fails with "nothing to commit". Guard it with a `git diff` check. Not obvious from the docs.
- **The `-alpha` suffix survives `publicReleaseRefSpec`.** After `prepare-release`, even though `main` is in the ref spec, the literal `"1.1-alpha"` in `version.json` propagates into `NuGetPackageVersion`. `main` keeps publishing prerelease packages until you run `nbgv set-version 1.1` (no suffix). Correct by design but easy to misread.
- **Fourth version segment is time-based, not sequential** (`1.0.1.62732`). Fine for `AssemblyFileVersion`, but it surprises engineers expecting `1.0.1.0`.
- **No CHANGELOG, release notes, or commit-message parsing.** Pair it with git-cliff, towncrier, or a manual Keep-a-Changelog flow. The docs say so, but "release tool" attracts users expecting notes generation.
- **PATH setup required in containers/CI** (see install note).

### Docs vs. reality

The original article was accurate: nbgv stamps Git-derived versions, computes from commit height, exposes the `nbgv` CLI, and has no opinion about release-note wording — all confirmed. The run surfaced three things the original undersold: the `prepare-release` auto-commit gotcha, the `-alpha`/`publicReleaseRefSpec` interaction, and the time-based fourth segment. The "pair it with a changelog tool" advice is correct and, in practice, an explicit decision every nbgv team must make.

## Verdict

**Verdict: Recommended — with caveats**

The hands-on run confirms nbgv delivers what it promises: reproducible, Git-derived version stamping with minimal configuration, and a genuinely useful `prepare-release` for teams wanting a structured release/development branch split. Two caveats to carry into automation:

1. `prepare-release` makes its own commit — guard any follow-up `git commit` in CI scripts.
2. After `prepare-release`, `main` emits prerelease NuGet packages (e.g. `1.1.2-alpha`) until you call `nbgv set-version <version>` without a prerelease qualifier.

Neither changes the recommendation. nbgv remains the right choice for .NET library or tool authors who want deterministic, MSBuild-integrated versioning from git history. Do not treat it as a release-note generator; pair it with a separate changelog process.
