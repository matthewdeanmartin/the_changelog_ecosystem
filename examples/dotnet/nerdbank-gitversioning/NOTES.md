# NOTES — nerdbank-gitversioning experiment

## Run date
2026-06-02

## Container
- Base image: `mcr.microsoft.com/dotnet/sdk:8.0`
- Tool: `nbgv` 3.7.112 (installed via `dotnet tool install -g nbgv --version 3.7.112`)
- git version: Debian bookworm package

## What ran
Five stages:

1. **SETUP**: `git init` + `git checkout -b main`; nbgv confirmed as 3.7.112+63bbe780b0.
2. **Stage 1**: v1 code + `version.json` committed. `nbgv get-version` shows `1.0.1`
   (commit height = 1, first commit since version.json was added).
3. **Stage 2**: v2 Program.cs committed. Height becomes 2 → `1.0.2`.
4. **Stage 3**: `nbgv prepare-release` called. It:
   - Created a `v1.0` branch pointing at the current HEAD.
   - Committed a version.json change on `main` bumping to `1.1-alpha`.
   - Printed: "v1.0 branch now tracks v1.0 stabilization and release. main branch now tracks v1.1-alpha development."
   - The commit was already made by prepare-release; no additional commit needed.
5. **Stage 4**: v3 code committed on main. Version shows `1.1.2-alpha`.
6. **Stage 5**: `nbgv set-version 2.0` — updates version.json to `2.0`; after commit shows `2.0.1`.

## Key observed outputs

### Stage 1 — first commit
```
Version:                      1.0.1.62732
AssemblyVersion:              1.0.0.0
AssemblyInformationalVersion: 1.0.1+f50c1afe15
NuGetPackageVersion:          1.0.1
```
- The "fourth" segment (62732) is derived from a date-based offset, not a sequential build number.
- `PublicRelease: true` because we are on `main` which matches the `publicReleaseRefSpec`.
- `VersionHeight: 1` confirms this is commit #1 since version.json was introduced.

### Stage 2 — second commit
```
Version:                      1.0.2.8713
NuGetPackageVersion:          1.0.2
VersionHeight: 2
```
- Height incremented as expected. NuGetPackageVersion is clean (no prerelease suffix)
  because `PublicRelease: true` (main branch).

### Stage 3 — after prepare-release
```
Version:                      1.1.1.30934
AssemblyInformationalVersion: 1.1.1-alpha+78d63ba7a1
NuGetPackageVersion:          1.1.1-alpha
```
- The `-alpha` prerelease suffix was added because prepare-release sets `"version": "1.1-alpha"`.
- Despite being on `main` (which is in publicReleaseRefSpec), the prerelease suffix from
  version.json propagates. PublicRelease still shows `true` but the prerelease string is respected.

### Stage 4 — v3 code on 1.1-alpha main
```
Version:                      1.1.2-alpha
VersionHeight: 2
```

### Stage 5 — after set-version 2.0
```
Version:                      2.0.1.10976
NuGetPackageVersion:          2.0.1
VersionHeight: 1
```
- Height resets to 1 because version.json changed (that commit is the new "anchor").

### Final git log
```
2ae0729 (HEAD -> main) chore: bump to 2.0 for breaking change release
ea4a27c feat!: split the bill unevenly by weight
78d63ba Set version to '1.1-alpha'
220992f (v1.0) feat: split the bill evenly among diners
f50c1af feat: compute tip for a single bill
```

## Pain points / observations

1. **No CHANGELOG.md generated**: nbgv is purely version infrastructure. It produces
   no human-readable release notes. This must be called out clearly; docs say so, but
   it can be easy to conflate "release tool" with "release notes tool".

2. **prepare-release auto-commits**: `nbgv prepare-release` makes its own git commit on
   `main` (message: "Set version to '1.1-alpha'"). Trying to `git add -A && git commit`
   afterward fails with "nothing to commit". The experiment script must guard this.

3. **The prerelease suffix survives publicReleaseRefSpec**: After `prepare-release`,
   `main` gets `"version": "1.1-alpha"` in version.json. Despite the branch being in
   `publicReleaseRefSpec`, the `-alpha` suffix remains in NuGetPackageVersion. Removing
   it requires another explicit `nbgv set-version` or `prepare-release` cycle.

4. **Fourth version segment**: The `AssemblyFileVersion` fourth segment (e.g. `1.0.1.62732`)
   is a time-based offset (minutes since a reference epoch), not a sequential CI build
   counter. This confused the first read of the output.

5. **`nbgv --version` prints the version of nbgv itself**, not the project version.
   The tool version was `3.7.112+63bbe780b0` — the `+hash` suffix is nbgv's own
   informational version (built from its own version.json, naturally).

6. **JSON output is exhaustive**: `nbgv get-version -f json` dumps ~100 lines of JSON
   covering every possible format (NuGet, npm, Chocolatey, AssemblyVersion, cloud-build
   vars). Excellent for CI pipelines; overwhelming for first-time users.

7. **PATH setup required**: Installing as a dotnet global tool puts the binary at
   `~/.dotnet/tools/nbgv`. The Dockerfile must explicitly add this to PATH via
   `ENV PATH="/root/.dotnet/tools:${PATH}"`.

## Verdict adjustment
Original article said "Recommended". After running, this remains accurate but with the
caveat that the `-alpha` prerelease suffix behavior after `prepare-release` is a
gotcha not highlighted in the original review. Also the fourth version segment being
time-based (not sequential) is worth documenting.
