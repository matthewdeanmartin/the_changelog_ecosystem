Title: GitHub/GitLab + git-cliff/Changie pattern
Date: 2026-05-31
Slug: github-gitlab-git-cliff-changie-pattern
Ecosystem: Cpp
Tags: backfill, conventional-commits, cpp, github-integration, gitlab-integration, news-fragments, workflow-pattern
Tool_URL: https://git-cliff.org/
Tool_Version: unknown
Tool_Status: active
Summary: For C and C++, the must-review ecosystem is mostly language-agnostic: git-cliff for commit-derived logs, Changie for fragments, and GitHub/GitLab release tooling for publication.



## Overview

C and C++ do not have one dominant package-manager-owned changelog workflow. The practical pattern is to choose a language-agnostic note source, usually git-cliff for commit-derived logs or Changie for change fragments, then publish through GitHub Releases, GitLab Releases, package registries, or project documentation.

This article is a workflow recommendation rather than a single tool review.

## Installation

Install the tools that match the chosen workflow:

```bash
cargo install git-cliff
go install github.com/miniscruff/changie@latest
```

For publication, use the hosting platform CLI or API, such as `gh release` or `glab release`.

## What It Does

- Uses git-cliff when Conventional Commits or custom commit parsers are the source of truth.
- Uses Changie when each pull request should add an explicit change fragment.
- Publishes release notes through GitHub or GitLab release tooling.
- Works with CMake, Meson, Make, Conan, vcpkg, distro packages, and source tarballs because the changelog layer is separate from the build system.
- Can backfill old releases from tags when git history is consistent.

## Configuration

For commit-derived notes, configure `cliff.toml`:

```toml
[git]
conventional_commits = true
filter_unconventional = true
tag_pattern = "v[0-9]*"
```

For fragment-based notes, configure Changie categories and keep fragments in the repository:

```yaml
changesDir: .changes
kinds:
  - label: Added
    auto: minor
  - label: Fixed
    auto: patch
```

First-run setup is less about C++ and more about team behavior: either commits must be structured, or contributors must add fragments.

## Output Quality

Both routes can produce clear release notes:

```markdown
## v2.1.0 - 2026-05-31

### Added

- Add CMake package config generation for shared builds.

### Fixed

- Correct symbol visibility on Windows DLL exports.
```

Fragment workflows usually produce more intentional prose. Commit-derived workflows are easier to automate and backfill.

## Ecosystem Fit

This pattern fits C and C++ precisely because it does not assume a single package manager. It works for libraries published as source archives, projects with native packages, and mixed repositories with bindings in other languages.

The tradeoff is that version bumping and artifact publishing remain separate. Tools such as CMake, Conan, vcpkg, GitHub Actions, and GitLab CI still need their own release steps.

## Maintenance Status

- Latest version: **unknown**
- Last release: **unknown**
- Appears actively maintained.

The pattern depends on active external tools rather than one package. Check the individual git-cliff, Changie, GitHub, and GitLab reviews before final selection.

## Verdict

**Verdict: Recommended**

For C and C++, start by choosing between git-cliff and Changie, then wire the output into GitHub or GitLab release publication. That keeps changelog policy independent from the project's build and packaging stack.
