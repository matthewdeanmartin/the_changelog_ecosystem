Title: keepachangelog-manager-fork (hands-on synthesis)
Date: 2026-06-02
Slug: keepachangelog-manager-v2
Ecosystem: Python
Tool_Version: 5.2.0
Experiment: examples/python/keepachangelog-manager/
Tags: keep-a-changelog, python, python-cli, validation, release-notes, github-integration, ci-cd, multi-component
Tool_URL: https://pypi.org/project/keepachangelog-manager-fork/
Summary: Hands-on re-review after driving keepachangelog-manager-fork through the tip-calculator life cycle.


## What I actually ran

Container base image: `python:3.12-slim`. Tool: `keepachangelog-manager-fork 5.2.0` (installed via `pip install keepachangelog-manager-fork==5.2.0`). The CLI entry point is `changelogmanager`. Experiment directory: `examples/python/keepachangelog-manager/`.

**Note:** This review uses the maintained fork (`matthewdeanmartin/keepachangelog-manager`, PyPI: `keepachangelog-manager-fork`), not the archived original (`tomtom-international/keepachangelog-manager`). The fork is the only version receiving active development and should be the default recommendation.

The scenario drove a restaurant tip-calculator app through four life-cycle stages:

1. **No changelog** — v1.0.0 code committed, no `CHANGELOG.md` yet.
2. **Changelog created** — `changelogmanager create` produced the skeleton; `changelogmanager add` added the v1.0.0 entry; `changelogmanager release --override-version 1.0.0 --yes` promoted it.
3. **Changelog updated** — `changelogmanager add` recorded the v2.0.0 feature under `[Unreleased]`.
4. **Release v2.0.0 and v3.0.0** — `changelogmanager release --override-version <version> --yes` for each.


## Real output

### `CHANGELOG.md` after `changelogmanager create` + `add` (Stage 2 mid-point)

```markdown
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Compute the tip and total for a single restaurant bill.
```

### `CHANGELOG.md` after v2.0.0 release (Stage 4a)

```markdown
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-06-02
### Added
- Split the bill evenly among a fixed number of diners.

## [1.0.0] - 2026-06-02
### Added
- Compute the tip and total for a single restaurant bill.
```

### Final `CHANGELOG.md` after v3.0.0 (Stage 4b)

```markdown
## [3.0.0] - 2026-06-02
### Added
- Split the bill unevenly using per-person weights; output now lists each diner's share.

## [2.0.0] - 2026-06-02
### Added
- Split the bill evenly among a fixed number of diners.

## [1.0.0] - 2026-06-02
### Added
- Compute the tip and total for a single restaurant bill.
```

`release` stdout: `Released 2.0.0` — clean, one-line confirmation.


## Pros (observed)

- **`changelogmanager create` + `add` + `release` is a coherent three-command workflow.** No manual `CHANGELOG.md` editing is required. Each command has a clear, single responsibility.
- **`add` is the standout feature over the plain `keepachangelog` library.** Having a command that places a formatted bullet under the right section removes the most common human error in manual changelog workflows.
- **`release --yes` is non-interactive and automation-safe.** The `--yes` flag skips the confirmation prompt cleanly; `--override-version` pins the version so CI pipelines do not need to infer it.
- **`release` prints a clear confirmation.** `Released 2.0.0` on stdout is enough for a CI log to confirm success without parsing file output.
- **Installs on Python 3.12 without issues.** The dependency tree (inquirer, blessed, etc.) resolved cleanly.
- **Generates the `[Unreleased]` header.** The `create` output follows Keep a Changelog 1.1.0 conventions, which is a minor but meaningful format update over the older 1.0.0 spec.


## Cons / pain points (observed)

- **`[Unreleased]` section is dropped after `release`.** After `changelogmanager release`, the `[Unreleased]` section does not reappear in the file. The plain `keepachangelog` library preserves an empty `[Unreleased]` header; `changelogmanager` removes it. This is a footgun for teams that run `validate` against a released changelog and expect the section to be there, or for CI rules that assert its presence.
- **No comparison links are generated.** Unlike `keepachangelog release`, the fork does not maintain `[x.y.z]: https://...compare/...` link definitions at the bottom of the file. A strict KAC validator would flag the output as incomplete.
- **Version is not auto-detected from `pyproject.toml`.** `release` without `--override-version` attempts to infer the version automatically, but in the experiment it required `--override-version` to pin correctly. For projects that update `pyproject.toml` first, auto-detection might work — but this was not observed.
- **`--version` is not exposed.** Running `changelogmanager --version` fails. Verifying the installed version requires `pip show keepachangelog-manager-fork`.
- **Output format differs from the original library.** `create` generates `## [Unreleased]\n### Added\n` with no blank line after the header. The `keepachangelog` library writes with blank lines between sections. Both are valid KAC, but the two tools produce subtly different whitespace that can cause noisy diffs when switching between them.


## Docs vs. reality

The original `keepachangelog-manager.md` correctly identified the fork as the maintained package and described its command set. The workflow-oriented CLI description matched what was observed.

What the original article did not capture:

- The missing `[Unreleased]` section after `release` is a real behavior gap vs. the KAC spec.
- No comparison links are maintained — this is a significant difference from the plain `keepachangelog` library that the article does not call out.
- The `--section` flag mentioned conceptually does not exist; the actual flag is `--change-type` with lowercase type names.
- The `--yes` flag is essential for non-interactive use and should be prominent in any CI usage example.


## Revised verdict

**Verdict: Situational (confirmed, with format caveats)**

`keepachangelog-manager-fork` delivers on its core promise: a CLI workflow that avoids hand-editing `CHANGELOG.md`. The `create`/`add`/`release` triad is clean, non-interactive with `--yes`, and suitable for CI pipelines.

The two format gaps (no `[Unreleased]` after release, no comparison links) make the output non-compliant with a strict reading of the KAC spec and incompatible with the plain `keepachangelog` library's output style. Projects that need those features should add a post-release step to restore the `[Unreleased]` header and maintain link definitions manually or with another tool.

Prefer the fork over the archived `tomtom-international/keepachangelog-manager`; the fork is the only version worth considering.
