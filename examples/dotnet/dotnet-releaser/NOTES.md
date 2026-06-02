# dotnet-releaser — Experiment Notes

## Run date

2026-06-02

## Container

- Base image: `mcr.microsoft.com/dotnet/sdk:10.0`
- Tool: `dotnet-releaser` 0.21.0
- App: `TipCalc` .NET 10 console project (net10.0)

## Key findings

### 1. The NuGet package requires .NET 10 SDK

Version 0.21.0 ships binaries at `tools/net10.0/any/`. Installing it with
`dotnet tool install` on SDK 8.0 or SDK 9.0 produces:

```
The settings file in the tool's NuGet package is invalid:
Settings file 'DotnetToolSettings.xml' was not found in the package.
```

The problem is that the SDK cannot find the settings file because it does not
look in `net10.0` sub-directories when the SDK itself is 8.0 or 9.0. Switching
to `mcr.microsoft.com/dotnet/sdk:10.0` fixes this.

### 2. TOML format is stricter than the README suggests

The documented TOML examples use `[[nuget]]` and `[[msbuild]]` (array-of-tables
syntax). The actual parser expects singular tables:

```toml
[msbuild]
project = "TipCalc.csproj"

[github]
user = "testuser"
repo = "testrepo"
```

Using array-of-tables syntax produces:
```
ERR  Unexpected exception while trying to load configuration.
     Reason: Expected StartTable token but was StartArray.
```

The safest way to generate a valid config is `dotnet-releaser new --project
<csproj> --user <owner> --repo <repo>`. This also revealed the `[github]`
section uses `user` (not `owner` as some docs say).

### 3. A fake git remote is required to avoid a NullReferenceException

Without a configured git remote, `dotnet-releaser build` crashes with:

```
Unexpected error System.NullReferenceException: Object reference not set
to an instance of an object.
   at DotNetReleaser.GitInformation.Create(...)
```

Adding `git remote add origin https://github.com/test/test.git` (even a
non-resolvable URL) eliminates the crash and lets the build proceed.

### 4. `dotnet-releaser build` works locally — and does a lot

With a committed git repo + fake remote + `[msbuild]`+`[github]` config, `build`
successfully:

- Restores + compiles via MSBuild in Release mode
- Creates a NuGet package (`.nupkg`)
- Cross-compiles and packages for **9 targets**: win-x64/arm64 (zip),
  linux-x64/arm64 (rpm, deb, tar.gz), osx-x64/arm64 (tar.gz)

All of this happens without any GitHub or NuGet token. The build step is
genuinely local. It stops (successfully) after packaging with no error about
missing tokens — the token requirement only kicks in for the publish/release
steps.

### 5. `dotnet-releaser run` fails with an artifacts-collision error, not an auth error

After `build` created `artifacts-dotnet-releaser/`, running `run` without
`--force` fails with:

```
ERR  The artifacts folder `/work/repo/artifacts-dotnet-releaser` already
     exists. Use `--force` to delete/recreate this folder during a
     `build`/`publish`.
```

This is a UX friction point: running both `build` and then `run` in the same
workspace without `--force` breaks.

### 6. `dotnet-releaser changelog` requires `--github-token` immediately

```
ERR  Missing required option `--github-token`.
```

No offline path exists for the changelog command. Release notes are sourced
exclusively from GitHub PRs and commits via the API.

### 7. `dotnet-releaser run` is for GitHub Actions, not local use

The `--help` text states: "Automatically build and publish a project when
running from a GitHub Action based on which branch is active, if there is a
tag (for publish), and if the change is a push." It is explicitly a CI command.

## Artifact output from `dotnet-releaser build`

```
artifacts-dotnet-releaser/
  TipCalc.1.0.0.nupkg
  TipCalc.1.0.0.win-x64.zip
  TipCalc.1.0.0.win-arm64.zip
  TipCalc.1.0.0.linux-x64.rpm
  TipCalc.1.0.0.linux-x64.deb
  TipCalc.1.0.0.linux-x64.tar.gz
  TipCalc.1.0.0.linux-arm64.rpm
  TipCalc.1.0.0.linux-arm64.deb
  TipCalc.1.0.0.linux-arm64.tar.gz
  TipCalc.1.0.0.osx-x64.tar.gz
  TipCalc.1.0.0.osx-arm64.tar.gz
```

## Full transcript

See `out/transcript.txt` after running `make run`. Key excerpt:

```
2026-06-02 14:30:19 INF  Building `/work/repo/TipCalc.csproj` - Configuration = Release
2026-06-02 14:30:20 INF  Building NuGet Package - TipCalc
2026-06-02 14:30:23 INF  NuGet Package built: TipCalc.1.0.0.nupkg
...
2026-06-02 14:30:23 INF  Building target platform [win-x64] / [zip] package
2026-06-02 14:30:47 INF  Build successful ... TipCalc.1.0.0.win-x64.zip
... (8 more platform packages)
2026-06-02 14:33:15 ERR  Missing required option `--github-token`.
```
