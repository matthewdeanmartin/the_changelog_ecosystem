Title: Nerdbank.GitVersioning (hands-on synthesis)
Slug: nerdbank-gitversioning-v2
Date: 2026-06-02
Ecosystem: Dotnet
Tags: ci-cd, dotnet, nuget-msbuild-dotnet-tool
Tool_URL: https://www.nuget.org/packages/Nerdbank.GitVersioning/
Tool_Version: 3.7.112
Experiment: examples/dotnet/nerdbank-gitversioning/
Summary: Hands-on re-review after driving nbgv through the tip-calculator life cycle.



## What I actually ran

The experiment lives at `examples/dotnet/nerdbank-gitversioning/`. Base image is
`mcr.microsoft.com/dotnet/sdk:8.0`; `nbgv` 3.7.112 is installed as a dotnet global tool
(`dotnet tool install -g nbgv --version 3.7.112`).

The tip-calculator scenario walks five stages inside the container's isolated git repo:

1. **Stage 1** — v1 `Program.cs` + `version.json` committed on `main`; `nbgv get-version`
   confirms height-based version.
2. **Stage 2** — v2 `Program.cs` (even split) committed; commit height increments.
3. **Stage 3** — `nbgv prepare-release` called; creates a `v1.0` release branch and bumps
   `version.json` to `1.1-alpha` on `main` with an auto-commit.
4. **Stage 4** — v3 `Program.cs` (weighted split) committed on main; version shows `1.1.x-alpha`.
5. **Stage 5** — `nbgv set-version 2.0` demonstrates a manual major bump; height resets to 1.

nbgv produces **no CHANGELOG.md**. It is version infrastructure. The "Real output" section
below shows version JSON in place of a changelog.


## Real output

### Stage 1 — first commit (`VersionHeight: 1`)

```
Version:                      1.0.1.62732
AssemblyVersion:              1.0.0.0
AssemblyInformationalVersion: 1.0.1+f50c1afe15
NuGetPackageVersion:          1.0.1
NpmPackageVersion:            1.0.1
```

The third segment is the commit height (1). The fourth segment (62732) is a
time-based offset — minutes since a reference epoch — not a sequential CI build counter.
`PublicRelease: true` because `main` matches `publicReleaseRefSpec`.

### Stage 2 — second commit (`VersionHeight: 2`)

```
Version:                      1.0.2.8713
NuGetPackageVersion:          1.0.2
VersionHeight: 2
```

Height incremented automatically; no configuration change needed.

### Stage 3 — after `nbgv prepare-release`

```
Version:                      1.1.1.30934
AssemblyInformationalVersion: 1.1.1-alpha+78d63ba7a1
NuGetPackageVersion:          1.1.1-alpha
```

`prepare-release` printed:

```
v1.0 branch now tracks v1.0 stabilization and release.
main branch now tracks v1.1-alpha development.
```

It created the `v1.0` branch at the current HEAD and committed a version.json change on
`main` setting `"version": "1.1-alpha"`. The `-alpha` prerelease suffix is now part of
every NuGet version string produced on `main` until explicitly removed.

### Stage 4 — v3 code on `1.1-alpha` main

```
NuGetPackageVersion:          1.1.2-alpha
VersionHeight: 2
```

### Stage 5 — after `nbgv set-version 2.0`

```
Version:                      2.0.1.10976
NuGetPackageVersion:          2.0.1
VersionHeight: 1
```

Height resets to 1 because changing `version.json` is the "anchor" for the height counter.

### Final `nbgv get-version -f json` (trimmed)

```json
{
  "SimpleVersion": "2.0.1",
  "VersionHeight": 1,
  "MajorMinorVersion": "2.0",
  "NuGetPackageVersion": "2.0.1",
  "AssemblyVersion": "2.0.0.0",
  "AssemblyInformationalVersion": "2.0.1+2ae0729aff",
  "PublicRelease": true,
  "BuildingRef": "refs/heads/main"
}
```

Full JSON is ~100 lines covering NuGet, npm, Chocolatey, AssemblyFileVersion,
AssemblyInformationalVersion, and every cloud-build variable name.


## Pros (observed)

- **Zero configuration friction for SDK-style projects.** Drop `version.json` in the
  repo, add the NuGet package reference, and every `dotnet build` stamps the assembly.
  The `nbgv` CLI works purely from git history with no build needed.

- **Commit height is automatic.** No human intervention required to increment the patch
  segment; every commit on the same major.minor naturally bumps it. This prevents
  the "forgot to bump the version" class of release mistakes.

- **`prepare-release` does the right thing out of the box.** One command creates the
  release branch, sets the next development prerelease on `main`, and commits — the
  whole branching ceremony in a single invocation.

- **JSON output is CI-pipeline-friendly.** Every version format a pipeline might need
  (NuGet, npm, Chocolatey, assembly, cloud-build export vars) is in one JSON blob.
  Parsing `SimpleVersion` or `NuGetPackageVersion` in a CI script is trivial.

- **`PublicRelease` is driven by branch/tag patterns**, not by a manual flag. Builds on
  unrecognized branches automatically get prerelease suffixes with the commit hash, which
  makes it safe to publish CI artifacts from feature branches without version collisions.


## Cons / pain points (observed)

- **`prepare-release` auto-commits, which breaks naive scripts.** The command commits
  the `version.json` bump on `main` itself (message: "Set version to '1.1-alpha'").
  Any script that tries to `git commit` after calling `prepare-release` will fail with
  "nothing to commit". The workaround is to guard the commit with a `git diff` check.
  This is not obvious from the docs.

- **The `-alpha` prerelease suffix survives `publicReleaseRefSpec`** after
  `prepare-release`. Even though `main` is in the public-release ref spec, the literal
  string `"1.1-alpha"` in `version.json` propagates into `NuGetPackageVersion`. This
  means CI builds on `main` will publish prerelease NuGet packages until you explicitly
  run `nbgv set-version 1.1` (dropping the suffix). The workflow is correct by design,
  but the interaction between `publicReleaseRefSpec` and the prerelease string in
  `version.json` is easy to misread.

- **The fourth version segment is time-based, not sequential.** `AssemblyFileVersion`
  shows `1.0.1.62732`; the last number is minutes-since-epoch, not a build counter.
  This is fine for `AssemblyFileVersion` (just needs to be monotonic), but it can alarm
  engineers who expect `1.0.1.0` as the first build.

- **No CHANGELOG.md, release notes, or commit-message parsing.** nbgv is explicitly not
  a changelog tool. Teams must separately adopt a tool like git-cliff, towncrier, or a
  manual Keep-a-Changelog workflow. The original article acknowledged this, but it is
  worth repeating because "release tool" is a phrase that attracts users expecting release
  notes generation.

- **PATH setup required for Docker/CI.** `dotnet tool install -g` puts the binary at
  `~/.dotnet/tools/`. Unless `PATH` is explicitly updated, `nbgv` is not found. The
  Dockerfile must add `ENV PATH="/root/.dotnet/tools:${PATH}"`. Easy to miss in
  container-based CI.


## Docs vs. reality

The original `nerdbank-gitversioning.md` described nbgv accurately:

- "stamps .NET builds with Git-derived version information" — confirmed.
- "Computes versions from Git commits and tags" — confirmed; specifically commit height.
- "Provides the `nbgv` CLI for inspection and release tasks" — confirmed; `prepare-release`
  and `set-version` worked exactly as advertised.
- "It has no opinion about release-note wording" — confirmed; no CHANGELOG, no fragments,
  no commit parsing.

Where the original review undersold:

- The `prepare-release` auto-commit behavior is not mentioned. It is a workflow gotcha that
  any CI script author will hit immediately.
- The `-alpha` suffix and its interaction with `publicReleaseRefSpec` is important for teams
  who want clean NuGet versions on `main` immediately after `prepare-release`.
- The time-based fourth segment is worth a sentence.

Where the original review was accurate but more important in practice:

- "Should be paired with a changelog or release-note tool" is correct and understated.
  In practice every team using nbgv needs to answer "how do we produce human-readable
  release notes?" as a separate, explicit decision.


## Revised verdict

**Verdict: Recommended — unchanged, with caveats**

The run confirmed that nbgv delivers exactly what it promises: reproducible, Git-derived
version stamping with minimal configuration. `prepare-release` is genuinely useful for
teams that want a structured release/development branch split.

The two caveats worth adding to the original verdict:

1. The `prepare-release` auto-commit is a gotcha for automation scripts. Document it in
   your CI pipeline comments.
2. After `prepare-release`, `main` emits prerelease NuGet packages (e.g. `1.1.2-alpha`)
   until you call `nbgv set-version <version>` without a prerelease qualifier. Teams that
   want clean NuGet versions on `main` need one additional step.

Neither caveat changes the recommendation. nbgv remains the right choice for .NET
library or tool authors who want deterministic, MSBuild-integrated versioning from git
history.
