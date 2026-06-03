Title: dotnet-releaser
Date: 2026-06-02
Slug: dotnet-releaser
Ecosystem: Dotnet
Tags: dotnet, dotnet-tool, github-integration, release-notes, hands-on
Tool_URL: https://www.nuget.org/packages/dotnet-releaser/
Tool_Version: 0.21.0
Tool_Status: active
Experiment: examples/dotnet/dotnet-releaser/
Summary: All-in-one .NET release CLI for building, packaging, and publishing; hands-on testing confirms a genuinely capable local cross-platform `build` but a GitHub-only changelog path with no offline preview.



## Overview

`dotnet-releaser` is an all-in-one release runner for .NET projects. It can build, test, pack, collect artifacts, generate release notes, publish to NuGet, and create GitHub Releases from one release configuration.

It is for maintainers who want a cohesive .NET-native release command rather than stitching together separate build, package, changelog, and upload scripts.

A reproducible hands-on experiment for this tool lives in [`examples/dotnet/dotnet-releaser/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/dotnet-releaser).

## Installation

```bash
dotnet tool install -g dotnet-releaser
```

> **Note (from hands-on testing):** version 0.21.0 ships its binaries under `tools/net10.0/any/` and therefore **requires the .NET 10 SDK**. Installing it on an SDK 8.0 or 9.0 image fails with an opaque message — `Settings file 'DotnetToolSettings.xml' was not found in the package` — rather than a clear "requires .NET 10". Pin your container/CI to `mcr.microsoft.com/dotnet/sdk:10.0`.

## What It Does

- Builds and tests .NET projects as part of a release.
- Packs NuGet packages and publishes them.
- Generates release notes from pull requests and commits (via the GitHub API).
- Creates GitHub Releases and uploads artifacts.
- Supports CI-oriented release orchestration from a single config file.

## Configuration

Projects use a TOML configuration file that describes the projects, package outputs, GitHub release behavior, and NuGet publishing settings.

The safest way to get a valid config is to let the tool generate it:

```bash
dotnet-releaser new --project TipCalc.csproj --user test --repo test
```

This produces:

```toml
# configuration file for dotnet-releaser
[msbuild]
project = "TipCalc.csproj"
[github]
user = "test"
repo = "test"
```

> **Caution (from hands-on testing):** the README shows array-of-tables syntax (`[[msbuild]]`, `[[nuget]]`) and an `owner` key, but the actual parser expects **singular** `[msbuild]`/`[github]` tables and the `[github]` section uses **`user`**, not `owner`. The wrong format fails with `Expected StartTable token but was StartArray`. Use `dotnet-releaser new` rather than hand-writing TOML from README examples.

First-run setup is more involved than a note generator because it covers the whole release path. The payoff is one command that understands common .NET release chores.

## Ecosystem Fit

The fit is strong for .NET libraries and tools distributed through NuGet and GitHub Releases. It aligns with `dotnet tool`, `.csproj`, NuGet packaging, and CI release jobs.

It is heavier than GitVersion or Versionize if you only need version calculation or changelog generation — but note (see below) that the `build` sub-command is a genuinely useful *local* cross-compilation tool, not merely a CI step.

## Maintenance Status

- Latest version: **0.21.0**
- Last release: **2026-05-22**
- GitHub stars: **767**
- Appears actively maintained.
- Repository: <a href="https://github.com/xoofx/dotnet-releaser" target="_blank" rel="noopener noreferrer">https://github.com/xoofx/dotnet-releaser</a>

Recent release metadata is healthy, and the scope matches modern .NET package release workflows.

---

## Hands-on findings

The notes below come from driving `dotnet-releaser` 0.21.0 through a real life cycle in an offline Docker container (no GitHub or NuGet credentials). The full setup and transcript are in [`examples/dotnet/dotnet-releaser/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/dotnet-releaser).

**Setup:** `mcr.microsoft.com/dotnet/sdk:10.0`, a minimal .NET 10 console project (`TipCalc`) taken through three versions, with 3 commits + 3 tags (`v1.0.0`–`v3.0.0`) in an ephemeral repo. We probed which sub-commands run without GitHub/NuGet credentials: `--version`, `--help`, `new`, `build`, `run`, and `changelog`.

### `dotnet-releaser new` (works fully offline)

```
2026-06-02 14:30:15 INF  New configuration file `/work/repo/dotnet-releaser.toml`
                          created successfully.
```

### `dotnet-releaser build` (local build succeeds; publish requires token)

```
2026-06-02 14:30:19 INF  Building `/work/repo/TipCalc.csproj` - Configuration = Release
2026-06-02 14:30:20 INF  Building NuGet Package - TipCalc
2026-06-02 14:30:23 INF  NuGet Package built: TipCalc.1.0.0.nupkg

2026-06-02 14:30:23 INF  Building target platform [win-x64]   / [zip] ...
2026-06-02 14:30:47 INF  Build successful: TipCalc.1.0.0.win-x64.zip
2026-06-02 14:30:47 INF  Building target platform [win-arm64] / [zip] ...
2026-06-02 14:31:08 INF  Build successful: TipCalc.1.0.0.win-arm64.zip
... (linux-x64/arm64 rpm+deb+tar.gz, osx-x64/arm64 tar.gz) ...
2026-06-02 14:33:15 INF  Build successful: TipCalc.1.0.0.osx-arm64.tar.gz
```

`build` completed with **no GitHub token** and produced **11 artifacts** — 1 NuGet package plus 10 cross-compiled distribution packages across 9 targets (win-x64/arm64, linux-x64/arm64, osx-x64/arm64). The token requirement only kicks in at the publish/release step.

### `dotnet-releaser changelog` (requires a token immediately)

```
2026-06-02 14:33:38 ERR  Missing required option `--github-token`.
```

### `dotnet-releaser run` (artifacts-folder conflict after a prior build)

```
2026-06-02 14:33:15 ERR  The artifacts folder `/work/repo/artifacts-dotnet-releaser`
                          already exists. Use `--force` to delete/recreate this
                          folder during a `build`/`publish`.
```

### Pros (observed)

- **`build` does real work locally.** Restore, compile, NuGet pack, and cross-compile for 9 targets, all with no credentials. The breadth of platform coverage from one command is impressive.
- **`new` generates a valid config** without needing a git remote or GitHub credentials.
- **Structured, timestamped logging.** The `INF`/`ERR` lines are readable and machine-parseable.
- **Honest help text.** Sub-command help accurately describes token requirements and CI-only semantics.

### Cons / pain points (observed)

- **Requires .NET 10 SDK** — and fails with a cryptic message on SDK 8/9 (see install note above).
- **Config format is poorly documented** — README TOML examples are wrong (see config note above).
- **`build` crashes with a `NullReferenceException` without a git remote.** `GitInformation.Create` throws an unhandled exception (full stack trace) if no remote is configured. Adding a fake, non-resolvable remote (`git remote add origin https://github.com/test/test.git`) works around it; the tool should emit a friendly error instead.
- **`run` then `build` collide on the artifacts folder.** A local `build` → `run` loop hits the artifacts-collision error on every iteration unless you pass `--force`.
- **No changelog/release notes without GitHub.** `run`, `changelog`, and `publish` all require `--github-token`. There is no `--dry-run`, no local Markdown output, and no way to preview the changelog offline. GitHub is the sole source of truth for change history.
- **Build is slow for a quick test.** Cross-compiling 9 platforms takes 3+ minutes for a trivial project. A `--skip-app-packages-for-build-only` flag exists but is neither the default nor prominent.

### Docs vs. reality

The original article was accurate in broad strokes. Two refinements from the hands-on run:

1. **SDK floor.** 0.21.0 targets `net10.0`; SDK 8.0 hits an opaque install failure.
2. **`build` is more capable locally than "CI-only" implied.** It is a genuine local cross-compilation tool producing distribution-ready packages with no GitHub contact.

## Verdict

**Verdict: Recommended — with caveats**

`dotnet-releaser` does what it claims: a cohesive .NET release orchestrator for teams publishing to both NuGet and GitHub Releases. Hands-on testing strengthens the case for the `build` command as a local cross-platform packager, while sharpening the caveats:

- Pin to the **.NET 10 SDK**; do not assume SDK 8/9 works.
- Generate config with **`dotnet-releaser new`** — do not hand-write TOML from README examples.
- There is **no offline changelog preview**. If your workflow needs local release-note drafting, pair `dotnet-releaser` with a separate changelog tool.

Pick a smaller tool if your pipeline already handles packaging, notes, and uploads. Otherwise this is a strong, .NET-native choice.
