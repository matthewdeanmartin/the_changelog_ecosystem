# GitVersion Experiment Notes

Tool: dotnet-gitversion    Status: done
Base image: mcr.microsoft.com/dotnet/sdk:8.0
Tool version: 6.0.2

## Checklist

- [x] Dockerfile installs GitVersion.Tool 6.0.2 + git on mcr.microsoft.com/dotnet/sdk:8.0
- [x] app/ is the tip calculator (.csproj + Program.cs), runs & prints
- [x] scenario/ has GitVersion.yml (conventional-commit bump rules, no top-level mode)
- [x] run_experiment.sh walks all life-cycle stages, commits/tags in /work/app
- [x] make run completes end-to-end with only Docker installed
- [x] out/ contains gitversion.json + git-log.txt + git-tags.txt + transcript.txt
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + pros/cons captured below
- [x] content/articles/gitversion.v2.md written, grounded in the run

## Key findings

### Version 6.x config schema change (blocker)

The biggest friction: the original article config used `mode: Mainline` as a top-level
key, but GitVersion 6.x removed `Mainline` as a valid top-level mode. Running with that
config produces:

    WARN: Could not build the configuration instance because following exception occurred:
    'Requested value 'Mainline' was not found.'

In v6, `mode` is a per-branch setting only, and the valid values are `ContinuousDelivery`,
`ManualDeployment`, and `ContinuousDeployment`. The working config uses only bump-message
regex keys and a per-branch `increment` override.

### dotnet build -q causes "Question build" failure

Passing `-q` to `dotnet build` triggers MSBuild's "Question" mode (up-to-date check only,
exits non-zero if anything needs rebuilding). Use `--nologo -v minimal` instead.

### Version progression observed

| State                         | MajorMinorPatch | SemVer       |
|-------------------------------|-----------------|--------------|
| After initial commit, no tag  | 0.1.0           | 0.1.0-1      |
| After `git tag v1.0.0`        | 1.0.0           | 1.0.0        |
| After `feat:` commit          | 1.1.0           | 1.1.0-1      |
| After `git tag v1.1.0`        | 1.1.0           | 1.1.0        |
| After `feat!:` commit         | 2.0.0           | 2.0.0-1      |
| After `git tag v2.0.0`        | 2.0.0           | 2.0.0        |

`SemVer` includes a pre-release suffix (`-1`) between tags. `MajorMinorPatch` is always
clean. `FullSemVer` without a tag: `0.1.0-1`; after tag: `1.0.0`.

### JSON output is rich but chatty

GitVersion outputs ~25 fields per invocation including AssemblySemVer, FullBuildMetaData,
InformationalVersion, EscapedBranchName, etc. Most CI use-cases only need 3-4 of them.
The `/showvariable` flag cleanly extracts one value for scripting.

### INFO log noise on stderr

Every invocation prints 8+ INFO lines to stderr about working directory, DotGit path,
branch detection, and cache file lookups. Redirecting stderr or using `/l /dev/null` hides
it, but it makes simple shell invocations messy.

## Transcript (excerpt)

```
tool under test:
6.0.2+Branch.main.Sha.30211316bc16e481dc440baae39ff904c4fa4966

==================== STAGE 1: v1 code committed — no tag yet ====================

program output:
Bill:  $85.00
Tip:   $15.30 (18.0%)
Total: $100.30

computed version before any tag:
  MajorMinorPatch = 0.1.0
  SemVer = 0.1.0-1

==================== STAGE 2: tag v1.0.0 — show full gitversion JSON ====================

tagged v1.0.0
  MajorMinorPatch = 1.0.0
  SemVer = 1.0.0

==================== STAGE 3: feat commit (even split) — expect minor bump to 1.1.0 ====================

program output:
Bill:        $85.00
Tip:         $15.30 (18.0%)
Total:       $100.30
Diners:      4
Per person:  $25.08

  MajorMinorPatch = 1.1.0
  SemVer = 1.1.0-1

==================== STAGE 4: feat! commit (uneven split by weight) — expect major bump to 2.0.0 ====================

program output:
Bill:  $85.00
Tip:   $15.30 (18.0%)
Total: $100.30

Per-person breakdown (weighted):
  Alice  (weight 3.0): $42.99
  Bob    (weight 2.0): $28.66
  Carol  (weight 1.0): $14.33
  Dave   (weight 1.0): $14.33

  MajorMinorPatch = 2.0.0
  SemVer = 2.0.0-1

tagged v2.0.0
  MajorMinorPatch = 2.0.0
  SemVer = 2.0.0

GIT LOG:
0e91967 (HEAD -> master, tag: v2.0.0) feat!: split the bill unevenly by weight
8bb277d (tag: v1.1.0) feat: split the bill evenly among diners
fd36aef (tag: v1.0.0) feat: compute tip for a single bill
```
