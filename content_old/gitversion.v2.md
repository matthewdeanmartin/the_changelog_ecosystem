Title: GitVersion (hands-on synthesis)
Slug: gitversion-v2
Date: 2026-06-02
Ecosystem: Dotnet
Tags: ci-cd, dotnet, dotnet-tool-msbuild
Tool_URL: https://www.nuget.org/packages/GitVersion.Tool/
Tool_Version: 6.0.2
Experiment: examples/dotnet/gitversion/
Summary: Hands-on re-review after driving GitVersion through the tip-calculator life cycle.



## What I actually ran

The experiment lives at `examples/dotnet/gitversion/`. Base image: `mcr.microsoft.com/dotnet/sdk:8.0`. Tool version: `GitVersion.Tool 6.0.2` installed as a dotnet global tool.

The tip-calculator app is a minimal .NET 8 SDK-style console project (`.csproj` + `Program.cs`). Three versions were committed and tagged inside the container at `/work/app` — none of this touches the host repo.

Stages walked:

1. **No tag** — initial `feat:` commit, GitVersion computes a pre-release `0.1.0-1`.
2. **Tag v1.0.0** — immediately resolves to clean `1.0.0`; full JSON output captured.
3. **Feature commit** — `feat: split the bill evenly among diners` bumps to `1.1.0-1`; tagged `v1.1.0`.
4. **Breaking commit** — `feat!: split the bill unevenly by weight` bumps to `2.0.0-1`; tagged `v2.0.0`.

The "changelog equivalent" here is the JSON output GitVersion produces at each stage, since GitVersion is a version-calculator, not a changelog writer.

## Real output

### Stage 1 — after initial commit, before any tag

```
MajorMinorPatch = 0.1.0
SemVer          = 0.1.0-1
```

```json
{
  "FullSemVer": "0.1.0-1",
  "MajorMinorPatch": "0.1.0",
  "SemVer": "0.1.0-1",
  "CommitsSinceVersionSource": 1,
  "UncommittedChanges": 0
}
```

### Stage 2 — after `git tag v1.0.0`

```json
{
  "FullSemVer": "1.0.0",
  "MajorMinorPatch": "1.0.0",
  "SemVer": "1.0.0",
  "CommitsSinceVersionSource": 0,
  "InformationalVersion": "1.0.0+Branch.master.Sha.fd36aef..."
}
```

### Stage 3 — after `feat:` commit (minor bump)

```
MajorMinorPatch = 1.1.0
SemVer          = 1.1.0-1
```

The pre-release suffix `-1` signals "one commit ahead of the last tag". `MajorMinorPatch` is always the clean triple.

### Stage 4 — after `feat!:` commit (major bump) and `git tag v2.0.0`

Before tag:

```
MajorMinorPatch = 2.0.0
SemVer          = 2.0.0-1
```

After tag:

```json
{
  "FullSemVer": "2.0.0",
  "MajorMinorPatch": "2.0.0",
  "SemVer": "2.0.0",
  "CommitsSinceVersionSource": 0,
  "UncommittedChanges": 0
}
```

Final `gitversion.json` artifact confirms `2.0.0` with all 25 variables available for downstream use.

## Pros (observed)

- **Correct version derivation from commit messages.** `feat:` incremented minor, `feat!:` incremented major, exactly as Conventional Commits specifies. No ceremony — just commit message discipline.
- **`/showvariable` is excellent for scripting.** `dotnet-gitversion /showvariable MajorMinorPatch` prints only `1.1.0` with no JSON parsing. Perfect for CI shell steps.
- **25 variables in one shot.** A single invocation provides `AssemblySemVer`, `InformationalVersion`, `NuGetVersion`, `FullSemVer`, and many more. Most tools need several separate commands to get this breadth.
- **Zero-config baseline.** Without `GitVersion.yml`, the tool works sensibly with just tags, defaulting to patch-increment on the main branch.
- **Deterministic re-runs.** The same git history always produces the same version; the result is a pure function of the repo state.

## Cons / pain points (observed)

- **`mode: Mainline` was silently removed in v6.** The original article and most blog posts show `mode: Mainline` as the standard top-level setting. In 6.0.2 it fails with a cryptic `'Requested value 'Mainline' was not found.'` error. The valid per-branch modes are now `ContinuousDelivery`, `ManualDeployment`, and `ContinuousDeployment`. Finding this required trial-and-error because the v6 migration guide is not surfaced prominently. This will break any team upgrading from v5 with an existing config file.
- **Verbose INFO logging to stderr.** Every call emits ~8 lines of INFO diagnostics (working directory, DotGit path, cache file path, build-agent detection). These flood shell output and are hard to suppress without piping stderr or adding `/l /dev/null`. In a CI pipeline with 10 `dotnet-gitversion` calls this becomes noisy fast.
- **`SemVer` has a pre-release suffix between tags.** `SemVer = 1.1.0-1` is technically correct (one commit ahead of the source), but it can surprise teams who expect a clean version number between release cycles. Use `MajorMinorPatch` if you only want the triple.
- **`dotnet build -q` triggers "Question build" and exits non-zero.** This is a general MSBuild footgun, not GitVersion's fault, but it bit the experiment setup and is worth calling out for .NET container workflows.
- **`UncommittedChanges` counts build artifacts without `.gitignore`.** Without a `.gitignore` excluding `bin/` and `obj/`, the count inflates after every build. Trivial to fix but confusing if you don't know why `UncommittedChanges` jumps to 8.

## Docs vs. reality

The original `gitversion.md` correctly describes what GitVersion does — version computation, not changelog prose — and the JSON output shape shown in that article is accurate. The verdict ("Recommended for .NET projects") holds.

Where the original article diverges from the 2026 reality:

- It shows `mode: ContinuousDelivery` under a `branches:` key and a separate top-level `mode:` in the example snippet. The top-level `mode` key no longer exists in v6. The per-branch `mode` values it shows are still valid.
- It lists version `6.7.0` as the latest, but the stable 6.x release actually installable at time of experiment is `6.0.2`. The `6.7.0` number likely came from the docs-generation pass reading pre-release or future version data.
- The article says "first-run setup is moderate." This understates the v5→v6 migration friction. First-run on a fresh repo is easy; migration from a v5 config is a silent failure until you know what to look for.

## Revised verdict

**Verdict: Recommended — with a v6 migration warning**

GitVersion does exactly what it claims: reliable, deterministic SemVer from git history. The conventional-commit bump rules (`feat:` → minor, `feat!:` → major) worked perfectly in the experiment without any manual intervention. The `/showvariable` interface is genuinely useful for CI scripting.

The original verdict stands, but with one addition: teams upgrading from GitVersion v5 should read the v6 migration guide *before* upgrading in CI. The `mode: Mainline` removal is a silent breaking change that will fail builds with a non-obvious error message. New adopters starting on v6 from scratch will have an easier time.
