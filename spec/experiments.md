# Spec — Hands-On Tool Experiments (`examples/`)

## Start here (for an agent picking this up)

Read these three things, in order, then start:

1. **This file** — the why, the scenario, and all the contracts.
2. **`examples/README.md`** — the operational guide: per-tool task table,
   parallelization rules, the per-task checklist, and the gotcha quick-reference.
3. **`examples/python/towncrier/`** — the **complete, runnable reference**. Build and run
   it (`cd examples/python/towncrier && make run`) to see the whole life cycle work, then
   copy its shape for your tool. Its `run_experiment.sh` and finished
   `content/articles/towncrier.v2.md` are the gold standard.

To start a new tool: copy `examples/TEMPLATE/` to `examples/<ecosystem>/<tool>/`, set
`TOOL` in the Makefile, fill the Dockerfile install line + `scenario/` + the `TODO`s in
`run_experiment.sh`, run `make run`, then write `content/articles/<slug>.v2.md`.

## Why this exists

This is a review site. Most articles were produced by asking an LLM to transform a
tool's help docs and README into a review. That is fine for a first pass, but it is
second-hand knowledge — the reviewer never actually ran the tool through a real
changelog life cycle.

LLMs are good at writing code. So instead of reading docs *about* a tool, we make the
LLM **drive the tool through a reproducible scenario in a container**, observe the real
output and pain points, and then write a *synthesis* review that reconciles what the
docs claim with what actually happened.

The deliverable of each experiment is:

1. A runnable example under `examples/<ecosystem>/<tool>/` (Docker + a minimal project).
2. A captured transcript of running the tool through the changelog life cycle.
3. A **v2 synthesis article** at `content/articles/<slug>.v2.md` (never overwrites the
   original `<slug>.md`).

Phase 1 is **Python only**. The structure is designed so later phases (Rust, Go, Node,
Java, Ruby, .NET, C/C++) and parallel agents can follow the same recipe.

---

## The Scenario (identical across every tool and ecosystem)

A **restaurant tip calculator** CLI. All inputs are hard-coded constants — the program
takes no arguments, runs, and prints to stdout. It is deliberately trivial so that *all*
the interesting variation lives in the changelog/release tooling, not the app.

Three versions, each a real release in the project's git history:

| Version | Behavior | Change type |
|---------|----------|-------------|
| `1.0.0` | Computes a tip (constant bill, constant tip %) and prints total. | Initial release |
| `2.0.0` | Splits the bill **evenly** among a constant number of diners. | Feature |
| `3.0.0` | Splits the bill **unevenly** (constant per-person weights). | Feature (breaking output shape) |

Optionally a `2.0.1`/patch may be introduced to exercise a bugfix entry if the tool's
workflow benefits from it (e.g. to show a `### Fixed` section). Keep it optional — the
three feature releases above are the required spine.

### Required life-cycle stages

Every experiment must walk the tool through this arc and capture output at each stage:

1. **No changelog** — fresh repo, `1.0.0` code committed, no changelog yet.
2. **Changelog created** — initialize/generate the first changelog for `1.0.0`.
3. **Changelog updated** — add the `2.0.0` change(s), regenerate/assemble.
4. **Version bump + release** — bump to `2.0.0`, tag, produce release notes; then
   repeat the update→bump→release loop for `3.0.0`.

The point is to see how the tool behaves across the *whole* life cycle, not just one
invocation.

### Git inside the container

Create **3–4 real git commits** (and tags) **inside the container**, in a repo that
lives entirely in the container's filesystem (e.g. `/work`). This lets each experiment
use whatever commit-message convention and version scheme the tool wants
(Conventional Commits, plain messages, `vX.Y.Z` tags, etc.) **without polluting the
`the_changelog_ecosystem` repo**.

> **Hard rule:** never run `git init`/`git commit`/`git tag` for the scenario against the
> host repo. All scenario git activity happens inside the container's `/work`. The
> `examples/` files themselves are committed to *this* repo as source, but they contain
> no `.git` of their own.

Suggested commit shape (adapt per tool's expected convention):

```
feat: compute tip for a single bill            # -> tag v1.0.0
feat: split the bill evenly among diners        # -> tag v2.0.0
feat!: split the bill unevenly by weight         # -> tag v3.0.0
```

For tools that read Conventional Commits (git-cliff, python-semantic-release), use the
`feat:` / `fix:` / `feat!:` prefixes. For fragment tools (towncrier, scriv, reno), the
commit messages can be plain and the *fragments* carry the change descriptions. For
manual tools (keepachangelog, keepachangelog-manager), edit the changelog directly and
commit it.

---

## Directory Layout

```
examples/
  README.md                      # the parallelization guide (see below)
  TEMPLATE/                      # copy-me skeleton for a new tool
    Dockerfile
    Makefile
    app/                         # the tip-calculator project (ecosystem-specific)
    scenario/                    # any tool config / fragments / changelog seeds
    run_experiment.sh           # the in-container life-cycle driver
    NOTES.md                     # where the LLM records observations
  python/
    towncrier/
    scriv/
    reno/
    keepachangelog/
    keepachangelog-manager/
```

Each tool directory is **self-contained**: `Dockerfile`, `Makefile`, the app, and the
experiment driver. No shared build state between tools (so they can run in parallel).

### Files in a tool directory (target: 2–4 source files for the app)

| File | Purpose | Edited by |
|------|---------|-----------|
| `Dockerfile` | Pins a base image, installs the tool + git, sets `WORKDIR /work`. | author |
| `Makefile` | Host-side `build`/`run`/`shell`/`clean` + in-container `experiment`. | author |
| `run_experiment.sh` | Runs the full life cycle in the container, echoing each step. | author |
| `app/` | The tip-calculator (e.g. `pyproject.toml` + `tipcalc/__init__.py` + `tipcalc/__main__.py`). | author |
| `scenario/` | Tool config seeds (e.g. `[tool.towncrier]` block, fragment files). | author |
| `NOTES.md` | Raw observations + final transcript paste. | LLM driver |

Keep the app minimal: **pyproject.toml + 1–2 Python files**. For Python use
`pyproject.toml` (PEP 621) and run with `uv`/`python -m tipcalc` inside the container.

---

## The Makefile contract

Every tool's `Makefile` exposes the **same target names** so a driver (human or LLM)
never has to learn a new interface:

```make
# ---- host side (run on your machine; needs only Docker) ----
build:        ## Build the image for this tool
	docker build -t cle-exp-$(TOOL) .

run: build    ## Run the full experiment and stream the transcript
	docker run --rm -v "$(CURDIR)/out:/work/out" cle-exp-$(TOOL) ./run_experiment.sh

shell: build  ## Drop into an interactive shell in the container for debugging
	docker run --rm -it -v "$(CURDIR)/out:/work/out" cle-exp-$(TOOL) bash

clean:        ## Remove the image and local out/
	-docker rmi cle-exp-$(TOOL)
	-rm -rf out

# ---- in-container side (invoked by run_experiment.sh, not by the host) ----
experiment:   ## (inside container) run the life cycle and write artifacts to out/
	./run_experiment.sh
```

`TOOL` is set per directory (e.g. `TOOL := towncrier`).

### Why a mount?

The user asked to mount the local filesystem so the `CHANGELOG.md` and config can be
read back out. We do this by mounting only an **`out/` directory** (`-v $(CURDIR)/out:/work/out`)
and having `run_experiment.sh` copy the final `CHANGELOG.md`, generated release notes,
and the captured transcript into `/work/out`. The *scenario repo itself* is created
fresh inside the container each run (ephemeral `/work`), so reruns are clean and the
host repo is never touched. The seed config/fragments are baked into the image from
`scenario/` at build time.

> Mounting only `out/` (not the whole project) keeps the container's git repo isolated
> from the host. If a tool genuinely needs to read host config live, mount it read-only.

### Cross-platform mount gotcha (Windows / Git Bash) — verified

`make run` is the reliable entry point on every OS. GNU Make resolves `$(CURDIR)` to a
native path, so the bind mount works and artifacts come back to `out/`.

**Do not run the `docker run -v …` line by hand from Git Bash on Windows** — MSYS rewrites
both the source path and the container path, the mount silently maps somewhere else, and
`out/` ends up empty even though the run "succeeds". If you must invoke docker directly on
Windows, use a Windows-style source path and disable path conversion:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "C:/…/out:/work/out" cle-exp-<tool> ./run_experiment.sh
```

This was hit and fixed during the towncrier reference run; prefer `make run` and you never
see it.

---

## `run_experiment.sh` contract

A POSIX shell script, baked into the image, that:

1. Sets up an isolated git repo in `/work` (`git init`, sets a local
   `user.name`/`user.email`, **never** touches `~/.gitconfig` of the host).
2. Walks the four life-cycle stages, committing/tagging as it goes.
3. After **each** stage, prints a clear banner (`echo "=== STAGE 2: changelog created ==="`)
   and dumps the current `CHANGELOG.md` (or equivalent) to stdout.
4. Exercises the tool's headline features (init, generate/assemble, check, bump, build
   release notes).
5. Copies final artifacts (`CHANGELOG.md`, any `dist/` notes, the full transcript) into
   `/work/out/`.
6. Exits non-zero if a required tool command fails, so a broken experiment is obvious.

The script is the **single source of truth** for what "running the experiment" means and
must be re-runnable with `make run` from a clean checkout that has only Docker.

### Lessons baked in from the towncrier reference run

`examples/python/towncrier/` is a fully working reference. These gotchas were found by
running it and are now encoded in the TEMPLATE — keep them in mind for every tool:

1. **`scenario/` is absolute.** It is baked at `/work/scenario`, a sibling of the app.
   After `cd /work/app` it is *not* relative; the script defines `SCENARIO=/work/scenario`
   and references `$SCENARIO/…`.
2. **Commit before the tool's `build`.** Tools that delete consumed fragments via `git rm`
   (towncrier does) will error mid-run (`fatal: No pathspec was given`) if the fragments
   are untracked. Commit new fragments/changes *before* invoking the assemble step.
3. **Re-`mkdir` emptied dirs.** A tool that empties its fragment directory leaves it gone
   (git doesn't track empty dirs); `mkdir -p <dir>` again before the next stage, or ship a
   `.gitkeep`.
4. **Keep the tree clean.** `app/.gitignore` excludes `__pycache__`/`*.pyc` so the tool's
   `check`/diff inspection isn't polluted by Python bytecode. The TEMPLATE app ships this.

---

## The Synthesis Article (`<slug>.v2.md`)

After running the experiment, the LLM writes `content/articles/<slug>.v2.md`. It does
**not** overwrite `<slug>.md`.

### Frontmatter

Reuse the existing article's frontmatter (same `Slug` base is fine — Pelican will treat
`.v2.md` as a separate article; if Pelican complains about a duplicate slug, append
`-v2` to the `Slug:` and `Title:`). Add:

```
Title: <tool> (hands-on synthesis)
Slug: <slug>-v2
Date: <run date>
Ecosystem: <…>
Tool_Version: <version actually installed in the container>
Experiment: examples/<ecosystem>/<tool>/
Summary: Hands-on re-review after driving <tool> through the tip-calculator life cycle.
```

### Required sections

1. **What I actually ran** — link the example dir, name the container base image and the
   exact tool version, summarize the four stages.
2. **Real output** — paste the actual generated `CHANGELOG.md`/release notes (trimmed),
   per stage. This is the evidence.
3. **Pros (observed)** — only things seen first-hand in the run.
4. **Cons / pain points (observed)** — friction, footguns, confusing config, anything
   that needed a workaround. Be specific and honest.
5. **Docs vs. reality** — where the original `<slug>.md` (or the tool's docs) matched the
   experience, and where it oversold/undersold/missed something.
6. **Revised verdict** — keep, upgrade, or downgrade the original verdict, with the
   reason grounded in the run.

> The synthesis must be grounded in the captured transcript. No claim in the v2 article
> should be unsupported by something in `NOTES.md` / the `out/` artifacts.

---

## Definition of done (per tool)

- [ ] `examples/python/<tool>/` exists with Dockerfile, Makefile, app, scenario, script.
- [ ] `make run` from that dir builds and runs end-to-end with **only Docker installed**.
- [ ] All four life-cycle stages produce visible output; artifacts land in `out/`.
- [ ] Scenario git history lives only in the container; host repo `git status` unchanged
      except for the new `examples/` source files.
- [ ] `NOTES.md` captures the transcript + observations.
- [ ] `content/articles/<slug>.v2.md` written, grounded in the run, original untouched.
- [ ] `uv run pelican content -o output -s pelicanconf.py` still builds cleanly.

---

## Phase 1 scope (Python)

Five tools, in suggested order (simplest workflow first):

1. **keepachangelog** — manual Keep-a-Changelog edits + the `keepachangelog` parser lib.
2. **keepachangelog-manager** — the host's own fork; edit/validate workflow.
3. **towncrier** — news-fragment assembly (the canonical Python fragment tool).
4. **scriv** — fragment tool with a slightly different model than towncrier.
5. **reno** — OpenStack's YAML-fragment release-notes tool.

Cross-language tools that also serve Python (`git-cliff`, `python-semantic-release`)
are **deferred to a later phase** to keep Phase 1 strictly Python-ecosystem and avoid
overlap with the Rust/Node passes.

See `examples/README.md` for the per-tool task breakdown and parallelization rules.
