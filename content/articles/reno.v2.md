Title: reno (hands-on synthesis)
Date: 2026-06-02
Slug: reno-v2
Ecosystem: Python
Tool_Version: 4.1.0
Experiment: examples/python/reno/
Tags: news-fragments, python, python-cli-sphinx, release-notes, sphinx, git-tags, branch-aware, ci-cd
Tool_URL: https://pypi.org/project/reno/
Summary: Hands-on re-review after driving reno through the tip-calculator life cycle.


## What I actually ran

Container base image: `python:3.12-slim`. Tool: `reno 4.1.0` (installed via `pip install reno==4.1.0`). Experiment directory: `examples/python/reno/`.

The scenario drove a restaurant tip-calculator app through four life-cycle stages:

1. **No release notes** — v1.0.0 code committed, no notes yet.
2. **Notes created** — `reno new initial-release` created a unique YAML file under `releasenotes/notes/`; the YAML was overwritten with pre-written content; committed + tagged `1.0.0`; `reno report` generated the first RST report.
3. **Notes updated** — `reno new even-split` created a second note for the v2.0.0 feature; committed.
4. **Release v2.0.0 and v3.0.0** — tagged `2.0.0`; `reno report` associated the new note with that tag automatically; same pattern for v3.0.0.

A `reno lint` CI check was run at the end.

**Important:** Reno does not produce a `CHANGELOG.md`. Its output format is reStructuredText (RST), and it generates reports by scanning git history and tags. The `out/CHANGELOG.md` artifact in this experiment contains the RST report text.


## Real output

### `reno report` after tagging v1.0.0 (Stage 2)

```rst
=============
Release Notes
=============

.. _Release Notes_1.0.0:

1.0.0
=====

.. _Release Notes_1.0.0_New Features:

New Features
------------

- Compute the tip and total for a single restaurant bill.
  All inputs are hard-coded constants; the program takes no arguments.
```

### `reno report` with v2 note committed but not yet tagged (Stage 3)

```rst
1.0.0-1
=======

New Features
------------

- Split the bill evenly among a fixed number of diners.
  The per-person share is printed alongside the total.

1.0.0
=====

New Features
------------

- Compute the tip and total for a single restaurant bill.
```

Reno shows unreleased notes under a provisional `1.0.0-1` heading until a new tag is created.

### Final `reno report` after all three tags (Stage 4b)

```rst
3.0.0
=====

New Features
------------

- Split the bill unevenly by per-person weights.
  Output now lists each diner's individual share on its own line.

Upgrade Notes
-------------

- The output format changed: each diner's share is now printed on a separate
  line instead of a single summary line. Scripts parsing stdout must be updated.

2.0.0
=====

New Features
------------

- Split the bill evenly among a fixed number of diners.
  The per-person share is printed alongside the total.

1.0.0
=====

New Features
------------

- Compute the tip and total for a single restaurant bill.
  All inputs are hard-coded constants; the program takes no arguments.
```

The multi-section v3.0.0 note (features + upgrade) rendered correctly without any extra configuration.

### `reno lint` output (bonus stage)

```
no configuration file in: ./releasenotes/config.yaml, ./reno.yaml
scanning ./releasenotes/notes (branch=*current* earliest_version=None ...)
including entire branch history
000001 ... updating current version to 3.0.0
3c2151749025afd1: adding releasenotes/notes/uneven-split-3c2151749025afd1.yaml from 3.0.0
000002 ... updating current version to 2.0.0
...
```

`reno lint` scanned all commits and passed with no validation errors.


## Pros (observed)

- **Tag-based association works automatically and correctly.** Notes committed before a tag are assigned to that version without any explicit command. Tags `1.0.0`, `2.0.0`, and `3.0.0` were all associated correctly; the report required no arguments beyond `reno report`.
- **Multi-section notes work with no config.** The v3.0.0 note had both `features` and `upgrade` sections. Both rendered to separate RST sections (`New Features` and `Upgrade Notes`) with no extra configuration.
- **Unreleased notes get a provisional label, not an error.** When a note is committed but no tag has been created yet, reno labels the section `<last-tag>-1` (e.g., `1.0.0-1`) rather than failing. This makes work-in-progress notes visible in reports without breaking anything.
- **`reno lint` is a good CI gate.** It scanned three releases and found no issues. The verbose scan output shows exactly which commit each note was attributed to, making it easy to debug attribution problems.
- **`reno new` creates uniquely-named files.** The suffix (e.g., `initial-release-5e74fc2f67b51388.yaml`) ensures no filename collision across branches or contributors. This solves the merge-conflict problem that plagues tools using sequential numbering.
- **Structured sections express semantics that plain changelog bullets cannot.** A note with both `features` and `upgrade` sections communicates intent more precisely than a `### Breaking` entry in a KAC file.


## Cons / pain points (observed)

- **RST output is a hard barrier for Markdown-first projects.** Every section, heading, and anchor in the generated report is RST. Teams not already using Sphinx have no use for this output format. There is no built-in Markdown output mode.
- **No config file = repeated warnings.** Every `reno` command printed `no configuration file in: ./releasenotes/config.yaml, ./reno.yaml`. This is informational, not fatal, but it is noise in every CI log. Creating a minimal `reno.yaml` silences it.
- **`reno --version` does not exist.** The `--version` flag is not implemented; the version must be read from the package metadata (`python -c "import reno; print(reno.__version__)"`). A cosmetic gap, but an annoying one for scripting.
- **Note content is YAML, not plain text.** Contributors must write valid YAML with pipe-literal blocks (`- |`) to get multi-line text. A missing `|`, a wrong indent, or a stray colon will produce a confusing parse error or silently empty section. For teams unfamiliar with YAML block scalars, this is a real friction point.
- **The tag must come *after* the note commit.** If a release is tagged before the notes are committed, those notes land in the next version's report (or in an unreleased section). This ordering requirement is easy to violate in a fast release workflow and is not enforced by the tool.
- **`releasenotes/notes/` accumulates all note files forever.** Unlike towncrier or scriv, reno never deletes note files. After many releases, the directory fills with hundreds of YAML files. Navigation and grep become less useful. This is intentional (full history is preserved), but teams should be aware.
- **`reno report` has no `--output` flag in the common invocation.** Capturing the output to a file requires shell redirection (`reno report > file.rst`). There is no `--output` option documented for simple cases.


## Docs vs. reality

The original `reno.md` correctly described reno as a tool designed for OpenStack-scale projects with Sphinx documentation. Every major feature — note files, YAML sections, `reno report`, `reno lint`, `reno semver-next` — was accurately described.

What the original article did not convey:

- The provisional `<tag>-N` heading for unreleased notes is a useful behavior that deserves mention as a feature, not just documentation noise.
- The YAML block scalar requirement is a genuine contributor friction point. The original article described YAML sections but did not highlight the `- |` gotcha.
- The no-configuration warning on every command is a realistic friction point in production use.
- The tag-ordering constraint (note must be committed before the tag) is critical and should be in any usage guide.


## Revised verdict

**Verdict: Situational (confirmed, narrower fit than the original article suggested)**

Reno works exactly as designed. For a Sphinx-based project with stable branches, long support windows, and a dedicated documentation site, it is the right tool. The YAML note format, RST output, and git-history scanning all compose into a coherent system at that scale.

For a typical Python package — Markdown README, GitHub releases, no Sphinx docs, no stable branches — reno introduces meaningful overhead: YAML block scalars, RST output that must be converted for GitHub, configuration needed to silence noise, and a tag-ordering discipline that is easy to violate. The lighter fragment tools (scriv, towncrier) serve that use case better.

The original Situational verdict is confirmed, but the niche is narrower in practice than it reads on paper.
