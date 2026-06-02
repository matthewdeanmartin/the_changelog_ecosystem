Title: towncrier (hands-on synthesis)
Date: 2026-06-01
Slug: towncrier-v2
Ecosystem: Python
Tags: keep-a-changelog, news-fragments, python, python-cli, release-notes, ci-cd, hands-on
Tool_URL: https://pypi.org/project/towncrier/
Tool_Version: 24.8.0
Tool_Status: active
Experiment: examples/python/towncrier/
Summary: Hands-on re-review after driving towncrier through the tip-calculator life cycle in a container.



## What I actually ran

This is a second-pass review grounded in *running* towncrier, not reading its docs. The
reproducible experiment lives in [`examples/python/towncrier/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/python/towncrier).

- **Base image:** `python:3.12-slim`
- **Tool version:** `towncrier 24.8.0` (pinned in the Dockerfile)
- **Fixture:** a trivial all-constants "restaurant tip calculator" CLI, so all the
  interesting behavior is in the tool, not the app.
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code, **no changelog**.
  2. Configure towncrier, add a news fragment, **build the first changelog**.
  3. Implement an even-split feature (2.0.0), add a fragment, **preview** with `--draft`.
  4. **Bump + release** 2.0.0, then loop again for an uneven-split 3.0.0.

Seven commits and three tags (`v1.0.0`, `v2.0.0`, `v3.0.0`) were created entirely inside
the container — nothing touched the review site's own repo.

## Real output

The generated `CHANGELOG.md` after the full run (newest-first, exactly as towncrier
wrote it):

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

The `--draft` preview at stage 3 printed the pending 2.0.0 notes **without** consuming
the fragment:

```text
Draft only -- nothing has been written.
What is seen below is what would be written.

## 2.0.0 (...)

### Features

- Split the bill evenly among a fixed number of diners. (#2)
```

And `towncrier check --compare-with v2.0.0` correctly located the new fragment before the
3.0.0 release — the CI gate works as advertised.

## Pros (observed)

- **Output is genuinely user-facing.** Stable `## version` / `### category` headings,
  issue links, no raw commit noise. The docs' central claim held up exactly.
- **`--draft` is a real workflow feature**, not a footnote: you can render the *next*
  release's notes at PR time without mutating anything.
- **`towncrier check --compare-with <ref>` is a working CI gate** — it found the pending
  fragment against the previous tag.
- **Deterministic builds** via `--date` and explicit `--version`, which made the run
  reproducible.

## Cons / pain points (observed)

These only surfaced by actually running the life cycle:

- **Fragments must be git-committed *before* `towncrier build`.** towncrier deletes
  consumed fragments with `git rm`; if they are untracked, the build prints a scary
  `fatal: No pathspec was given. Which files should I remove?` partway through. It still
  finishes, but a strict CI step keying on stderr/exit noise could trip on it. The fix is
  simply to commit fragments first.
- **The `newsfragments/` directory vanishes after a build.** towncrier empties it and git
  does not track empty directories, so each subsequent stage had to recreate it. In a real
  project you would drop a `.gitkeep` in there.
- **`check` inspects the whole working tree.** Stray `__pycache__/*.pyc` files showed up
  in its file list until the app got a `.gitignore` — a reminder to keep the tree clean.
- **No free version inference in a minimal project.** We passed `--version` explicitly;
  metadata-based inference needs the package actually installed.

## Docs vs. reality

The original [towncrier review](/towncrier.html) is accurate where it counts: output is
human-facing, configuration lives in `pyproject.toml`, and `check` works as a release
gate. What no doc-derived review captured — and what the hands-on run exposed — is the
**git coupling**: fragments-must-be-tracked-before-build and the empty-directory
disappearance. Those are exactly the kind of first-run papercuts a maintainer hits and a
docs-summary misses.

## Revised verdict

**Verdict: Recommended (unchanged).** Running it end-to-end reinforced the original
rating rather than altering it. The two caveats are operational, not architectural, and
both have one-line fixes (commit fragments first; keep `newsfragments/.gitkeep`). For a
Python library that wants contributor-authored, user-facing release notes with a CI gate,
towncrier remains the baseline choice.
