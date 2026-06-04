Title: release-please
Date: 2026-05-31
Modified: 2026-06-03
Slug: release-please
Ecosystem: Cross
Tags: conventional-commits, cross, github-action-cli, github-integration, semantic-versioning, hands-on
Tool_URL: https://github.com/googleapis/release-please
Tool_Version: 17.7.0
Tool_Status: active
Experiment: examples/cross/release-please/
Summary: Google release automation that parses Conventional Commits, opens release PRs, updates changelogs, bumps versions, and creates GitHub releases. GitHub-required (hands-on verified).



## Overview

`release-please` automates releases by opening a release pull request. It parses Conventional Commits, proposes version bumps, updates changelogs and manifest files, and creates GitHub Releases after the release PR merges.

That release-PR model is the key distinction: automation does the bookkeeping, but humans still review the exact release diff.

> **Hands-on note.** This review is grounded in actually trying to drive `release-please`
> through the changelog life cycle in a container — see
> [`examples/cross/release-please/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/cross/release-please).
> The decisive finding: **it cannot run offline.** Tool under test was the `release-please`
> npm CLI **17.7.0** on `node:20-slim`. Every path that would produce a changelog requires a
> live GitHub repository *and* a valid token, so the "real output" below is the API wall the
> tool hits, not a generated changelog.

## Installation

Most projects run it as a GitHub Action; there is also an npm CLI (what this review tested):

```yaml
# GitHub Action
- uses: googleapis/release-please-action@v4
  with:
    release-type: node
```

```bash
# npm CLI — identical GitHub-API requirement
npm install -g release-please
release-please release-pr --repo-url=<owner>/<repo> --token=$GITHUB_TOKEN
```

Choosing the CLI over the Action buys you **no** offline capability — see Output Quality.

## What It Does

- Parses Conventional Commits to determine semantic version bumps.
- Opens and updates a release PR with changelog and version-file changes.
- Supports many release types, including Node, Python, Java, Go, Ruby, Rust, and simple projects.
- Creates GitHub Releases after the release PR is merged.
- Supports manifest mode for monorepos and multi-package repositories.

## Configuration

Small projects can configure the GitHub Action directly. Larger projects usually use `release-please-config.json` and `.release-please-manifest.json`. This is the config that drove the experiment:

```json
{
  "packages": {
    ".": {
      "release-type": "python",
      "package-name": "tipcalc",
      "include-v-in-tag": false
    }
  }
}
```

```json
{ ".": "1.0.0" }
```

The config and manifest are clean and well-documented, and `release-type` covers many ecosystems. First-run setup is moderate: commit conventions, package files, branch permissions, and GitHub token behavior must line up. Once it is running, the release PR becomes a clear review point.

## Output Quality

When release-please runs against a real GitHub repo, release notes are generated from Conventional Commits and look like this:

```markdown
## [1.7.0](https://github.com/example/tool/compare/v1.6.0...v1.7.0)

### Features

- add GitLab release publishing support

### Bug Fixes

- preserve changelog headings in manifest mode
```

The quality is strong for projects that write user-facing commit messages, and weaker when commits are noisy or implementation-heavy.

**But that output cannot be produced locally.** In the experiment, the repo, config,
manifest, and a clean Conventional-Commit history (`feat` → minor, `feat!`/`BREAKING
CHANGE` → major) were all built correctly inside the container — and then
`release-pr --local --local-path … --dry-run` failed on its very first action:

```text
RequestError [HttpError]: getaddrinfo EAI_AGAIN api.github.com
    at GitHubApi.defaultBranch (.../github-api.js:314)
    at LocalGitHub.create     (.../local-github.js:46)
  request: { method: 'GET', url: 'https://api.github.com/repos/example/tipcalc' }
```

Read the stack: even in `--local` mode, the first call is `GitHubApi.defaultBranch` →
`GET /repos/{owner}/{repo}`. The `--local` flag controls the *clone* strategy, not the API
dependency; `--dry-run` does not bypass it either. With a network but a fake token the same
call returns `401 Bad credentials`, so a valid token is mandatory too — and `debug-config`,
despite the name, behaves identically. There is no subcommand that emits a changelog or
version bump from local state alone.

## Ecosystem Fit

`release-please` is cross-language but **GitHub-required**, not merely GitHub-centered. It is especially good for repositories that want version bumps and changelog updates committed (and reviewed) before the actual release, all driven by commit history rather than fragment files.

It is inappropriate for teams that publish from GitLab, want fragment files, prefer a single push-to-main release with no release PR, or need any offline/air-gapped changelog generation. For the purposes of this site's hands-on experiments it sits with the platform-bound tools (glab, Release Drafter), not the local CLIs (logchange, Towncrier).

## Maintenance Status

- Latest version: **5.0.0** (action) / **17.7.0** (CLI tested)
- Last release: **2026-04-22**
- GitHub stars: **2,415**
- Appears actively maintained.
- Repository: <a href="https://github.com/googleapis/release-please" target="_blank" rel="noopener noreferrer">https://github.com/googleapis/release-please</a>

The action and CLI remain active and widely used across Google's open-source release workflows.

## Verdict

**Verdict: Recommended (for GitHub repositories)**

For its intended habitat — a GitHub repository with a token in CI — release-please is exactly what it claims: strong, reviewable, Conventional-Commits release automation, and one of the best default choices when you want automation without losing a human checkpoint. The hands-on run does not downgrade that; it sharpens the boundary. Be clear-eyed that this is a GitHub-*required* tool: there is no local or offline mode, the npm CLI carries the same dependency as the Action, and you cannot generate a changelog without a live GitHub repo and token. If that constraint fits, recommend it; if you need platform independence or offline generation, choose a fragment tool instead.
