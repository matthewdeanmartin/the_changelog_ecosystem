Title: GoReleaser
Date: 2026-06-02
Slug: goreleaser
Ecosystem: Go
Tags: github-integration, gitlab-integration, gitea-integration, go, go-cli-ci, release-orchestration, artifacts, changelog-generate, ci-cd, hands-on
Tool_URL: https://goreleaser.com/
Tool_Version: 2.16.0
Tool_Status: active
Experiment: examples/go/goreleaser/
Summary: Full Go release-automation pipeline where changelog generation is one stage — hands-on testing confirms the build pipeline runs offline, but the changelog stage is gated behind a real release.



## Overview

`goreleaser` is the dominant release automation tool in the Go ecosystem. It builds binaries, creates archives and checksums, publishes package-manager manifests, creates GitHub/GitLab/Gitea releases, and includes generated changelog text in those releases.

For this survey, the key point is that GoReleaser is not just a changelog generator. It is a release pipeline where changelog generation is one stage, best suited to Go CLIs and services that need reproducible artifacts as much as release notes.

> A reproducible hands-on experiment for this tool lives in [`examples/go/goreleaser/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/goreleaser). We drove GoReleaser through a real release life cycle in an offline Docker container; the real output and an important caveat about changelog generation are at the end of this article.

## Installation

```bash
# Pre-built binaries from GitHub Releases, Homebrew, package managers, Docker:
# https://github.com/goreleaser/goreleaser
```

## What It Does

- Builds Go binaries for multiple operating systems and architectures.
- Generates release archives, checksums, SBOMs, container images, and package-manager updates depending on configuration.
- Creates releases on GitHub, GitLab, Gitea, and related hosting targets.
- Generates changelog text from git commits or hosting-provider compare APIs.
- Groups, sorts, filters, and skips commits using regular expressions.
- Can accept hand-written release notes with `--release-notes` when generated notes are not enough.

## Configuration

GoReleaser uses `.goreleaser.yaml` or `.goreleaser.yml`. The changelog section controls whether release notes are generated, which backend is used, and how commits are grouped.

```yaml
project_name: my-cli

builds:
  - main: ./cmd/my-cli
    binary: my-cli

archives:
  - formats: [tar.gz]   # NOTE: 2.x uses `formats:` (array); scalar `format:` is deprecated

changelog:
  use: git              # `git` reads local tags and works offline; `github` needs a remote + token
  sort: asc
  groups:
    - title: Features
      regexp: '^.*feat[(\\w)]*:+.*$'
      order: 0
    - title: Bug Fixes
      regexp: '^.*fix[(\\w)]*:+.*$'
      order: 1
  filters:
    exclude:
      - '^docs:'
      - '^test:'
```

First-run setup is moderate to high because GoReleaser covers the full release lifecycle. The changelog settings themselves are manageable, but the surrounding artifact, signing, package-manager, and token configuration takes care.

## Ecosystem Fit

GoReleaser is deeply native to Go project release work: it understands Go binaries, cross-compilation, Git tags, GitHub Actions, Homebrew taps, Docker images, and the expectation that users download compiled artifacts rather than build from source.

It is too broad if all you need is a `CHANGELOG.md`; `git-chglog`, `git-cliff`, or Changie are narrower. For Go CLIs, though, it is usually the first release tool to evaluate.

## Maintenance Status

- Latest version: **2.16.0**
- Last release: **2026-05-24**
- GitHub stars: **15,830**
- Appears actively maintained.
- Repository: <a href="https://github.com/goreleaser/goreleaser" target="_blank" rel="noopener noreferrer">https://github.com/goreleaser/goreleaser</a>

The documentation is current and includes detailed changelog configuration, release commands, GitHub/GitLab/Gitea support, generated artifacts, and CI usage.

---

## Hands-On Findings

We built a Docker image from `golang:1.22-bullseye`, installed GoReleaser 2.16.0 from the official GitHub Release tarball, set up a minimal Go project (`github.com/example/tipcalc`) with three tagged commits (`v1.0.0`/`v2.0.0`/`v3.0.0`, conventional-commit messages), and exercised every changelog-related command path with no remote and no token. Full transcript: [`examples/go/goreleaser/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/goreleaser).

**The build pipeline worked.** `goreleaser release --snapshot --clean` ran successfully and produced real artifacts on every run. **The changelog stage, however, never executed** — three discoveries explain why, and they matter a lot if you are evaluating GoReleaser specifically as a changelog tool.

### `goreleaser changelog` does not exist

The first surprise: there is no standalone `changelog` subcommand in v2.16.0.

```
⨯ command failed    error=unknown command "changelog" for "goreleaser release"
```

Some blog posts and older docs reference it, but in the current release changelog generation is a pipeline stage that runs internally during `goreleaser release`, and the result goes directly into the GitHub/GitLab/Gitea release body. It is never printed to stdout or written to `CHANGELOG.md` by default.

### Snapshot mode skips the changelog stage

`goreleaser release --snapshot` is the recommended offline path. It ran cleanly and produced a compiled Linux amd64 binary, a tarball, and checksums:

```
dist/tipcalc_0.0.0-SNAPSHOT-none_linux_amd64.tar.gz
dist/tipcalc_0.0.0-SNAPSHOT-none_checksums.txt
```

But the changelog pipe was skipped entirely:

```
• pipe skipped or partially skipped    reason=disabled during snapshot mode
```

There is no way to preview what GoReleaser would write to a GitHub Release body without performing a real release against a real remote. `--snapshot` exists specifically to validate the build and archive pipeline in isolation — not the release notes.

### Version detection fails without a remote

With `changelog.use: github` and no remote configured, GoReleaser could not determine the current tag, even though local tags existed:

```
error=couldn't get remote URL: fatal: No remote configured to list refs from.
using tags    previous=<unknown> current=v0.0.0
```

Switching to `changelog.use: git` reads local tags directly and works without a remote — the fix for offline/local rendering.

### Deprecation notice

The config used `archives.format: tar.gz` (scalar). GoReleaser 2.x expects `archives.formats: [tar.gz]` (array) and emits a deprecation warning on every run. Minor but visible, and easy to inherit from 1.x tutorials.

### What the changelog looks like in production

Because snapshot mode skips changelog generation, **no release-note text was produced in the experiment** — the block below is illustrative, not captured output. In a real release against a remote (with `GITHUB_TOKEN` set, or with `use: git`), GoReleaser would embed grouped markdown in the release body. With the grouping config used here, the three commits would render roughly as:

```markdown
## Changelog

### Features

* feat: compute tip for a single bill
* feat: split the bill evenly among diners
* feat!: split the bill unevenly by weight

**Full Changelog**: https://github.com/example/tipcalc/compare/v1.0.0...v3.0.0
```

This text appears in the hosted Release UI. It is **not** written to a `CHANGELOG.md` file on disk. For a file-based changelog you need a separate step — GoReleaser integrates with `git-cliff` via `before.hooks`, or you can supply a pre-written file with `--release-notes`.

### Commands that work offline

| Command | Works offline? | Notes |
|---------|----------------|-------|
| `goreleaser --version` | Yes | |
| `goreleaser check` | Yes | Validates config only; fast |
| `goreleaser release --snapshot --clean` | Partially | Builds binaries; skips changelog |
| `goreleaser release` | No | Requires remote + token for changelog (with `use: github`) |
| `goreleaser changelog` | N/A | Subcommand does not exist in v2.16.0 |

### Pros (observed)

- **Full pipeline coherence.** Cross-compilation, archives, checksums, SBOMs, container images, Homebrew taps, and release notes are all driven by one config and one command. Nothing else matches this scope for distributing Go CLI artifacts.
- **Proven and actively maintained.** 15,800+ stars, consistent releases, deep GitHub Actions integration.
- **Conventional-commit grouping works.** `changelog.groups` with `regexp` matchers categorizes commits with no boilerplate.
- **`goreleaser check` is fast and useful**, catching schema errors before a real release.
- **`use: git` works locally**, generating changelog from local git history without an API call or token.

### Cons (observed)

- **No standalone changelog subcommand.** You cannot preview or extract release-note text without pushing a release — a real gap for changelog-first / review-in-PR workflows.
- **Changelog generation is gated behind a real release.** `--snapshot`, the documented offline path, explicitly disables the changelog pipe; you cannot dry-run the notes.
- **`use: github` requires a remote and token**, even for what feels like a local operation. Switch to `use: git` or keep a token in your environment.
- **Not a file-based changelog tool.** It writes notes into the hosted Release UI, not `CHANGELOG.md`. A checked-in file needs a second tool or a `before.hooks` script.
- **Large config surface.** Builds, archives, checksum, signs, SBOMs, snapshots, publishers, homebrew, announce — significant overhead if you only want release notes.

### Docs vs. reality

The documentation is thorough and accurate for the full pipeline. Two discrepancies surfaced: the `goreleaser changelog` subcommand referenced in some community posts does not exist in v2.16.0, and the snapshot docs describe `--snapshot` as testing "your release pipeline locally" without prominently noting that the changelog/release-notes stage is silently skipped. The `archives.format` → `archives.formats` deprecation is documented but easy to miss when copying 1.x examples.

## Verdict

**Verdict: Recommended for Go release pipelines; not recommended as a changelog-only tool.**

GoReleaser is the right choice when releasing a Go CLI or service that needs binary distribution — cross-platform builds, archives, checksums, Homebrew taps, container images, and hosted releases all from a single pipeline. Our run confirmed that pipeline works cleanly offline. The changelog component comes along for free and is good enough for standard GitHub Release notes.

It is the wrong choice if your primary goal is changelog management: it does not write `CHANGELOG.md`, you cannot preview release notes without performing an actual release, and the setup cost is disproportionate if you only want a formatted commit log.

**When to use GoReleaser for changelog:** you are already using it for binary distribution and want notes auto-generated in the Release body. Configure `changelog.use: git` (not `github`) for offline safety, add grouping rules, and you are done.

**When to use something else:** you want a `CHANGELOG.md` file, a changelog preview in CI before the release tag, or changelog tooling independent of the deployment pipeline. There, `git-cliff` (highly configurable templates, works entirely from local git) or `changie` (fragment-based, explicit control) fit better. Both integrate with GoReleaser via `before.hooks` if you need both a file and a hosted release body. Treat GoReleaser's changelog generator as a practical release-note component, not a replacement for human-written product communication.
