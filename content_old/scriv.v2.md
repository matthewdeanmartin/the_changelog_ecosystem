Title: scriv (hands-on synthesis)
Date: 2026-06-02
Slug: scriv-v2
Ecosystem: Python
Tool_Version: 1.8.0
Experiment: examples/python/scriv/
Tags: keep-a-changelog, news-fragments, python, python-cli, pyproject-config, custom-templates, github-integration
Tool_URL: https://pypi.org/project/scriv/
Summary: Hands-on re-review after driving scriv through the tip-calculator life cycle.


## What I actually ran

Container base image: `python:3.12-slim`. Tool: `scriv 1.8.0` (installed via `pip install scriv==1.8.0`). Experiment directory: `examples/python/scriv/`.

The scenario drove a restaurant tip-calculator app through four life-cycle stages:

1. **No changelog** — v1.0.0 code committed, no changelog yet.
2. **Changelog created** — appended `[tool.scriv]` config to `pyproject.toml`; dropped a pre-written fragment into `changelog.d/`; `scriv collect` assembled `CHANGELOG.md` for v1.0.0.
3. **Changelog updated** — added a v2.0.0 fragment to `changelog.d/`.
4. **Release v2.0.0 and v3.0.0** — `scriv collect` aggregated pending fragments into `CHANGELOG.md` for each version.

Configuration used:

```toml
[tool.scriv]
format = "md"
changelog = "CHANGELOG.md"
fragment_directory = "changelog.d"
version = "literal: pyproject.toml: project.version"
categories = "Added, Changed, Deprecated, Removed, Fixed, Security"
```


## Real output

### `CHANGELOG.md` after collecting v1.0.0 (Stage 2)

```markdown

<a id='changelog-1.0.0'></a>
# 1.0.0 — 2026-06-02

## Added

- Compute the tip and total for a single restaurant bill.
```

### `CHANGELOG.md` after collecting v2.0.0 (Stage 4a)

```markdown

<a id='changelog-2.0.0'></a>
# 2.0.0 — 2026-06-02

## Added

- Split the bill evenly among a fixed number of diners.

<a id='changelog-1.0.0'></a>
# 1.0.0 — 2026-06-02

## Added

- Compute the tip and total for a single restaurant bill.
```

### Final `CHANGELOG.md` after v3.0.0 (Stage 4b)

```markdown

<a id='changelog-3.0.0'></a>
# 3.0.0 — 2026-06-02

## Added

- Split the bill unevenly using per-person weights; output now lists each diner's share on its own line.

<a id='changelog-2.0.0'></a>
# 2.0.0 — 2026-06-02

## Added

- Split the bill evenly among a fixed number of diners.

<a id='changelog-1.0.0'></a>
# 1.0.0 — 2026-06-02

## Added

- Compute the tip and total for a single restaurant bill.
```

### `scriv collect` stdout (Stage 2)

```
Collecting from changelog.d
Reading changelog CHANGELOG.md
warning: Changelog CHANGELOG.md doesn't exist
Deleting fragment file 'changelog.d/20260101_initial.md'
```

The first-run warning about the changelog not existing is expected and benign; scriv creates the file if it does not exist.


## Pros (observed)

- **`scriv collect` is the entire release step.** No sub-commands, no version argument needed if configured; the version is read from `pyproject.toml` via the `literal:` reference. The command is one word.
- **Version read from `pyproject.toml` works correctly.** Setting `version = "literal: pyproject.toml: project.version"` in `[tool.scriv]` and then updating the `version = "2.0.0"` line in `pyproject.toml` is all that is needed before running `collect`. No separate bump command is required.
- **Fragment deletion is clean.** After `collect`, consumed fragment files are deleted from `changelog.d/`, leaving no clutter. The directory empties completely, which requires a `mkdir -p changelog.d` before the next fragment (a minor gotcha, but documented in the TEMPLATE).
- **Stable HTML anchors are auto-inserted.** Each version heading gets a `<a id='changelog-X.Y.Z'>` anchor automatically. These are useful for deep-linking from release notes or PR descriptions.
- **Markdown output is clean and direct.** Sections map one-to-one from the fragment's headings to the collected changelog. No transformation or RST conversion is involved.
- **Installed with no friction.** The dependency set (click, jinja2, attrs, requests) resolved cleanly on Python 3.12.
- **Warning messages are honest.** On first run, scriv warns about the missing changelog but continues; the message is accurate and non-alarming.


## Cons / pain points (observed)

- **No `draft` mode for previewing before collection.** Towncrier has `towncrier build --draft` to preview without consuming fragments. Scriv has no equivalent; `collect` both assembles the changelog and deletes the fragments in a single step. Previewing requires a manual inspection of `changelog.d/`.
- **Section heading level differs from Keep a Changelog convention.** KAC uses `###` for section names (`### Added`, `### Fixed`). Scriv produces `##` for categories (`## Added`). This is a direct copy from the fragment file's format. If fragments use `##`, the output uses `##`. Teams wanting KAC-style `###` must write their fragment files with `###` headings, which is a bit surprising.
- **No `[Unreleased]` section.** The collected changelog uses version numbers and dates as top-level `#` headings rather than the standard KAC structure with an `[Unreleased]` sentinel. This makes scriv's output different from KAC-aware tools (keepachangelog, keepachangelog-manager) and means the plain `keepachangelog` library cannot parse scriv-generated files.
- **`scriv create` was not needed in this workflow.** The fragment files were pre-written. In practice, contributors run `scriv create` to open an editor and scaffold a new fragment. That interactive step was bypassed by dropping pre-written files — a reminder that the real friction for contributors is writing the fragment content, not running the command.
- **Fragment filenames must be pre-existing or created via `scriv create`.** There is no way to supply fragment content non-interactively via stdin or a flag. CI pipelines that want to inject a fragment programmatically must write a file to `changelog.d/` directly.


## Docs vs. reality

The original `scriv.md` described the tool accurately. The `collect` workflow, `pyproject.toml` config, and stable-anchor output all matched observation.

What the original article understated:

- The heading level difference (`##` vs `###`) is a real interoperability issue with the broader KAC ecosystem and worth calling out explicitly.
- The absence of a draft/preview mode is a practical limitation for maintainers who want to review notes before they are locked in and fragments deleted.
- Scriv's output format is not compatible with the `keepachangelog` parser library — the two tools produce structurally different Markdown.


## Revised verdict

**Verdict: Recommended (confirmed)**

Scriv works as advertised. `collect` is genuinely the simplest way to aggregate fragments into a changelog, and version detection from `pyproject.toml` eliminates a common manual step. The stable anchors are a nice touch for linking from release notes.

The KAC format divergence (no `[Unreleased]`, `##` not `###`) means scriv is its own changelog style rather than a strict KAC implementation. That is fine for teams adopting it fresh, but teams migrating from KAC tooling or pairing with the `keepachangelog` library should be aware.

The Recommended verdict stands: scriv is a solid first choice for Python projects that want news fragments without Towncrier's extra complexity.
