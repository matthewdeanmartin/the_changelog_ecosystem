# `examples/` — Hands-On Tool Experiments

This directory holds **runnable** experiments that drive each changelog/release tool
through a real life cycle inside Docker, so reviews can be grounded in observed behavior
rather than docs alone. Read `spec/experiments.md` first for the full rationale; this
file is the **operational guide for agents** (human or LLM) doing the work, including how
to parallelize.

## TL;DR of the recipe

1. Copy `TEMPLATE/` to `examples/<ecosystem>/<tool>/`.
2. Set `TOOL := <tool>` in the `Makefile`.
3. Fill in the `Dockerfile` (install the tool), `scenario/` (its config/fragments), and
   `run_experiment.sh` (the life-cycle steps for *this* tool).
4. `make run` — it builds the image and streams the full transcript; artifacts land in
   `out/`.
5. Paste the transcript + observations into `NOTES.md`.
6. Write `content/articles/<slug>.v2.md` (synthesis). **Never overwrite `<slug>.md`.**

## The scenario (do not change it)

A restaurant **tip calculator** CLI, all-constants, prints to stdout. Three releases:

- `1.0.0` — tip on one bill.
- `2.0.0` — split the bill **evenly** among N diners.
- `3.0.0` — split the bill **unevenly** by per-person weights.

Walk every tool through: **no changelog → changelog created → changelog updated →
version bump + release**, repeating the update→bump→release loop for each version.
Create 3–4 git commits/tags **inside the container** (`/work`), never against the host
repo. Full details and the synthesis-article contract are in `spec/experiments.md`.

---

## Parallelization rules

Each tool directory is fully self-contained and builds its own Docker image
(`cle-exp-<tool>`), so **multiple agents can work on different tools at the same time**
with zero shared state. To parallelize safely:

1. **One agent owns one tool directory.** Claim it by creating the directory and its
   `NOTES.md` with a `Status: in progress (<agent>)` line at the top.
2. **Never edit another tool's directory.** Shared edits (this README, the spec, the
   TEMPLATE) are serialized — make them in a separate, small commit and call it out.
3. **Image names are namespaced by tool** (`cle-exp-<tool>`) so parallel `docker build`
   runs never collide. `out/` is per-directory and gitignored.
4. **The host repo is read-only for scenario git.** All `git init/commit/tag` happens in
   the container. If you see scenario commits in `git status` of this repo, you mounted
   the wrong thing — fix the Makefile mount.
5. **Synthesis articles touch a shared dir** (`content/articles/`). Each writes a
   *new* `<slug>.v2.md` file, so there are no edit conflicts as long as nobody edits an
   existing article. Do not run `generate_pages.py` until all v2 files for a batch exist,
   then run it once.

### Suggested work units (Phase 1 — Python)

Each row is an independent, parallelizable task. Assign one agent per row.

| # | Tool | Dir | Article (do not overwrite) | Workflow flavor |
|---|------|-----|----------------------------|-----------------|
| 1 | keepachangelog | `python/keepachangelog/` | `keepachangelog.md` | Manual KAC edits + parser lib |
| 2 | keepachangelog-manager | `python/keepachangelog-manager/` | `keepachangelog-manager.md` | Edit/validate CLI (host's fork) |
| 3 | towncrier | `python/towncrier/` | `towncrier.md` | News-fragment assembly — **DONE (reference)** |
| 4 | scriv | `python/scriv/` | `scriv.md` | Fragment tool, collect on release |
| 5 | reno | `python/reno/` | `reno.md` | YAML release-notes fragments |

`python/towncrier/` is the **complete reference implementation** — it builds and runs
end-to-end (`make run`) and has a finished `towncrier.v2.md`. Copy its shape when in doubt;
its `run_experiment.sh` shows exactly how to wire a fragment-based tool through all four
stages.

---

## Per-task checklist (paste into your NOTES.md and tick as you go)

```
Tool: <name>    Status: in progress (<agent>)
- [ ] Copied TEMPLATE, set TOOL in Makefile
- [ ] Dockerfile installs <tool> + git on a pinned base image
- [ ] app/ is the tip calculator (pyproject.toml + 1-2 py files), runs & prints
- [ ] scenario/ has the tool's seed config / fragments
- [ ] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [ ] make run completes end-to-end with only Docker installed
- [ ] out/ contains final CHANGELOG.md + release notes + transcript
- [ ] host `git status` shows only new examples/ source (no scenario .git)
- [ ] transcript + pros/cons/pain points captured in NOTES.md
- [ ] content/articles/<slug>.v2.md written, grounded in the run
- [ ] pelican build still clean
```

## Gotchas (learned from the towncrier reference run)

- **Always use `make run`.** On Windows/Git Bash, a hand-typed `docker run -v …` silently
  fails to return artifacts (MSYS path mangling). `make run` resolves `$(CURDIR)` natively
  and works on every OS. If you truly must run docker by hand on Windows:
  `MSYS_NO_PATHCONV=1 docker run --rm -v "C:/…/out:/work/out" cle-exp-<tool> ./run_experiment.sh`.
- **`scenario/` is at `/work/scenario`** (absolute) — the script `cd`s into `/work/app`, so
  use the `$SCENARIO` variable, never a relative `scenario/…` path.
- **Commit fragments/changes before the tool's build** if the tool removes them via
  `git rm` (towncrier does), else it errors mid-run on untracked files.
- **Re-`mkdir -p` a fragment dir** the tool emptied (git drops empty dirs).
- The TEMPLATE already bakes all of the above in; if you start from it you inherit the fixes.

## House rules

- Pin base images and tool versions; record the exact installed version in the v2 article.
- `uv` only for Python on the host side; **inside containers** you may use whatever the
  image ships (the experiments are isolated, so container-internal `pip`/`python` is OK).
- Be honest in synthesis: observed cons are the most valuable output. Don't launder
  pain points into neutral prose.
- If a tool can't complete a stage, document the failure as a finding rather than faking
  success.

## Phases beyond Python (deferred)

Same recipe, new `examples/<ecosystem>/` subtrees, swap the app to that ecosystem's
minimal project (Cargo for Rust, `go.mod` for Go, `package.json` for Node, etc.) and the
install step for the tool. Cross-language tools (`git-cliff`, `python-semantic-release`,
`release-please`) belong to a later cross-language phase, not Phase 1.
