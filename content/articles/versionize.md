Title: versionize
Date: 2026-06-02
Slug: versionize
Ecosystem: Dotnet
Tags: conventional-commits, dotnet, dotnet-tool, keep-a-changelog, semantic-versioning, hands-on
Tool_URL: https://www.nuget.org/packages/versionize/
Tool_Version: 2.5.0
Tool_Status: active
Experiment: examples/dotnet/versionize/
Summary: .NET tool for automatic versioning and CHANGELOG generation from Conventional Commits; hands-on testing confirms a clean one-command release loop, with a few changelog-format quirks.



## Overview

`versionize` brings a Conventional Commits release workflow to .NET projects. It determines the next semantic version, updates project/package metadata, and writes `CHANGELOG.md` entries from commit history.

It is a good fit when the team wants a focused version-and-changelog tool rather than a full release publisher.

A reproducible hands-on experiment for this tool lives in [`examples/dotnet/versionize/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/versionize).

## Installation

```bash
dotnet tool install -g versionize
```

## What It Does

- Parses Conventional Commits.
- Determines major, minor, and patch version bumps.
- Updates .NET project version metadata (rewrites the `<Version>` element in `.csproj`).
- Writes or updates `CHANGELOG.md`.
- Creates the release commit (`chore(release): X.Y.Z`) and tags the release as part of the workflow.

## Configuration

`versionize` works with minimal configuration when the project already uses Conventional Commits — in testing, zero config files were needed for a single-project repo.

```bash
versionize --dry-run    # preview the proposed bump + changelog section
versionize              # bump, write CHANGELOG.md, commit, and tag
```

Requirements observed in testing: the `.csproj` must have a `<Version>` element, the working tree must be clean before running, and there must be at least one `fix:`/`feat:`/`feat!:` commit since the last tag for the tool to do anything. The main setup requirement is commit discipline — without Conventional Commits, the version bump and changelog categories will be unreliable.

## Ecosystem Fit

`versionize` feels native for .NET libraries because it is distributed as a .NET tool and understands project versioning. It is smaller and easier to adopt than an all-in-one publisher.

It does not replace a GitHub Release uploader, artifact publisher, or NuGet publishing pipeline by itself.

## Maintenance Status

- Latest version: **2.5.0**
- Last release: **2026-02-01**
- GitHub stars: **373**
- Appears actively maintained.
- Repository: <a href="https://github.com/versionize/versionize" target="_blank" rel="noopener noreferrer">https://github.com/versionize/versionize</a>

The release metadata is current enough to treat it as an active .NET option.

---

## Hands-on findings

The notes below come from driving `versionize` 2.5.0 through a real life cycle in an offline Docker container (`mcr.microsoft.com/dotnet/sdk:8.0`). A minimal "tip calculator" .NET project was taken through fix, feature, and breaking-change releases in an isolated git repo. The full transcript is in [`examples/dotnet/versionize/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/versionize).

The bump sequence followed SemVer strictly from commit types: `v1.0.0` → `fix:` → `1.0.1` → `feat:` → `1.1.0` → `feat!:` → `2.0.0`.

### First run (1.0.0 → 1.0.1) — one command does everything

```
Discovered 1 versionable projects
  * /work/app/TipCalc.csproj
√ bumping version from 1.0.0 to 1.0.1 in projects
√ updated CHANGELOG.md
√ committed changes in projects and /work/app/CHANGELOG.md
√ tagged release as v1.0.1 against commit with sha 6ad3a1c...
```

Resulting `CHANGELOG.md`:

```markdown
# Change Log

All notable changes to this project will be documented in this file. See [versionize](https://github.com/versionize/versionize) for commit guidelines.

<a name="1.0.1"></a>
## 1.0.1 (2026-06-02)

### Bug Fixes

* remove trailing whitespace in output
```

### Breaking change (`feat!:` → 2.0.0)

```markdown
<a name="2.0.0"></a>
## 2.0.0 (2026-06-02)

### Features

* split the bill unevenly by weight

### Breaking Changes

* split the bill unevenly by weight
```

### Dry-run

```
√ bumping version from 2.0.0 to 2.0.1 in projects

---
<a name="2.0.1"></a>
## 2.0.1 (2026-06-02)

### Bug Fixes

* add end-of-file comment
---
```

The dry-run printed the proposed section to stdout and exited without writing files or committing.

### Pros (observed)

- **Zero configuration required.** Ran against a plain `.csproj` with a `<Version>` element and a Conventional-Commits git repo — no config file.
- **Accurate SemVer logic.** `fix:` → patch, `feat:` → minor, `feat!:` → major, all correct without tuning.
- **One command does everything:** bump `.csproj`, prepend the changelog section, create the release commit, and tag — no separate steps.
- **Dry-run is genuinely useful** for CI preview jobs.
- **Clear, checkmark-prefixed terminal output** makes each step obvious.
- **Discovers all projects** (`Discovered N versionable projects`), suggesting multi-project solutions work without extra flags.

### Cons / pain points (observed)

- **`--no-verify` does not exist** in 2.5.0 (despite appearing in some flag lists). No built-in way to bypass commit hooks; work around with git config or hook tweaks.
- **Breaking-change entries are duplicated.** A `feat!:` commit appears under *both* `### Features` and `### Breaking Changes` — noisy, and arguably it should appear only under Breaking Changes.
- **HTML `<a name="…">` anchors instead of pure Markdown.** Works in most renderers but trips strict Markdown linters.
- **Not strictly Keep a Changelog-compliant.** Output uses `## 2.0.0 (2026-06-02)` and `### Bug Fixes`/`### Breaking Changes`, not the canonical `## [2.0.0] - 2026-06-02` / `### Fixed`. The original article's "Keep a Changelog-like shape" qualifier is doing a lot of work.
- **Requires commits after the most recent tag** — nothing to process otherwise.
- **No `--changelog-all` in 2.5.0.** Commit types outside `fix`/`feat`/breaking (e.g. `chore:`, `docs:`, `refactor:`) do not appear, with no flag in this version to include them.

### Docs vs. reality

The original article's example used a hand-written `## [2.5.0] - 2026-02-01` / `### Bug Fixes` block; the real output uses `## 2.5.0 (2026-06-02)` with HTML anchors — a mild oversell. The breaking-change major-bump claim and the minimal-configuration claim were both confirmed exactly.

## Verdict

**Verdict: Recommended (with caveats)**

The hands-on run confirms the core promise: point `versionize` at a .NET project with Conventional Commits and it handles the full release loop (version bump, changelog, commit, tag) in one command with no configuration file. The most notable friction points are the `feat!:` duplication in the changelog and the non-standard HTML anchors — neither a blocker, but teams that care about changelog polish will likely post-process the output.

Use `versionize` when a .NET project follows Conventional Commits and needs automatic version bumps plus `CHANGELOG.md`. Combine it with `dotnet-releaser` or a CI workflow when the desired scope also includes packaging, GitHub Releases, and NuGet publishing.
