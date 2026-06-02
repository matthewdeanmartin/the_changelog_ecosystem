Tool: REPLACE_ME    Status: not started

# Experiment notes

> Fill this in as you go. The synthesis article (`<slug>.v2.md`) must be grounded in
> what's recorded here. Paste the real transcript; don't paraphrase from docs.

## Checklist
- [ ] Copied TEMPLATE, set TOOL in Makefile
- [ ] Dockerfile installs the tool + git on a pinned base image
- [ ] app/ runs and prints (all three versions)
- [ ] scenario/ has the tool's seed config / fragments
- [ ] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [ ] `make run` completes end-to-end with only Docker installed
- [ ] out/ contains final CHANGELOG.md + release notes + transcript
- [ ] host `git status` shows only new examples/ source (no scenario .git)
- [ ] transcript + pros/cons/pain points captured below
- [ ] content/articles/<slug>.v2.md written, grounded in the run
- [ ] pelican build still clean

## Installed version
(record the exact version printed in the container)

## Per-stage output
### Stage 1 — no changelog
### Stage 2 — changelog created
### Stage 3 — changelog updated
### Stage 4 — bump + release (v2.0.0, v3.0.0)

## Pros (observed)
## Cons / pain points (observed)
## Docs vs. reality
## Revised verdict

## Raw transcript
```
(paste out/transcript.txt here)
```
