Tool: logchange    Status: done

# Experiment notes

Hands-on run of logchange through the tip-calculator life cycle, fully offline in Docker.

## Checklist
- [x] Copied TEMPLATE, set TOOL in Makefile
- [x] Dockerfile installs the tool + git on a pinned base image (FROM logchange/logchange:1.19.15 + apk git/python3)
- [x] app/ runs and prints (all three versions)
- [x] scenario/ has the tool's seed entries (YAML fragments per version)
- [x] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [x] `make run` completes end-to-end with only Docker installed
- [x] out/ contains final CHANGELOG.md + the full changelog/ tree + transcript
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + pros/cons/pain points captured below
- [x] content/articles/logchange.v2.md written, grounded in the run
- [x] pelican build still clean

## Installed version
`logchange -V` reports:

```
Logchange version: null
Build with Java: 21.0.11 - Oracle Corporation
VirtualMachine: 21.0.11+9-LTS - Oracle Corporation - Substrate VM
```

FINDING: the native binary does not know its own version (`version: null`). The
actual artifact is the `logchange/logchange:1.19.15` Docker image (GraalVM native
image on Alpine, Java 21 / Substrate VM). Pin the *image tag* for reproducibility,
not `logchange -V`.

## Tool model (observed via `--help`)
- `logchange init` — writes `changelog/logchange-config.yml` and `changelog/unreleased/.gitkeep`.
- change entries — one YAML file per change in `changelog/unreleased/*.yml` (fields:
  `title`, `type`, plus optional `authors`, `issues`, `merge_requests`, `links`,
  `important_notes`, `configurations`).
- `logchange lint` — validates entries + config. Clean CI gate; clear pass message.
- `logchange generate` — (re)writes `CHANGELOG.md` from entries. NON-destructive:
  pending entries render under `[unreleased]`; does not move files.
- `logchange release --versionToRelease X --releaseDate Y` — MOVES
  `changelog/unreleased/*.yml` into `changelog/vX/`, writes `release-date.txt`, and
  recreates `unreleased/` with a fresh `.gitkeep`.

## Per-stage output
### Stage 1 — no changelog
v1.0.0 committed and tagged; `python3 -m tipcalc` prints the single-bill total; no CHANGELOG.md.

### Stage 2 — changelog created
`logchange init` + drop the v1 YAML entry + `lint` + `generate` shows it under
`[unreleased]`; then `release --versionToRelease 1.0.0 --releaseDate 2026-01-01`
moves it to `changelog/v1.0.0/` and `generate` produces the first released section.

### Stage 3 — changelog updated
Even-split implementation + v2 YAML entry; `generate` previews the pending change
under `[unreleased]` without releasing it. No build/`git rm` dance needed.

### Stage 4 — bump + release (v2.0.0, v3.0.0)
`release --versionToRelease 2.0.0/3.0.0` per loop. v3 uses `type: changed` plus an
`important_notes:` line to flag the breaking output-shape change; it renders as a
dedicated `### Important notes` section above `### Changed`.

Final CHANGELOG.md (trimmed of the auto-generated header comments):

```
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

## Pros (observed)
- Genuinely offline and local: no GitHub/GitLab token, no network. The whole life
  cycle runs in a container with only Docker.
- The version/release model is dead simple and visible on disk: unreleased entries
  are files; `release` literally renames the directory to `vX.Y.Z`. Easy to reason about.
- `lint` is a real, fast validation gate with a clear pass/fail message — good for CI.
- `generate` is idempotent and non-destructive, so previewing pending notes is free.
- `important_notes` gives a clean, dedicated section for breaking/operational callouts —
  more structured than a bare `feat!` convention.
- Version comes from a CLI flag (`--versionToRelease`), so it is decoupled from any
  ecosystem's project file. Works the same for Python, Node, Java, etc.

## Cons / pain points (observed)
- `logchange -V` prints `version: null` — the binary can't self-report its version.
  You must track the Docker image tag yourself.
- `generate` writes a `version-summary.md` *into* `changelog/unreleased/`, so an
  otherwise-empty unreleased dir ends up holding a stray generated file (visible in
  `out/changelog/unreleased/version-summary.md`). Slightly surprising; it gets carried
  along on the next `release` rename unless cleaned.
- The CHANGELOG.md format is logchange's own (setext `----` underlines, a loud
  "DO NOT MODIFY THIS FILE" banner, emoji in comments). It is Keep-a-Changelog-ish but
  not byte-for-byte KAC, and entries get a trailing space after the title.
- Version is a manual flag; logchange does no version inference from commits or tags
  (by design — it is a fragment tool, not a semantic-release tool).

## Docs vs. reality
- The original review calls it a fragment tool "closer to Towncrier/Scriv/Changie" —
  accurate. The YAML-per-change model and `release` dir-rename are exactly as described.
- The review's sample output shows clean Keep-a-Changelog `## x.y.z` headings; the real
  output uses setext underlines and a generated header block. Close in spirit, different
  on the page. Worth flagging for anyone expecting strict KAC.
- "Cross-language" holds up: nothing in the run was Python-specific; the app being
  Python was incidental.

## Revised verdict
Keep the original "Situational" verdict, with more confidence. logchange does exactly
what it claims, runs fully offline, and has a clean lint gate. The friction is cosmetic
(null self-version, stray version-summary.md, its own CHANGELOG dialect) rather than
functional. Good pick for teams that want fragment-based, conflict-free changelogs
without tying themselves to a host platform.

## Raw transcript
See `out/transcript.txt` (regenerate with `make run`).
