Title: keepachangelog (hands-on synthesis)
Date: 2026-06-02
Slug: keepachangelog-v2
Ecosystem: Python
Tool_Version: 2.0.0
Experiment: examples/python/keepachangelog/
Tags: keep-a-changelog, python, python-library-cli, parser, release-notes, semantic-versioning, ci-cd
Tool_URL: https://pypi.org/project/keepachangelog/
Summary: Hands-on re-review after driving keepachangelog through the tip-calculator life cycle.


## What I actually ran

Container base image: `python:3.12-slim`. Tool: `keepachangelog 2.0.0` (installed via `pip install keepachangelog==2.0.0`). Experiment directory: `examples/python/keepachangelog/`.

The scenario drove a restaurant tip-calculator app through four life-cycle stages:

1. **No changelog** — v1.0.0 code committed, no `CHANGELOG.md` yet.
2. **Changelog created** — seeded a hand-written Keep a Changelog `CHANGELOG.md` covering v1.0.0; used `keepachangelog show 1.0.0` to extract the release body.
3. **Changelog updated** — added a v2.0.0 entry under `[Unreleased]` by directly editing `CHANGELOG.md`.
4. **Release v2.0.0 and v3.0.0** — `keepachangelog release <version>` promoted `[Unreleased]` to a dated section for each release.

The library API (`to_dict`, `from_dict`) was also exercised in a bonus stage.


## Real output

### After `keepachangelog show 1.0.0` (Stage 2)

```
### Added
- Compute the tip and total for a single restaurant bill.
```

### `CHANGELOG.md` after v2.0.0 release (Stage 4a)

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

### Final `CHANGELOG.md` after v3.0.0 (Stage 4b)

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

The tool correctly updates comparison links on every release, which is a detail that is tedious to maintain by hand.

### Library API output (bonus stage)

```
Versions found: ['3.0.0', '2.0.0', '1.0.0']
v3.0.0 sections: ['metadata', 'added']
Round-trip Markdown length: 760 chars
```

`to_dict` parsed all three releases correctly; `from_dict` round-tripped back to valid Markdown.


## Pros (observed)

- **`keepachangelog release` works cleanly and is non-destructive.** It promotes `[Unreleased]` content, stamps today's date, and rewrites comparison links in one command. There is no config file to maintain.
- **`keepachangelog show <version>` is genuinely useful.** The extracted body is clean, section-formatted Markdown suitable for pasting directly into a GitHub release or CI artifact.
- **Comparison links are auto-maintained.** Both the `[Unreleased]` pointer and the new version link are updated on every `release` call — an easy thing to forget by hand.
- **Library API (`to_dict`/`from_dict`) is a real feature.** Parsing three versioned sections back to a Python dict worked without configuration. Round-tripping to Markdown preserves structure.
- **Zero config.** No `pyproject.toml` block, no config file, no init step. Works on any well-formed Keep a Changelog file out of the box.


## Cons / pain points (observed)

- **`keepachangelog show Unreleased` crashes with a `TypeError`.** When the `[Unreleased]` section exists but has no sub-entries, `keepachangelog show Unreleased CHANGELOG.md` raises `TypeError: 'NoneType' object is not subscriptable` in `__main__.py`. This is a real bug in 2.0.0 — using `show` to preview pending notes fails exactly when the section is freshest. The command exits non-zero, which breaks automation.
- **CLI argument syntax is inconsistent.** `keepachangelog show <version>` takes no file argument (reads `CHANGELOG.md` in the current directory implicitly), but the docs imply a path. Discovering the actual interface requires reading the source; the error messages from the arg parser are not helpful.
- **Manual editing is the entire input workflow.** There is no `add` subcommand. Every change entry must be hand-typed into `CHANGELOG.md` under `[Unreleased]`. For multi-contributor projects this is a discipline problem, not a tooling solution.
- **`keepachangelog release` prints only the version number.** It outputs `2.0.0` on success with no confirmation message. Combined with the crashes on `show`, the CLI feels rough around the edges.
- **No draft/preview for upcoming release.** There is no equivalent of `towncrier build --draft` to preview what `release` will produce before committing. You get the result when you run it.


## Docs vs. reality

The original `keepachangelog.md` accurately described the tool's purpose and positioning. The API and `release` command behave as documented.

What the original article did not capture:

- The `show Unreleased` crash is a significant usability bug absent from the docs.
- The CLI argument surface is narrow and somewhat opaque; neither `show` nor `release` accepts an explicit file path as a second positional argument (the error message implies otherwise).
- The library API working reliably (`to_dict`/`from_dict` round-trip) is a genuine strength worth highlighting more.


## Revised verdict

**Verdict: Situational (confirmed, with a bug caveat)**

The tool does what it claims for the release-promotion workflow: `keepachangelog release` is reliable and auto-maintains comparison links. The Python API for parsing changelog structure works well.

The `show Unreleased` crash is a real footgun. Any automation that previews pending entries before release will hit it. Until that is fixed upstream, script callers should handle the non-zero exit defensively.

The original verdict — best for projects already committed to a hand-authored changelog — stands. Do not choose this tool if contributors need to record changes without manually editing a Markdown file; for that, fragment tools are better suited.
