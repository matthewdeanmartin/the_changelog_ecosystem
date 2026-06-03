Title: changelog-generator
Date: 2026-06-02
Slug: changelog-generator
Ecosystem: Go
Tags: conventional-commits, go, go-cli-library, release-notes, github-action, commit-history, ci-cd, git-history, changelog-file, hands-on
Tool_URL: https://pkg.go.dev/gabe565.com/changelog-generator
Tool_Version: 1.1.5
Tool_Status: active
Experiment: examples/go/changelog-generator/
Summary: A focused, commit-based changelog generator that emits commits since the previous tag to stdout — hands-on testing confirms it works with zero config but has a narrow feature set.



## Overview

`changelog-generator` is a focused Go CLI and library for generating release-note text from commits since the previous release. It intentionally resembles GoReleaser's changelog output, making it useful when a project wants GoReleaser-style notes without adopting the full GoReleaser artifact pipeline.

It is a narrower tool than GoReleaser and a smaller ecosystem player than `git-cliff` or Changie. Its best niche is projects that already have another build or publish system but want a lightweight, Go-native changelog step.

> A reproducible hands-on experiment for this tool lives in [`examples/go/changelog-generator/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/changelog-generator). We drove the tool through a real three-tag release life cycle in an offline Docker container; the real output and findings are at the end of this article.

## Installation

```bash
# Go install (requires Go >= 1.24 — see hands-on findings)
go install gabe565.com/changelog-generator@v1.1.5

# Pre-built binaries, Homebrew, and package managers are also available:
# https://github.com/gabe565/changelog-generator
```

## What It Does

- Finds commits since the previous release tag.
- Filters and groups commits into release-note sections (grouping requires a config file).
- Produces GoReleaser-like changelog output.
- Can run as a CLI, a Go library, or a GitHub Action.
- Supports configuration file paths and CI-friendly outputs.

## Configuration

The GitHub Action accepts a config path, and the CLI/library can use project configuration to control grouping and filtering. A typical workflow is lightweight:

```yaml
name: release-notes
on:
  workflow_dispatch:

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gabe565/changelog-generator-action@v1
        with:
          config: .github/changelog.yml
```

First-run setup is low if the default grouping matches the project. It becomes more useful once commit filtering and section names are tuned to the team's commit style — but note that **without** a config file there is no grouping at all (see the hands-on findings).

## Ecosystem Fit

The Go fit is pragmatic. It is available as a Go package and GitHub Action, and it is useful for projects that want GoReleaser-like changelog behavior while using another build system. In practice it is also language-agnostic — our hands-on run drove it against a plain shell-script project with no issue.

It is not broad enough to replace GoReleaser for Go CLI releases, and it is not as mature or configurable as `git-cliff` for complex historical changelogs. Treat it as a small, focused generator.

## Maintenance Status

- Latest version: **1.1.5**
- Last release: **2025-03-02**
- GitHub stars: **4**
- Appears actively maintained, but the community is tiny.
- Repository: <a href="https://github.com/gabe565/changelog-generator" target="_blank" rel="noopener noreferrer">https://github.com/gabe565/changelog-generator</a>

The project is small but current, with docs for GitHub Action usage, configuration, installation, and library/CLI entry points.

---

## Hands-On Findings

We built a Docker container using `golang:1.24-bookworm`, installed `changelog-generator` via `go install gabe565.com/changelog-generator@v1.1.5`, and ran a three-tag life cycle (v1.0.0 → v2.0.0 → v3.0.0) on a language-agnostic shell-script app (`tipcalc.sh`). The full script and transcript live in [`examples/go/changelog-generator/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/changelog-generator).

**The tool worked.** It produced correct, incremental output on every release with zero mandatory configuration.

### Two surprises during setup

- **Go 1.24 required.** The first build used `golang:1.22` and the module rejected it at install time:
  ```
  go: gabe565.com/changelog-generator@v1.1.5 requires go >= 1.24.0 (running go 1.22.12; GOTOOLCHAIN=local)
  ```
  This requirement is not prominent on the releases page or README. Bumping the base image fixed it cleanly.
- **There is no `--output` flag.** The GitHub Action documentation implies an `--output` binary flag. It does not exist — no `--output`, no `-o`. The binary writes to stdout only; the Action's `output` parameter is handled by the Action wrapper, not the binary. To write a file you must redirect: `changelog-generator > CHANGELOG.md`.

### Real output

The entire CLI surface is three user-facing flags:

```
Generates a changelog from commits since the previous release

Usage:
  changelog-generator [flags]

Flags:
      --config string   Config file (default ".changelog-generator.yaml")
  -h, --help            help for changelog-generator
  -C, --repo string     Path to the git repo root. Parent directories will be walked until .git is found. (default ".")
  -v, --version         version for changelog-generator
```

The version string is misleading — a tagged v1.1.5 binary reports itself as `beta`:

```
changelog-generator version beta
```

This is a stale embedded build-time constant. Cosmetically confusing, no functional impact.

After tagging v1.0.0 with one conventional-commit message, running `changelog-generator` produced (no config file):

```markdown
## Changelog
- 240c69c7 feat: compute tip for a single bill
```

After v2.0.0 → v3.0.0 with a breaking-change commit:

```markdown
## Changelog
- 5c837c1b feat!: split the bill unevenly by weight
```

The tool correctly found only the commits since the previous tag. Without a config file there are no sections — one flat list under `## Changelog`. The `feat!:` breaking-change marker appears verbatim; the tool does **not** automatically promote it to a "Breaking Changes" section. Grouping requires a `.changelog-generator.yaml` config.

### Pros (observed)

- **Zero mandatory configuration.** Run it in any git repo with tagged releases and it produces output immediately.
- **Correct incremental behavior.** It reliably finds the previous tag and shows only the commits since then. No manual range arguments needed.
- **Language-agnostic.** Confirmed working against a shell-script fixture; not Go-specific despite the Go distribution.
- **Small, fast binary** (~8 MiB), an unobtrusive addition to any CI image.
- **GitHub Action wrapper available**, which handles file writing and token auth cleanly.

### Cons (observed)

- **Stdout only.** No `--output` flag; shell redirection is required — a minor but real gap versus `git-cliff --output CHANGELOG.md`.
- **No grouping without config.** Out of the box there are no "Features" / "Bug Fixes" / "Breaking Changes" sections — every commit lands in one flat list.
- **Version string says "beta"** despite being a tagged v1.x release.
- **Requires Go 1.24**, a newer toolchain than many CI base images include, with no clear guidance on install failure.
- **4 GitHub stars.** Not evidence of a bad tool, but the community is tiny, issue response may be slow, and long-term maintenance is uncertain (compare `git-cliff` at 6,000+).
- **No changelog accumulation.** Each run replaces previous output; there is no `--prepend`/append mode, so maintaining a running `CHANGELOG.md` requires scripting on top.
- **Docs vs. reality gap.** The Action docs create the impression `--output` is a binary flag. It is not.

### Docs vs. reality

The README covers installation and the GitHub Action well, but the CLI itself is barely documented — no man page, no extended help, no CLI-only examples. The linked `config_example.yaml` is the most useful secondary documentation for grouping and filtering. The "version beta" string and the implied `--output` flag are the two clearest documentation-quality signals.

## Verdict

**Verdict: Narrow fit, use with clear expectations.**

`changelog-generator` does its one job — emit commits since the last tag to stdout — correctly and with zero friction, as our hands-on run confirmed. If your use case is exactly "run in GitHub Actions, get a text blob for a GitHub Release body," it is a reasonable choice.

Outside that narrow scope, the gaps matter: no output flag, no accumulation mode, no auto-grouping without config, a misleading version string, and an undocumented Go 1.24 requirement combine to make it a rougher experience than the docs imply. The 4-star count is not a disqualifier on its own, but it does mean you are taking on maintenance risk with no ecosystem to fall back on.

For teams already in the GitHub Actions ecosystem wanting GoReleaser-style notes without GoReleaser, it is worth a try. For everyone else, `git-cliff` offers substantially more functionality, better documentation, and a large community at the cost of slightly more initial configuration. For flagship Go CLI release pipelines, start with GoReleaser.
