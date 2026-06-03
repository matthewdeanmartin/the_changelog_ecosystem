Title: GitReleaseManager
Date: 2026-06-02
Slug: gitreleasemanager
Ecosystem: Dotnet
Tags: dotnet, dotnet-tool, draft-releases, github-integration, milestones, ci-only, hands-on
Tool_URL: https://www.nuget.org/packages/gitreleasemanager.tool/
Tool_Version: 0.20.0
Tool_Status: active
Experiment: examples/dotnet/gitreleasemanager/
Summary: .NET/GitTools CLI for milestone-driven draft releases; hands-on testing confirms it is GitHub-API-only with no offline or local-changelog mode.



## Overview

GitReleaseManager is a GitTools-era .NET utility for managing GitHub Releases, especially milestone-driven draft releases. It helps maintainers create a draft, attach assets, publish it, and export release notes from GitHub project data.

It is useful when GitHub milestones are already the organizing unit for a release.

A reproducible hands-on experiment for this tool lives in [`examples/dotnet/gitreleasemanager/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/gitreleasemanager).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), GitReleaseManager could not be driven through any meaningful step of the release life cycle offline. Every operational subcommand (<code>create</code>, <code>publish</code>, <code>close</code>, <code>export</code>) hard-requires <code>--token</code>, <code>--owner</code>, and <code>--repository</code> and fails at argument validation before any work happens. There is no local-changelog mode and no offline path — even <code>export</code> pulls from the GitHub Releases API rather than local git history. The tool is not broken or unmaintained; it is simply <strong>CI-only by design</strong> and useless without a live GitHub connection. (Separately, note the NuGet package-ID gotcha below.) See the hands-on findings.
</div>

## Installation

```bash
dotnet tool install -g gitreleasemanager.tool
```

> **Important (from hands-on testing):** the package ID is **`gitreleasemanager.tool`**, not `GitReleaseManager`. Installing `GitReleaseManager` fails with a confusing error — `Settings file 'DotnetToolSettings.xml' was not found in the package` — and the tool's README/NuGet listing do not surface this clearly. The installed binary is `dotnet-gitreleasemanager`.

## What It Does

- Creates draft GitHub Releases (from milestones).
- Pulls issue and pull request information from GitHub milestones.
- Attaches binary assets to releases.
- Publishes existing draft releases.
- Exports release notes (fetched from the GitHub Releases API, not local git).

## Configuration

Most configuration is command-line driven: repository owner/name, milestone, tag, token, and optional asset paths. Teams usually wrap it in CI scripts.

```bash
dotnet-gitreleasemanager create \
  --owner example \
  --repository my-library \
  --milestone "1.4.0" \
  --token "$GITHUB_TOKEN" \
  --targetcommitish main
```

The `init` subcommand creates a sample YAML configuration file locally without any API call, so you can scaffold a config even in a dry run. Beyond that, setup is moderate because GitHub milestones, labels, and tokens need to be consistent.

## Ecosystem Fit

GitReleaseManager fits .NET projects that already use GitHub milestones and the GitTools chain (GitVersion + GitReleaseManager). It is less central today than newer all-in-one options such as `dotnet-releaser`.

It does not compute semantic versions like GitVersion and does not generate notes from Conventional Commits. Critically, it does nothing locally — see the hands-on findings.

## Maintenance Status

- Latest version: **0.20.0**
- Last release: **2025-04-03**
- GitHub stars: **323**
- Appears actively maintained.
- Repository: <a href="https://github.com/GitTools/GitReleaseManager" target="_blank" rel="noopener noreferrer">https://github.com/GitTools/GitReleaseManager</a>

The metadata shows a less frequent release cadence than the most active tools, but it is not marked archived.

---

## Hands-on findings

The notes below come from driving `gitreleasemanager.tool` 0.20.0 through a real life cycle in an offline Docker container (`mcr.microsoft.com/dotnet/sdk:8.0`, a minimal tip-calculator project with two real commits and tags `v1.0.0`/`v2.0.0`). The full transcript is in [`examples/dotnet/gitreleasemanager/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/dotnet/gitreleasemanager).

All four primary operational subcommands were invoked with `--owner test --repository test` and no `--token`. Every one fails at argument validation before any network call:

**`create` (no token):**

```
GitReleaseManager 0.20.0+f0911e4b5480846c34f0026b2be8fb40871b7c25
Copyright (c) 2015 - Present - GitTools Contributors

ERROR(S):
  Required option 'token' is missing.
```

**`export` (no token):**

```
ERROR(S):
  Required option 'token' is missing.
  Required option 'f, fileOutputPath' is missing.
```

**`publish` and `close` (no token):**

```
ERROR(S):
  Required option 'token' is missing.
```

`--token` is declared `Required = true` in the CLI parser for every operational subcommand. There is no environment-variable fallback, no `.gitconfig` credential lookup, and no local cache. Only `init` and `showconfig` are plausibly runnable without a live GitHub connection.

### Pros (observed)

- **Clear, immediate error messages.** The missing-token error is precise and explains exactly what is needed.
- **Consistent argument shape.** Every subcommand uses the same `--token`/`--owner`/`--repository` triple, so a CI wrapper can template them uniformly.
- **Full release-lifecycle surface on GitHub:** draft creation, asset attachment, milestone open/close, publish, and export.
- **`init` works offline,** producing a usable YAML config scaffold without an API call.

### Cons / pain points (observed)

- **Wrong package ID by default.** `dotnet tool install -g GitReleaseManager` fails; the correct ID is `gitreleasemanager.tool` (see install note).
- **Zero offline capability.** No mode reads local git history or writes a local `CHANGELOG.md`. Even `export`, despite its name, fetches release notes from the GitHub Releases API.
- **`--version` exits with code 1.** A minor CI footgun if a pipeline runs `tool --version && ...` to confirm install.
- **`export` requires `--fileOutputPath`** — no stdout default like most tools.
- **Three required arguments minimum** (`--token`, `--owner`, `--repository`) before any business logic, so CI must inject all three for every call.

### Docs vs. reality

The original article correctly described GitReleaseManager as a GitHub-API-driven, command-line-driven tool. The hands-on run adds two things it missed: the **package-ID gotcha** (the first barrier any new user hits) and how **hard** the CI-only constraint is — there is genuinely no local or offline use case.

## Verdict

**Verdict: Situational — CI-only**

For teams already on the GitTools chain (GitVersion + GitReleaseManager) and organizing releases around GitHub milestones, the combination is coherent and GitReleaseManager is a reasonable fit. But it is **not** a general .NET changelog tool: it is a GitHub Release management CLI that requires a live GitHub connection and a token for every meaningful operation. There is no local-first workflow.

For new projects choosing a .NET changelog tool, `dotnet-releaser` or git-cliff offer local-first workflows and are better defaults. Treat the NuGet package-ID issue (`gitreleasemanager.tool`, not `GitReleaseManager`) as a known friction point. If the design didn't fit your needs, the tool is open source and could be forked — but its scope is deliberate, so forking for an offline mode would be a substantial rewrite rather than a small fix.
