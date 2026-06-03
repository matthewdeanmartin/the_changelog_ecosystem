Title: keepachangelog
Date: 2026-06-02
Slug: keepachangelog
Ecosystem: Python
Tags: keep-a-changelog, python, python-library-cli, parser, release-notes, semantic-versioning, ci-cd, hands-on
Tool_URL: https://pypi.org/project/keepachangelog/
Tool_Version: 2.0.0
Tool_Status: active
Experiment: examples/python/keepachangelog/
Summary: Python library/CLI for parsing, generating, and releasing Keep a Changelog files — hands-on testing confirms reliable release promotion with one notable `show Unreleased` bug.



## Overview

`keepachangelog` is a Python library and small CLI for projects that already maintain a Keep a Changelog-style `CHANGELOG.md`. Instead of generating notes from commits or fragments, it parses the changelog into structured data, renders it back to Markdown, and can promote the `[Unreleased]` section into a numbered release.

That makes it useful for automation around a hand-written changelog: CI can extract a release body, a web service can expose changelog JSON, and a release job can update comparison links consistently.

A reproducible hands-on experiment for this tool lives in [`examples/python/keepachangelog/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/keepachangelog). The real output shown later in this article comes from that run.

## Installation

```bash
pip install keepachangelog
# or with uv:
uv add keepachangelog
```

## What It Does

- Parses a Keep a Changelog Markdown file into a Python dictionary.
- Renders structured changelog data back into Keep a Changelog Markdown.
- Provides `keepachangelog show VERSION` to extract release text for publishing.
- Provides `keepachangelog release [VERSION]` to move `[Unreleased]` content into a new release section.
- Guesses the next version when one is not supplied: breaking-style sections push major, only `Fixed` pushes patch, and other changes push minor.

## Configuration

There is no project configuration file to maintain. The tool expects a conventional Keep a Changelog document, then operates on `CHANGELOG.md` by default. (Note: in hands-on testing the CLI subcommands do *not* accept an explicit file path as a positional argument — they read `CHANGELOG.md` from the current working directory. See the hands-on findings below.)

```bash
NEW_VERSION=$(keepachangelog release)
GITHUB_RELEASE_BODY=$(keepachangelog show "$NEW_VERSION")
```

For library use, the API is direct:

```python
import keepachangelog

changes = keepachangelog.to_dict("CHANGELOG.md")
content = keepachangelog.from_dict(changes)
new_version = keepachangelog.release("CHANGELOG.md")
```

First-run complexity is low if the changelog already follows the expected format. The hard part is not configuring the package; it is keeping the source changelog structured enough to parse reliably.

## Output Quality

Because `keepachangelog` operates on hand-written changelog text, output quality mostly mirrors the input. This is not a prose-improving generator, but it is good at preserving a human-authored changelog while automating the release mechanics — promoting `[Unreleased]` to a dated, versioned section and rewriting comparison links. See the **Hands-on findings** section below for the exact, real output produced when driving a sample project through several releases.

## Ecosystem Fit

The package fits Python automation nicely because it is both importable and scriptable. It can sit inside a `uv run` release script, a GitHub Actions job, or a small API endpoint that exposes changelog data to a documentation site or service.

It does not replace Towncrier, Scriv, or Reno for teams that need contributor fragments. It complements manual changelog authoring and works best when the project already believes in Keep a Changelog.

## Maintenance Status

- Latest version: **2.0.0**
- Last release: **2024-06-14**
- GitHub stars: **51**
- Appears actively maintained.
- Repository: <a href="https://github.com/Colin-b/keepachangelog" target="_blank" rel="noopener noreferrer">https://github.com/Colin-b/keepachangelog</a>

The project documents CLI and library usage, including release creation, release body extraction, Markdown conversion, and optional web endpoints for Starlette and Flask-RestX.

---

## Hands-on findings

A reproducible experiment lives in [`examples/python/keepachangelog/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/keepachangelog). All output below is **real**, captured from that run — not hypothetical.

### What I actually ran

Container base image: `python:3.12-slim`. Tool: `keepachangelog 2.0.0` (installed via `pip install keepachangelog==2.0.0`). The scenario drove a restaurant tip-calculator app through four life-cycle stages:

1. **No changelog** — v1.0.0 code committed, no `CHANGELOG.md` yet.
2. **Changelog created** — seeded a hand-written Keep a Changelog `CHANGELOG.md` covering v1.0.0; used `keepachangelog show 1.0.0` to extract the release body.
3. **Changelog updated** — added a v2.0.0 entry under `[Unreleased]` by directly editing `CHANGELOG.md`.
4. **Release v2.0.0 and v3.0.0** — `keepachangelog release <version>` promoted `[Unreleased]` to a dated section for each release.

The library API (`to_dict`, `from_dict`) was also exercised in a bonus stage.

### Real output

`keepachangelog show 1.0.0` (Stage 2):

```
### Added
- Compute the tip and total for a single restaurant bill.
```

`CHANGELOG.md` after the v2.0.0 release (Stage 4a):

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-06-02

### Added

- Split the bill evenly among a fixed number of diners.


## [1.0.0] - 2026-01-01

### Added

- Compute the tip and total for a single restaurant bill.

[Unreleased]: https://github.com/example/tipcalc/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/example/tipcalc/releases/tag/v1.0.0
```

Final `CHANGELOG.md` after v3.0.0 (Stage 4b):

```markdown
## [Unreleased]

## [3.0.0] - 2026-06-02

### Added

- Split the bill unevenly using per-person weights; output now lists each diner's share.

## [2.0.0] - 2026-06-02

### Added

- Split the bill evenly among a fixed number of diners.

## [1.0.0] - 2026-01-01

### Added

- Compute the tip and total for a single restaurant bill.

[Unreleased]: https://github.com/example/tipcalc/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/example/tipcalc/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/example/tipcalc/releases/tag/v1.0.0
```

The tool correctly updates comparison links on every release — a detail that is tedious to maintain by hand.

Library API output (bonus stage):

```
Versions found: ['3.0.0', '2.0.0', '1.0.0']
v3.0.0 sections: ['metadata', 'added']
Round-trip Markdown length: 760 chars
```

`to_dict` parsed all three releases correctly; `from_dict` round-tripped back to valid Markdown.

### Pros (observed)

- **`keepachangelog release` works cleanly and is non-destructive.** It promotes `[Unreleased]` content, stamps today's date, and rewrites comparison links in one command. There is no config file to maintain.
- **`keepachangelog show <version>` is genuinely useful.** The extracted body is clean, section-formatted Markdown suitable for pasting directly into a GitHub release or CI artifact.
- **Comparison links are auto-maintained.** Both the `[Unreleased]` pointer and the new version link are updated on every `release` call — an easy thing to forget by hand.
- **Library API (`to_dict`/`from_dict`) is a real feature.** Parsing three versioned sections back to a Python dict worked without configuration; round-tripping to Markdown preserves structure.
- **Zero config.** No `pyproject.toml` block, no config file, no init step. Works on any well-formed Keep a Changelog file out of the box.

### Cons / pain points (observed)

- **`keepachangelog show Unreleased` crashes with a `TypeError`.** When the `[Unreleased]` section exists but has no sub-entries, `keepachangelog show Unreleased CHANGELOG.md` raises `TypeError: 'NoneType' object is not subscriptable` in `__main__.py`. This is a real bug in 2.0.0 — using `show` to preview pending notes fails exactly when the section is freshest. The command exits non-zero, which breaks automation.
- **CLI argument syntax is inconsistent.** Neither `show` nor `release` accepts an explicit file path as a second positional argument (passing one yields "unrecognized arguments"); the file is always read from the current directory. Discovering the actual interface requires reading the source.
- **Manual editing is the entire input workflow.** There is no `add` subcommand. Every change entry must be hand-typed into `CHANGELOG.md` under `[Unreleased]`. For multi-contributor projects this is a discipline problem, not a tooling solution.
- **`keepachangelog release` prints only the version number.** It outputs `2.0.0` on success with no confirmation message.
- **No draft/preview for upcoming release.** There is no equivalent of `towncrier build --draft` to preview what `release` will produce before committing.

### Docs vs. reality

The original description accurately captured the tool's purpose and positioning, and the API and `release` command behave as documented. What was not captured: the `show Unreleased` crash, the narrow/opaque CLI argument surface, and how solid the `to_dict`/`from_dict` round-trip actually is.

## Verdict

**Verdict: Situational (confirmed, with a bug caveat)**

The tool does what it claims for the release-promotion workflow: `keepachangelog release` is reliable and auto-maintains comparison links, and the Python API for parsing changelog structure works well.

The `show Unreleased` crash is a real footgun. Any automation that previews pending entries before release will hit it. Until that is fixed upstream, script callers should handle the non-zero exit defensively.

The original verdict stands: choose `keepachangelog` when the changelog is already hand-authored and the missing piece is reliable parsing, release extraction, or `[Unreleased]` promotion. Do not choose it if the team needs to collect fragments from contributors or derive notes from commits; that is the job of a different class of tool.
