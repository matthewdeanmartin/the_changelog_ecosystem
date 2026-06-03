Title: GitVersion
Date: 2026-06-02
Slug: gitversion
Ecosystem: Dotnet
Tags: ci-cd, dotnet, dotnet-tool-msbuild, semver, conventional-commits, hands-on
Tool_URL: https://www.nuget.org/packages/GitVersion.Tool/
Tool_Version: 6.0.2
Tool_Status: active
Experiment: examples/dotnet/gitversion/
Summary: Git-based SemVer calculator for .NET and CI; hands-on testing confirms correct conventional-commit bumps but flags a silent v5→v6 config breaking change.



## Overview

GitVersion calculates semantic versions from Git history, branch names, tags, and configuration rules. It is not a changelog writer; it answers the version-number question for .NET builds and CI pipelines.

It belongs in this comparison because many release workflows need version calculation before changelog generation, packaging, and publication.

A reproducible hands-on experiment for this tool lives in [`examples/dotnet/gitversion/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/gitversion).

## Installation

```bash
dotnet tool install -g GitVersion.Tool
```

The installed binary is `dotnet-gitversion`.

## What It Does

- Computes SemVer values from repository history.
- Supports common branching strategies such as mainline and GitFlow-style workflows.
- Exposes version variables (~25 of them) to CI systems.
- Integrates through a .NET tool, MSBuild package, and build-server support.

## Configuration

Configuration lives in `GitVersion.yml`. The file controls branch modes, tag prefixes, prerelease labels, and increment behavior.

> **Important (from hands-on testing):** In **v6**, the top-level `mode:` key was removed. `mode` is now a **per-branch** setting only, and the valid values are `ContinuousDelivery`, `ManualDeployment`, and `ContinuousDeployment`. The old `mode: Mainline` fails with a cryptic `'Requested value 'Mainline' was not found.'` Any v5 config carrying a top-level `mode` (or `Mainline`) will silently break on upgrade. A modern v6 config:

```yaml
tag-prefix: "v"
branches:
  main:
    regex: ^main$|^master$
    mode: ContinuousDelivery
    increment: Patch
  feature:
    regex: ^features?[/-]
    label: alpha
```

First-run setup on a fresh repo is easy. Migration from a v5 config is the friction point — see the hands-on findings.

## Ecosystem Fit

The fit is very strong for .NET projects, especially libraries that need deterministic assembly, NuGet, and CI versions. It also works outside .NET, but .NET remains its natural home.

GitVersion produces structured version data, not release prose. Pair it with a changelog generator or release publisher when you need user-facing notes.

## Maintenance Status

- Latest installable stable version (at experiment time): **6.0.2**
- Last release: **2026-03-23** (6.x line)
- GitHub stars: **3,118**
- Appears actively maintained.
- Repository: <a href="https://github.com/GitTools/GitVersion" target="_blank" rel="noopener noreferrer">https://github.com/GitTools/GitVersion</a>

GitVersion remains a prominent and actively maintained versioning tool in the .NET ecosystem. (An earlier metadata pass listed `6.7.0`; the stable, installable 6.x build used in testing was `6.0.2`.)

---

## Hands-on findings

The notes below come from driving `GitVersion.Tool` 6.0.2 through a real life cycle in an offline Docker container (`mcr.microsoft.com/dotnet/sdk:8.0`). A minimal .NET 8 console "tip calculator" was committed and tagged through three versions inside the container. The full transcript and `gitversion.json` artifact are in [`examples/dotnet/gitversion/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/gitversion).

Since GitVersion is a version calculator rather than a changelog writer, the "output" here is the version data it computes at each stage.

### Version progression observed

| State                         | MajorMinorPatch | SemVer    |
|-------------------------------|-----------------|-----------|
| After initial commit, no tag  | 0.1.0           | 0.1.0-1   |
| After `git tag v1.0.0`        | 1.0.0           | 1.0.0     |
| After `feat:` commit          | 1.1.0           | 1.1.0-1   |
| After `git tag v1.1.0`        | 1.1.0           | 1.1.0     |
| After `feat!:` commit         | 2.0.0           | 2.0.0-1   |
| After `git tag v2.0.0`        | 2.0.0           | 2.0.0     |

`SemVer` includes a pre-release suffix (`-1`) between tags ("one commit ahead of the source"); `MajorMinorPatch` is always the clean triple. Sample clean-tag JSON (stage 2):

```json
{
  "FullSemVer": "1.0.0",
  "MajorMinorPatch": "1.0.0",
  "SemVer": "1.0.0",
  "CommitsSinceVersionSource": 0,
  "InformationalVersion": "1.0.0+Branch.master.Sha.fd36aef..."
}
```

### Pros (observed)

- **Correct version derivation from commit messages.** `feat:` incremented minor, `feat!:` incremented major, exactly per Conventional Commits — no manual intervention.
- **`/showvariable` is excellent for scripting.** `dotnet-gitversion /showvariable MajorMinorPatch` prints only `1.1.0`, no JSON parsing. Perfect for CI shell steps.
- **25 variables in one shot** (`AssemblySemVer`, `InformationalVersion`, `NuGetVersion`, `FullSemVer`, …) from a single invocation.
- **Zero-config baseline.** Without `GitVersion.yml`, it works sensibly with just tags, defaulting to patch-increment on the main branch.
- **Deterministic re-runs.** The same git history always produces the same version.

### Cons / pain points (observed)

- **`mode: Mainline` silently removed in v6** — the major migration footgun (see config note above). Breaks any v5 config on upgrade.
- **Verbose INFO logging to stderr.** Every call emits ~8 diagnostic lines (working dir, DotGit path, cache file, build-agent detection). Noisy in CI; suppress with stderr redirection or `/l`.
- **`SemVer` carries a pre-release suffix between tags** (`1.1.0-1`). Technically correct, but surprising; use `MajorMinorPatch` for the clean triple.
- **`dotnet build -q` triggers "Question build" and exits non-zero.** A general MSBuild footgun (not GitVersion's fault) that bit the setup; use `--nologo -v minimal`.
- **`UncommittedChanges` inflates without `.gitignore`.** Build artifacts in `bin/`/`obj/` get counted; trivial to fix but confusing.

### Docs vs. reality

The original article accurately described what GitVersion does and the JSON output shape. Two corrections from the v6 run: the top-level `mode` key no longer exists (per-branch `mode` values are still valid), and the installable stable build was `6.0.2`, not `6.7.0`. "First-run setup is moderate" understates the v5→v6 migration friction — fresh-repo setup is easy, but migrating a v5 config is a silent failure until you know what to look for.

## Verdict

**Verdict: Recommended — with a v6 migration warning**

GitVersion does exactly what it claims: reliable, deterministic SemVer from git history. In the experiment, conventional-commit bump rules (`feat:` → minor, `feat!:` → major) worked perfectly with no manual intervention, and `/showvariable` is genuinely useful for CI scripting.

The original "Recommended" verdict stands, with one addition: teams upgrading from GitVersion v5 should read the v6 migration guide **before** upgrading in CI — the `mode: Mainline` removal is a silent breaking change with a non-obvious error. New adopters starting on v6 from scratch will have an easier time. Do not choose GitVersion expecting changelog prose; combine it with another tool for notes and release publication.
