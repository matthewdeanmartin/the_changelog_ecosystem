# .NET tool experiments

Six .NET changelog/release tools, each driven through the tip-calculator life cycle (or to its offline failure boundary) in Docker.
Run any experiment with `make run` from its directory. Artifacts land in `out/`.

## Results (run date: 2026-06-02)

| Tool | Version | Outcome | Headline finding |
|------|---------|---------|-----------------|
| [versionize](versionize/) | 2.5.0 | ✅ Full success | One command handles Conventional Commits → version bump in `.csproj` → CHANGELOG.md prepend → git commit + tag. `feat!:` correctly triggers major bump. Breaking-change commit appears in **both** `### Features` and `### Breaking Changes` (duplication). Output uses HTML `<a name>` anchors, not pure KAC format. |
| [gitversion](gitversion/) | 6.0.2 | ✅ Full success | Correctly computes version from git history: `feat:` → minor bump, `feat!:` → major bump, pre-release `-1` suffix between tags. Does **not** write CHANGELOG.md — version metadata only. v6.x removed `mode: Mainline` as a top-level config key; per-branch `increment` is the replacement. INFO log noise on stderr. |
| [nerdbank-gitversioning](nerdbank-gitversioning/) | 3.7.112 | ✅ Full success | Commit-height versioning (`1.0.1`, `1.0.2`, …) from `version.json`. `nbgv prepare-release` auto-commits a version bump on `main` and creates a stabilization branch. Does **not** write CHANGELOG.md. The fourth `AssemblyFileVersion` segment is time-based, not a sequential build counter. `-alpha` prerelease suffix survives `publicReleaseRefSpec` until explicitly cleared. |
| [gitreleasemanager](gitreleasemanager/) | 0.20.0 | ❌ CI-only | Every subcommand (`create`, `publish`, `close`, `export`) fails immediately with `Required option 'token' is missing.` — no offline mode exists. Correct NuGet package ID is **`gitreleasemanager.tool`** (not `GitReleaseManager`). `export` reads from the GitHub Releases API, not local git history. |
| [gitreleasenotes](gitreleasenotes/) | 0.7.1 | ❌ Uninstallable | `dotnet tool install` fails: package lacks `DotnetToolSettings.xml` (pre-.NET Core 2.1 format). The tool cannot be installed on any modern .NET SDK. Completely unusable. |
| [dotnet-releaser](dotnet-releaser/) | 0.21.0 | ⚠️ Build only | **Requires .NET 10 SDK** (not 8 or 9 — ships at `tools/net10.0/any/`). `dotnet-releaser build` works offline and cross-compiles for 9 platforms (NuGet + win/linux/osx x64+arm64). `changelog` and `run` require `--github-token` immediately — no local path. Fake git remote required to avoid `NullReferenceException`. |

## Recommended by use case

- **Conventional Commits → CHANGELOG.md + version bump (.NET library):** versionize — zero-config for standard workflows
- **SemVer computation from git history (CI variables, MSBuild integration):** GitVersion or Nerdbank.GitVersioning
  - GitVersion: branching-model-aware, richer config, `feat:`/`feat!:` rules
  - nbgv: commit-height model, MSBuild-integrated, `prepare-release` branch workflow
- **Cross-platform binary packaging + NuGet publishing (GitHub Actions):** dotnet-releaser `build` for artifacts, `run` for publishing
- **GitHub milestone-based release notes:** GitReleaseManager (CI only — requires GitHub token)
- **Legacy tracker-based notes:** GitReleaseNotes — do not use (uninstallable on .NET 5+)

## Key gotchas

- **versionize duplicates breaking-change commits.** A `feat!:` commit appears in both `### Features` and `### Breaking Changes`. There is no config to suppress the Features entry.
- **versionize uses HTML anchors, not KAC format.** Headers look like `## 2.0.0 (2026-06-02)` with `<a name="2.0.0"></a>`, not `## [2.0.0] - 2026-06-02`. The original article called it "Keep a Changelog-like" which is generous.
- **GitVersion 6.x removed `mode: Mainline`.** The top-level `mode` key is gone; use per-branch `increment` settings instead. Configs from v5 docs silently produce a `Requested value 'Mainline' was not found` warning.
- **nbgv `prepare-release` auto-commits on `main`.** It makes its own git commit (message: `Set version to '1.1-alpha'`). Any `git add -A && git commit` immediately after will fail with "nothing to commit".
- **nbgv `-alpha` suffix survives `publicReleaseRefSpec`.** After `prepare-release`, the prerelease string in `version.json` propagates into `NuGetPackageVersion` even on a public-release branch. Clear it explicitly with `nbgv set-version`.
- **GitReleaseManager NuGet ID is `gitreleasemanager.tool`.** Installing `GitReleaseManager` (without `.tool`) fails with an opaque `DotnetToolSettings.xml` error — same error message as a framework mismatch.
- **GitReleaseNotes is uninstallable on modern .NET SDK.** The package predates the dotnet global tool manifest format. It cannot be installed with `dotnet tool install` on .NET 5+.
- **dotnet-releaser 0.21.0 requires .NET 10 SDK.** Using SDK 8 or 9 produces the same `DotnetToolSettings.xml not found` error as GitReleaseNotes — the symptom looks like corruption but is actually a TFM mismatch.
- **dotnet-releaser `build` needs a git remote (even fake).** Without any remote configured, `build` crashes with `NullReferenceException` at startup. `git remote add origin https://github.com/placeholder/placeholder.git` is enough.
- **dotnet-releaser `build` + `run` conflict without `--force`.** Running `build` then `run` in the same workspace fails: `artifacts folder already exists`. Pass `--force` to `run` or clean between calls.
