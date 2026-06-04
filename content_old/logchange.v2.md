Title: logchange (hands-on synthesis)
Date: 2026-06-03
Slug: logchange-v2
Ecosystem: Cross
Tags: cli, cross, keep-a-changelog, news-fragments, release-notes, ci-cd, hands-on
Tool_URL: https://github.com/logchange/logchange
Tool_Version: 1.19.15 (Docker image; `logchange -V` self-reports "null")
Tool_Status: active
Experiment: examples/cross/logchange/
Summary: Hands-on re-review after driving logchange through the tip-calculator life cycle in a container.



## What I actually ran

This is a second-pass review grounded in *running* logchange, not reading its docs. The
reproducible experiment lives in [`examples/cross/logchange/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/cross/logchange).

- **Base image:** `logchange/logchange:1.19.15` (GraalVM native image on Alpine, Java 21
  / Substrate VM) — i.e. the *real published tool* — plus `git` and `python3` via `apk`.
- **Tool version:** the image tag is `1.19.15`; note `logchange -V` reports
  `Logchange version: null` (the native binary does not embed its own version).
- **Fixture:** a trivial all-constants "restaurant tip calculator" CLI, so all the
  interesting behavior is in the tool, not the app.
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code, **no changelog**.
  2. `logchange init`, add a YAML change entry, `lint`, `generate`, then
     `release --versionToRelease 1.0.0`.
  3. Implement an even-split feature (2.0.0), add an entry, `generate` to **preview** it
     under `[unreleased]`.
  4. `release` 2.0.0, then loop again for an uneven-split 3.0.0 that flags a breaking
     output-shape change via `important_notes`.

Six commits and three tags (`v1.0.0`, `v2.0.0`, `v3.0.0`) were created entirely inside
the container — nothing touched the review site's own repo. **No GitHub or GitLab token,
and no network, were needed**: logchange is a fully local, offline CLI.

## logchange's model (as observed)

- `logchange init` writes `changelog/logchange-config.yml` and `changelog/unreleased/.gitkeep`.
- Each change is **one YAML file** in `changelog/unreleased/` — `title` and `type` are
  the only required fields (optional: `authors`, `issues`, `merge_requests`, `links`,
  `important_notes`, `configurations`).
- `logchange lint` validates the entries and config — a clean CI gate.
- `logchange generate` (re)writes `CHANGELOG.md`. It is **non-destructive**: pending
  entries render under `[unreleased]` and nothing moves.
- `logchange release --versionToRelease X --releaseDate Y` **renames**
  `changelog/unreleased/` to `changelog/vX/`, writes `release-date.txt`, and recreates a
  fresh `unreleased/`.

The release model is unusually legible: an unreleased change is literally a file, and
"releasing" is literally a directory rename. The version is a CLI flag, so logchange is
decoupled from any ecosystem's project file — the Python fixture here was incidental.

## Real output

The generated `CHANGELOG.md` after the full run, exactly as logchange wrote it (the
auto-generated header comments and the loud "DO NOT MODIFY THIS FILE" banner are trimmed):

```markdown
[unreleased]
------------


[3.0.0] - 2026-03-01
--------------------

### Important notes

- Output shape changed: totals are now printed one line per diner.

### Changed (1 change)

- Split the bill unevenly using per-person weights


[2.0.0] - 2026-02-01
--------------------

### Added (1 change)

- Split the bill evenly among a fixed number of diners


[1.0.0] - 2026-01-01
--------------------

### Added (1 change)

- Compute the tip for a single bill and print the total
```

Two things to note from the evidence: the headings use **setext underlines**
(`----`), not Keep-a-Changelog's `## x.y.z`; and section labels carry a change count
(`### Added (1 change)`). The breaking change in 3.0.0 surfaces as a dedicated
`### Important notes` section above `### Changed`, driven purely by the `important_notes:`
field in the entry — a nicer affordance than a bare `feat!` convention.

`logchange lint` passed at every stage with a clear message:

```
Validation of changelog and logchange-config.yml successful
No problems found, lint passed successfully
```

## Pros (observed)

- **Truly offline and platform-agnostic.** The entire life cycle ran in a container
  with only Docker — no API, no token, no network. This is the headline differentiator
  from most of the other "cross" tools (glab, release-drafter, release-please), which all
  need a hosting platform.
- **Legible state.** Unreleased changes are files; release is a directory rename. It is
  trivial to inspect what is pending and what shipped, directly on disk.
- **Real lint gate.** Fast, clear pass/fail — easy to wire into CI to require an entry
  per change.
- **Non-destructive `generate`.** Previewing the next release's notes is free and
  repeatable; no `--draft` flag or fragment-deletion dance (contrast towncrier, which
  `git rm`s consumed fragments).
- **Structured callouts.** `important_notes` and `configurations` give first-class
  sections for breaking/operational details that most fragment tools leave to free prose.

## Cons / pain points (observed)

- **`logchange -V` reports `version: null`.** The native binary cannot self-report its
  version; you must track the Docker image tag yourself. Mildly alarming the first time.
- **`generate` litters `unreleased/`.** It writes a `version-summary.md` into
  `changelog/unreleased/`, so an otherwise-empty unreleased dir holds a stray generated
  file, which then gets swept along on the next `release` rename.
- **Its own CHANGELOG dialect.** Setext underlines, a mandatory header/banner block,
  emoji in comments, and a trailing space after each entry title. It is
  Keep-a-Changelog-*ish*, not byte-for-byte KAC — relevant if a downstream parser expects
  strict KAC.
- **No version inference.** Version is a manual flag; logchange does not derive bumps
  from commits or tags. This is by design (it is a fragment tool, not semantic-release),
  but worth stating plainly.

## Docs vs. reality

- The original review positions logchange as a fragment tool "closer to Towncrier,
  Scriv, and Changie." **Accurate** — the YAML-per-change model and the
  unreleased→version move are exactly as described.
- The original review's sample output shows clean `## 1.19.15 - 2026-05-13` Keep-a-
  Changelog headings. **Reality differs:** the tool emits setext underlines and a
  generated header block. Same spirit, different on the page — the original undersold how
  opinionated the output format is.
- "Cross-language" and "reduces merge conflicts" both **hold up**: nothing in the run was
  Python-specific, and one-file-per-change is a genuine conflict-avoidance win.

## Revised verdict

**Verdict: Situational (unchanged) — but with hands-on confidence.**

logchange does exactly what it claims and, crucially, does it **fully offline**, which
sets it apart from the platform-bound tools it sits next to in the "cross" list. The
friction observed is cosmetic — a null self-version, a stray `version-summary.md`, and its
own CHANGELOG dialect — not functional. If your team wants fragment-based, conflict-free
changelogs without binding to GitHub or GitLab, logchange is a solid, legible choice;
compare it with Changie and Towncrier on output-format taste before committing.
