Title: dotnet-releaser (hands-on synthesis)
Slug: dotnet-releaser-v2
Date: 2026-06-02
Ecosystem: Dotnet
Tool_Version: 0.21.0
Experiment: examples/dotnet/dotnet-releaser/
Summary: Hands-on probe of dotnet-releaser's offline capabilities and GitHub API dependencies.



## What I actually ran

Experiment directory: `examples/dotnet/dotnet-releaser/`

- Base image: `mcr.microsoft.com/dotnet/sdk:10.0` (not 8.0 — see below)
- Tool: `dotnet-releaser` 0.21.0
- App fixture: a minimal .NET 10 console project (`TipCalc`) taken through
  three versions (tip calculation → even split → weighted split)
- Git history: 3 commits + 3 tags (`v1.0.0`, `v2.0.0`, `v3.0.0`) in an
  ephemeral container repo at `/work/repo`

The experiment probed which sub-commands execute locally without GitHub or
NuGet credentials: `--version`, `--help`, `new`, `build`, `run`, and
`changelog`.

---

## Real output

### `dotnet-releaser new` (works fully offline)

```
2026-06-02 14:30:15 INF  New configuration file `/work/repo/dotnet-releaser.toml`
                          created successfully.
```

Generated `dotnet-releaser.toml`:

```toml
# configuration file for dotnet-releaser
[msbuild]
project = "TipCalc.csproj"
[github]
user = "test"
repo = "test"
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
2026-06-02 14:31:08 INF  Building target platform [linux-x64]   / [rpm] ...
2026-06-02 14:31:38 INF  Build successful: TipCalc.1.0.0.linux-x64.rpm
2026-06-02 14:31:38 INF  Building target platform [linux-x64]   / [deb] ...
2026-06-02 14:31:47 INF  Build successful: TipCalc.1.0.0.linux-x64.deb
2026-06-02 14:31:47 INF  Building target platform [linux-x64]   / [tar] ...
2026-06-02 14:31:49 INF  Build successful: TipCalc.1.0.0.linux-x64.tar.gz
2026-06-02 14:31:49 INF  Building target platform [linux-arm64] / [rpm] ...
2026-06-02 14:32:20 INF  Build successful: TipCalc.1.0.0.linux-arm64.rpm
2026-06-02 14:32:20 INF  Building target platform [linux-arm64] / [deb] ...
2026-06-02 14:32:30 INF  Build successful: TipCalc.1.0.0.linux-arm64.deb
2026-06-02 14:32:30 INF  Building target platform [linux-arm64] / [tar] ...
2026-06-02 14:32:32 INF  Build successful: TipCalc.1.0.0.linux-arm64.tar.gz
2026-06-02 14:32:32 INF  Building target platform [osx-x64]   / [tar] ...
2026-06-02 14:32:54 INF  Build successful: TipCalc.1.0.0.osx-x64.tar.gz
2026-06-02 14:32:54 INF  Building target platform [osx-arm64] / [tar] ...
2026-06-02 14:33:15 INF  Build successful: TipCalc.1.0.0.osx-arm64.tar.gz
```

`build` completed successfully and produced **11 artifacts** (1 NuGet package +
10 cross-compiled distribution packages) with no GitHub token.

### `dotnet-releaser changelog` (requires token immediately)

```
2026-06-02 14:33:38 ERR  Missing required option `--github-token`.
```

### `dotnet-releaser run` (artifacts-folder conflict after prior build)

```
2026-06-02 14:33:15 ERR  The artifacts folder `/work/repo/artifacts-dotnet-releaser`
                          already exists. Use `--force` to delete/recreate this
                          folder during a `build`/`publish`.
```

---

## Pros (observed)

- **`build` does real work locally.** Without any token it restores, compiles,
  packs the NuGet package, and cross-compiles for 9 targets (Windows x64/arm64,
  Linux x64/arm64, macOS x64/arm64). The breadth of platform coverage from a
  single command is impressive and unexpected.
- **`new` generates a valid config without needing a git remote or GitHub
  credentials.** Pass `--project`, `--user`, and `--repo` and you get a working
  TOML in one command.
- **Structured, timestamped logging.** The `INF`/`ERR` lines are readable and
  machine-parseable; failures are clearly surfaced.
- **Explicit help text.** Sub-command help accurately describes token
  requirements and CI-only semantics, so there is no ambiguity about what each
  command needs.

---

## Cons / pain points (observed)

- **Requires .NET 10 SDK, not 8.0.** The 0.21.0 package ships binaries at
  `tools/net10.0/any/`. Using SDK 8.0 or 9.0 produces a cryptic error ("Settings
  file 'DotnetToolSettings.xml' was not found in the package") rather than a
  clear "requires .NET 10" message. The NuGet page and README do not prominently
  call out this requirement.

- **Config format is poorly documented.** The README shows `[[nuget]]` and
  `[[msbuild]]` (TOML array-of-tables). The actual parser requires singular
  `[msbuild]` and `[github]` tables and the `[github]` section uses `user` (not
  `owner`). Using the wrong format produces a terse parse error. The `new`
  sub-command is the only reliable way to get a valid config.

- **`build` crashes with NullReferenceException without a git remote.** If the
  project directory has no git remote configured, `GitInformation.Create` throws
  an unhandled exception with a full stack trace. The tool should produce a
  friendly error instead. Adding a fake remote (even a non-resolvable URL) works
  around this.

- **`run` fails with an artifacts-collision error, not a useful "use --force"
  guidance in the happy path.** If `build` was run first, `run` cannot proceed
  without `--force`. The error message mentions `--force` but a developer
  running `build` then `run` in a local workflow will hit this on every
  iteration.

- **No changelog/release notes without GitHub.** All three release-facing
  commands (`run`, `changelog`, `publish`) require `--github-token`. There is no
  `--dry-run` that shows what release notes would look like, no local Markdown
  output mode, and no way to preview the changelog without a live API token.
  The tool is entirely dependent on GitHub as the source of truth for change
  history.

- **Build is slow for a quick local test.** Cross-compiling for 9 platforms takes
  3+ minutes even for a trivial project. There is a
  `--skip-app-packages-for-build-only` flag that skips the platform packages
  during build-only runs, but it is not the default and is not mentioned
  prominently.

---

## Docs vs. reality

The original `dotnet-releaser.md` article described the tool accurately in broad
strokes: "one command that understands common .NET release chores" and "strong
fit for .NET libraries distributed through NuGet and GitHub Releases." That
holds up.

Two places where the original article underspecified or missed:

1. **SDK version requirement.** The article lists "Latest version: 0.21.0" but
   does not note that 0.21.0 targets `net10.0`. A team on SDK 8.0 will hit an
   opaque install failure.

2. **`build` is more capable locally than the article suggests.** The original
   framing ("heavier than GitVersion if you only need version calculation")
   implies `dotnet-releaser` is CI-only. In practice, `build` is a genuine
   local cross-compilation tool that produces distribution-ready packages without
   any GitHub contact. That is worth calling out for teams that want local
   preview builds.

---

## Revised verdict

**Verdict: Recommended — with one important caveat**

The tool does exactly what it claims: it is a cohesive .NET release orchestrator
for teams that publish to both NuGet and GitHub Releases. The `build` sub-command
is more useful locally than the "CI-only" characterization implied — it produces
cross-platform distribution packages without any credentials.

The caveats are:

- Pin to .NET 10 SDK in your container/CI; do not assume SDK 8+ works.
- Use `dotnet-releaser new` to generate the config — do not hand-write TOML
  based on README examples, which show the wrong table syntax.
- There is no offline changelog preview. If your workflow needs local release
  note drafting, pair `dotnet-releaser` with a separate changelog tool.

The original "Recommended" verdict stands; this run adds specificity about
the SDK floor and the practical reach of the `build` command.
