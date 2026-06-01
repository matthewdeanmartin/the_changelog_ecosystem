Title: keepachangelog
Date: 2026-05-31
Slug: keepachangelog
Ecosystem: Python
Tags: keep-a-changelog, python, python-library-cli, parser, release-notes, semantic-versioning, ci-cd
Tool_URL: https://pypi.org/project/keepachangelog/
Tool_Version: 2.0.0
Tool_Status: active
Summary: Python library/CLI for parsing, generating, and releasing Keep a Changelog style changelog files.



## Overview

`keepachangelog` is a Python library and small CLI for projects that already maintain a Keep a Changelog-style `CHANGELOG.md`. Instead of generating notes from commits or fragments, it parses the changelog into structured data, renders it back to Markdown, and can promote the `[Unreleased]` section into a numbered release.

That makes it useful for automation around a hand-written changelog: CI can extract a release body, a web service can expose changelog JSON, and a release job can update comparison links consistently.

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

There is no project configuration file to maintain. The tool expects a conventional Keep a Changelog document, then operates on `CHANGELOG.md` by default or an explicitly provided path.

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

Because `keepachangelog` operates on hand-written changelog text, output quality mostly mirrors the input. A release workflow can turn this:

```markdown
## [Unreleased]

### Added

- Add CSV export for release-note audits.
```

into:

```markdown
## [1.3.0] - 2026-05-31

### Added

- Add CSV export for release-note audits.
```

The result remains clean Keep a Changelog Markdown. This is not a prose-improving generator, but it is good at preserving a human-authored changelog while automating the release mechanics.

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

## Verdict

**Verdict: Situational**

Choose `keepachangelog` when the changelog is already hand-authored and the missing piece is reliable parsing, release extraction, or `[Unreleased]` promotion. Do not choose it if the team needs to collect fragments from contributors or derive notes from commits; that is the job of a different class of tool.
