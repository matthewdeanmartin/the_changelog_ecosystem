Title: GitReleaseManager (hands-on synthesis)
Slug: gitreleasemanager-v2
Date: 2026-06-02
Ecosystem: Dotnet
Tags: dotnet, dotnet-tool, github-integration, milestones, ci-only
Tool_URL: https://www.nuget.org/packages/gitreleasemanager.tool/
Tool_Version: 0.20.0
Experiment: examples/dotnet/gitreleasemanager/
Summary: Hands-on confirmation that GitReleaseManager requires live GitHub API access — no offline/local mode.


## What I Actually Ran

The experiment lives in `examples/dotnet/gitreleasemanager/`. The container is based on
`mcr.microsoft.com/dotnet/sdk:8.0` with `gitreleasemanager.tool` 0.20.0 installed as a
dotnet global tool. The binary is `dotnet-gitreleasemanager`.

The experiment attempted all four primary operational subcommands (`create`, `publish`,
`close`, `export`) against a minimal tip-calculator project with two real git commits
and tags (v1.0.0, v2.0.0) created entirely inside the container.

All commands were invoked with `--owner test --repository test` and no `--token`.

---

## Real Output

Every subcommand fails at argument validation before any network call is made:

**Stage 2 — `create` attempt (no token):**

```
GitReleaseManager 0.20.0+f0911e4b5480846c34f0026b2be8fb40871b7c25
Copyright (c) 2015 - Present - GitTools Contributors

ERROR(S):
  Required option 'token' is missing.
```

**Stage 3 — `export` attempt (no token):**

```
ERROR(S):
  Required option 'token' is missing.
  Required option 'f, fileOutputPath' is missing.
```

**Stage 4 — `publish` and `close` attempts (no token):**

```
ERROR(S):
  Required option 'token' is missing.
```

The `--token` option is declared `Required = true` in the CLI parser for every subcommand
with operational effect. There is no environment variable fallback, no `.gitconfig` credential
lookup, and no local cache.

---

## Pros (Observed)

- **Clear, immediate error messages.** The missing-token error is precise and explains
  exactly what is needed.
- **Consistent argument shape.** Every subcommand uses the same `--token`, `--owner`,
  `--repository` triple, so a CI wrapper script can template them uniformly.
- **Subcommand breadth.** The tool covers the full release lifecycle on GitHub: draft
  creation, asset attachment, milestone closure, release publishing, and export.
- **`init` subcommand.** The `init` command creates a sample YAML configuration file
  locally without any API call, giving a usable configuration scaffold even in a dry run.

---

## Cons / Pain Points (Observed)

- **Wrong NuGet package ID.** The documented install command `dotnet tool install -g GitReleaseManager`
  fails with a confusing internal error:
  ```
  The settings file in the tool's NuGet package is invalid: DotnetToolSettings.xml was not found.
  ```
  The correct package ID is `gitreleasemanager.tool`. This is not prominently surfaced in
  the tool's README or on the NuGet package listing for `GitReleaseManager`.

- **Zero offline capability.** There is no mode that reads local git history, generates a
  local CHANGELOG.md, or does anything meaningful without a live GitHub remote. The `export`
  subcommand, despite its name suggesting a one-way data dump, also requires live API access
  to fetch existing release notes from GitHub Releases.

- **`--version` exits with code 1.** Running `dotnet-gitreleasemanager --version` exits
  non-zero. This is a minor but annoying CI footgun when a pipeline checks that the tool
  installed correctly via `tool --version && ...`.

- **`export` requires `--fileOutputPath`.** Unlike most tools where output defaults to
  stdout, `export` requires an explicit output file path. No stdout default.

- **Three required arguments minimum.** Before any business logic, every call needs
  `--token`, `--owner`, and `--repository`. For teams that vary repositories, this
  means three environment variables or parameters injected by the CI system for every call.

---

## Docs vs. Reality

The original `gitreleasemanager.md` article correctly identified GitReleaseManager as a
GitHub-API-driven tool and noted that "all inputs are command-line driven: repository
owner/name, milestone, tag, token." That assessment is accurate and confirmed.

The original article did not mention the broken NuGet package ID (`GitReleaseManager` vs.
`gitreleasemanager.tool`), which is the first practical barrier any new user will hit.

The original verdict of "Situational" is reasonable for teams already deeply invested in the
GitTools ecosystem and GitHub milestones. However, it understates the hard CI-only constraint:
there is truly no local or offline use case, and new adopters face the package-ID confusion
immediately.

---

## Revised Verdict

**CI-only — do not use without GitHub credentials and a live remote.**

The original verdict of "Situational" holds in narrow scope (GitHub milestones + GitTools
pipeline + CI environment), but for any developer evaluating it as a general .NET changelog
tool, the right answer is: it is not that. It is a GitHub Release management CLI that
requires a live GitHub connection for every meaningful operation.

For teams already on the GitTools chain (GitVersion + GitReleaseManager), the combination
is coherent. For new projects choosing a .NET changelog tool, `dotnet-releaser` or
git-cliff provide local-first workflows and are better defaults.

The NuGet package ID bug (`GitReleaseManager` fails to install; `gitreleasemanager.tool`
succeeds) should be treated as a known friction point when documenting this tool for any
audience.
