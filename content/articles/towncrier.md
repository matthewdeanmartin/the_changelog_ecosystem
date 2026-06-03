Title: towncrier
Date: 2026-06-02
Slug: towncrier
Ecosystem: Python
Tags: keep-a-changelog, news-fragments, python, python-cli, release-notes, custom-templates, ci-cd, hands-on
Tool_URL: https://pypi.org/project/towncrier/
Tool_Version: 24.8.0
Tool_Status: active
Experiment: examples/python/towncrier/
Summary: The canonical Python news-fragment tool — hands-on testing confirms human-facing output, a real draft preview, and a working CI gate, with a couple of git-coupling papercuts.



## Overview

`towncrier` is the canonical Python news-fragment tool: each user-visible change is written as a small file alongside the code change, then collected into release notes when the project cuts a release. It is strongest for libraries and frameworks where contributors should explain the user impact before the maintainer is assembling the final changelog.

The tool distinguishes itself by being mature, configurable, and strict enough to work as a release gate. It is less about reading git history after the fact and more about making release-note writing part of the contribution workflow.

A reproducible hands-on experiment for this tool lives in [`examples/python/towncrier/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/towncrier). The real output shown later in this article comes from that run.

## Installation

```bash
pip install towncrier
# or with uv:
uv add towncrier
```

## What It Does

- Creates individual news fragments such as `123.feature` or `456.bugfix`, usually stored in a `newsfragments` directory.
- Collects fragments into a project news file, commonly `NEWS.rst`, `NEWS.md`, or `CHANGELOG.md`.
- Supports Markdown and reStructuredText templates, with a Markdown-specific release-note start marker when the output file ends in `.md`.
- Lets projects define fragment categories such as features, bug fixes, removals, docs, or project-specific types.
- Provides `towncrier check` so CI can reject pull requests that forget a required user-facing note.

## Configuration

Towncrier reads TOML configuration from `pyproject.toml` or `towncrier.toml` under `[tool.towncrier]`. A minimal Python package can start with just the package name; Towncrier can infer the display name and version from installed package metadata or a package `__version__`.

```toml
[tool.towncrier]
package = "myproject"
filename = "CHANGELOG.md"
directory = "newsfragments"
issue_format = "[#{issue}](https://github.com/example/myproject/issues/{issue})"

[[tool.towncrier.type]]
directory = "feature"
name = "Features"
showcontent = true

[[tool.towncrier.type]]
directory = "bugfix"
name = "Bug Fixes"
showcontent = true
```

First-run setup is moderate: you need to pick a fragment directory, decide whether output is Markdown or reStructuredText, and agree on fragment categories. After that, contributor ergonomics are simple: add a short fragment file with the change. (One operational note confirmed in testing: fragments must be git-committed before `towncrier build`, and the empty `newsfragments/` directory benefits from a `.gitkeep` — see the hands-on findings below.)

## Output Quality

Towncrier output is intentionally human-facing, not a raw commit log: stable `## version` and `### category` headings, issue links, and no commit noise. The quality depends on fragment discipline — if contributors write good fragments, Towncrier produces clean release notes; if they write vague fragments, it will faithfully preserve the vagueness. See the **Hands-on findings** section below for the exact, real output produced when driving a sample project through three releases.

## Ecosystem Fit

Towncrier feels very native to Python packaging. It lives comfortably in `pyproject.toml`, works with `pip`, `uv`, `tox`, `nox`, and pre-commit-style checks, and it is already familiar in established Python projects that care about release notes as documentation.

Its model is especially good for contributor-heavy open source projects. Small applications with one maintainer may find the fragment ceremony heavier than a direct `CHANGELOG.md` edit.

## Maintenance Status

- Latest published version: **25.8.0** (last release 2025-08-30); the hands-on experiment pinned **24.8.0**.
- GitHub stars: **899**
- Appears actively maintained.
- Repository: <a href="https://github.com/twisted/towncrier" target="_blank" rel="noopener noreferrer">https://github.com/twisted/towncrier</a>

Towncrier has a long maintenance history and current documentation for modern `pyproject.toml` configuration, custom fragment types, Markdown output, and CI checks.

---

## Hands-on findings

This is a second-pass review grounded in *running* towncrier, not reading its docs. The reproducible experiment lives in [`examples/python/towncrier/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/towncrier). All output below is **real**, captured from that run.

### What I actually ran

- **Base image:** `python:3.12-slim`
- **Tool version:** `towncrier 24.8.0` (pinned in the Dockerfile)
- **Fixture:** a trivial all-constants "restaurant tip calculator" CLI, so all the interesting behavior is in the tool, not the app.
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code, **no changelog**.
  2. Configure towncrier, add a news fragment, **build the first changelog**.
  3. Implement an even-split feature (2.0.0), add a fragment, **preview** with `--draft`.
  4. **Bump + release** 2.0.0, then loop again for an uneven-split 3.0.0.

Seven commits and three tags (`v1.0.0`, `v2.0.0`, `v3.0.0`) were created entirely inside the container — nothing touched the review site's own repo.

### Real output

The generated `CHANGELOG.md` after the full run (newest-first, exactly as towncrier wrote it):

```markdown
## 3.0.0 (2026-03-01)

### Features

- Split the bill unevenly using per-person weights. Output now lists each diner's share on its own line. (#3)


## 2.0.0 (2026-02-01)

### Features

- Split the bill evenly among a fixed number of diners. (#2)


## 1.0.0 (2026-01-01)

### Features

- Compute the tip and total for a single restaurant bill. (#1)
```

The `--draft` preview at stage 3 printed the pending 2.0.0 notes **without** consuming the fragment:

```text
Draft only -- nothing has been written.
What is seen below is what would be written.

## 2.0.0 (...)

### Features

- Split the bill evenly among a fixed number of diners. (#2)
```

And `towncrier check --compare-with v2.0.0` correctly located the new fragment before the 3.0.0 release — the CI gate works as advertised.

### Pros (observed)

- **Output is genuinely user-facing.** Stable `## version` / `### category` headings, issue links, no raw commit noise. The docs' central claim held up exactly.
- **`--draft` is a real workflow feature**, not a footnote: you can render the *next* release's notes at PR time without mutating anything.
- **`towncrier check --compare-with <ref>` is a working CI gate** — it found the pending fragment against the previous tag.
- **Deterministic builds** via `--date` and explicit `--version`, which made the run reproducible.
- **Newest-first prepend is correct** and needs no manual ordering.

### Cons / pain points (observed)

These only surfaced by actually running the life cycle:

- **Fragments must be git-committed *before* `towncrier build`.** Towncrier deletes consumed fragments with `git rm`; if they are untracked, the build prints a scary `fatal: No pathspec was given. Which files should I remove?` partway through. It still finishes, but a strict CI step keying on stderr/exit noise could trip on it. The fix is simply to commit fragments first.
- **The `newsfragments/` directory vanishes after a build.** Towncrier empties it and git does not track empty directories, so each subsequent stage had to recreate it. In a real project you would drop a `.gitkeep` in there.
- **`check` inspects the whole working tree.** Stray `__pycache__/*.pyc` files showed up in its file list until the app got a `.gitignore` — a reminder to keep the tree clean.
- **No free version inference in a minimal project.** We passed `--version` explicitly; metadata-based inference needs the package actually installed.

### Docs vs. reality

The original description is accurate where it counts: output is human-facing, configuration lives in `pyproject.toml`, and `check` works as a release gate. What no doc-derived review captured — and what the hands-on run exposed — is the **git coupling**: fragments-must-be-tracked-before-build and the empty-directory disappearance. Those are exactly the kind of first-run papercuts a maintainer hits and a docs-summary misses.

## Verdict

**Verdict: Recommended (unchanged)**

Running it end-to-end reinforced the original rating rather than altering it. The two caveats are operational, not architectural, and both have one-line fixes (commit fragments first; keep `newsfragments/.gitkeep`).

Use Towncrier when a Python project wants contributors to record user-visible changes as part of the patch, especially for libraries, frameworks, and projects with many external contributors. It is not the lightest option, but it is the Python baseline for news-fragment workflows and belongs near the top of any changelog-tool shortlist.
