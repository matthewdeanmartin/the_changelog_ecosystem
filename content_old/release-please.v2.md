Title: release-please (hands-on synthesis)
Date: 2026-06-03
Slug: release-please-v2
Ecosystem: Cross
Tags: conventional-commits, cross, github-action-cli, github-integration, semantic-versioning, ci-cd, hands-on
Tool_URL: https://github.com/googleapis/release-please
Tool_Version: 17.7.0 (npm CLI)
Tool_Status: active
Experiment: examples/cross/release-please/
Summary: Hands-on re-review confirming release-please cannot run offline — the local-only subset hits a hard GitHub-API wall.



## What I actually ran

This is a second-pass review grounded in *running* release-please, not reading its docs.
The reproducible experiment lives in [`examples/cross/release-please/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/cross/release-please).

Unlike the fragment tools on this site (towncrier, scriv, reno, logchange), release-please
**cannot be driven through the full life cycle in an isolated container**, because it has
no offline mode. So this experiment deliberately drives the *local-only subset* and
captures the exact point where the GitHub API becomes mandatory — that limit is the finding.

- **Base image:** `node:20-slim` + `release-please@17.7.0` (npm CLI) + `git`, `python3`.
- **Tool version:** `release-please --version` → `17.7.0`.
- **Fixture:** the trivial all-constants "restaurant tip calculator" CLI.
- **Run mode:** the container runs with `--network none`, so release-please's API
  dependency surfaces as a hard, reproducible failure rather than a flaky live call.
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code, **no changelog**; tagged `tipcalc-1.0.0`.
  2. `release-please-config.json` (`release-type: python`, `package-name: tipcalc`,
     `include-v-in-tag: false`) + `.release-please-manifest.json` seeded at `1.0.0`.
  3. Even-split feature committed as `feat: …`.
  4. Uneven-split committed as `feat!: … / BREAKING CHANGE:`, then attempt
     `release-pr --local --local-path=/work/app --dry-run`.

Three commits and a tag were created entirely inside the container — nothing touched the
review site's own repo.

## Real output — the GitHub-API wall

The git history release-please would parse (exactly what the tool needs for version
inference) was built correctly and locally:

```
feat!: split the bill unevenly by weight   <- BREAKING CHANGE => major (3.0.0)
feat: split the bill evenly among diners    <- feat => minor (2.0.0)
feat: compute the tip for a single bill     <- tag: tipcalc-1.0.0
```

But `release-pr` — even with `--local`, `--local-path`, and `--dry-run` — fails before
producing anything, on its very first action:

```
RequestError [HttpError]: getaddrinfo EAI_AGAIN api.github.com
    at GitHubApi.defaultBranch (.../github-api.js:314)
    at GitHubApi.create     (.../github-api.js:306)
    at LocalGitHub.create   (.../local-github.js:46)
  request: { method: 'GET', url: 'https://api.github.com/repos/example/tipcalc' }
```

Read the stack: in `--local` mode (`LocalGitHub.create`) the first thing release-please
does is `GitHubApi.defaultBranch` → `GET /repos/{owner}/{repo}`. The `--local` flag
controls the *clone* strategy, **not** the API dependency. Run with a network but a fake
token, the same call returns `401 Bad credentials` — so a valid token is mandatory too.

`debug-config`, which *sounds* like a local config inspector, behaves identically: it also
immediately calls `GET /repos/{owner}/{repo}`. There is no subcommand that produces a
changelog or version bump from local state alone.

`out/` therefore contains the config, manifest, git log and tags, and the full transcript
— but **no `CHANGELOG.md`**, because release-please never writes one locally.

## Pros (observed, of the local subset)

- **Clean config + manifest model.** `release-please-config.json` and
  `.release-please-manifest.json` are well-structured; `release-type` covers many
  ecosystems (`python`, `node`, `rust`, `go`, `java`, `simple`, …).
- **Commits are the single source of truth.** No fragments, no manual version edits —
  Conventional Commits encode the bump (`feat` → minor, `feat!`/`BREAKING CHANGE` →
  major). The local history modeled this correctly.
- **A `--local` flag exists**, signalling intent toward offline use — even if it doesn't
  deliver it.

## Cons / pain points (observed)

- **No offline mode whatsoever.** release-please cannot emit a CHANGELOG.md or bump a
  version without a reachable GitHub repo *and* a valid token. `--dry-run` and `--local`
  do not bypass this; both call the API first.
- **`--local` is misleading.** It changes how the repo is obtained, not whether the API
  is used; `LocalGitHub.create` still calls `GitHubApi.defaultBranch`.
- **`debug-config` is not local.** Despite the name, it requires the API too.
- **Not containerizable for review** the way fragment tools are — you cannot exercise the
  headline behavior (the release PR + changelog) without a live GitHub repo.

## Docs vs. reality

- The original review describes it as "GitHub-centered," opening a release PR and creating
  GitHub Releases. **Confirmed — and stronger than stated:** it is GitHub-*required*. There
  is no local fallback for changelog generation, which the original review left implicit.
- The original review's install snippet is the GitHub Action. The npm CLI exists and is
  what I tested, but it carries the *identical* API requirement — using the CLI instead of
  the Action buys you no offline capability.

## Revised verdict

**Verdict: Recommended (for its habitat) — but reclassified as server/API-bound.**

For its intended use — a GitHub repository with a token in CI — release-please is exactly
what the original review says: a strong, reviewable, Conventional-Commits release
automation. Nothing here downgrades that. What the hands-on run *adds* is a precise
boundary: release-please is **not** a local CLI in the sense that logchange or towncrier
are. It belongs with the platform-bound "cross" tools (glab, release-drafter). The
local-only subset is limited to repo + config setup and commit-convention modeling; every
path that produces a changelog or release requires a live GitHub repo and token.
