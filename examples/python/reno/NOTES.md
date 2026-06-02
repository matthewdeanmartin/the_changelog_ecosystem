Tool: reno    Status: complete
- [x] Copied TEMPLATE, set TOOL in Makefile
- [x] Dockerfile installs reno==4.1.0 + git on python:3.12-slim
- [x] app/ is the tip calculator (pyproject.toml + 2 py files), runs & prints
- [x] scenario/ has YAML note files for v1/v2/v3
- [x] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [x] make run completes end-to-end with only Docker installed
- [x] out/ contains final report (as CHANGELOG.md) + git-log.txt + git-tags.txt + transcript.txt
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + pros/cons/pain points captured in NOTES.md
- [x] content/articles/reno.v2.md written, grounded in the run
- [x] pelican build still clean

## Observations

### Tool version
reno 4.1.0

### Key differences from other tools
- Output is RST, not CHANGELOG.md
- Notes are YAML files, not Markdown
- Tag-based attribution (notes committed before a tag → that tag's release)
- Notes are never deleted; they accumulate in releasenotes/notes/

### What worked
- `reno new <slug>` created uniquely-named YAML files (suffix = 8 random hex chars)
- Tag-based attribution worked automatically for all 3 versions
- Multi-section note (features + upgrade) rendered both sections without config
- `reno lint` passed with no errors and showed detailed per-commit scan output
- Provisional `1.0.0-1` heading for unreleased notes is a useful UX choice

### Bugs / pain points
1. **`reno --version` does not exist.** Raises usage error. Must use `python -c "import reno; print(reno.__version__)"`.
2. **Every command prints "no configuration file in: ..."** warning. Silenced by creating a `reno.yaml`.
3. **RST output only.** No Markdown mode. Hard barrier for non-Sphinx projects.
4. **YAML block scalars required.** `- |` for multi-line notes is a YAML gotcha; missing `|` produces mangled output or empty sections.
5. **Tag-ordering discipline.** Notes must be committed *before* tagging; tagging first misattributes the note.
6. **Note files accumulate forever.** After 20+ releases, `releasenotes/notes/` contains hundreds of files.
7. **`reno report` output goes to stdout only** by default.

### Note format used
```yaml
---
features:
  - |
    Split the bill unevenly by per-person weights.
    Output now lists each diner's individual share on its own line.
upgrade:
  - |
    The output format changed: each diner's share is now printed on a separate
    line instead of a single summary line. Scripts parsing stdout must be updated.
```

## Transcript excerpt (key outputs)

### Stage 2: reno report for 1.0.0
```
1.0.0
=====

New Features
------------

- Compute the tip and total for a single restaurant bill.
  All inputs are hard-coded constants; the program takes no arguments.
```

### Stage 3: unreleased note provisional heading
```
1.0.0-1
=======

New Features
------------

- Split the bill evenly among a fixed number of diners.
```

### Stage 4b: final report (v3.0.0 excerpt)
```
3.0.0
=====

New Features
------------

- Split the bill unevenly by per-person weights.
  ...

Upgrade Notes
-------------

- The output format changed: each diner's share is now printed on a separate line...
```

### reno lint output
```
scanning ./releasenotes/notes (branch=*current* earliest_version=None ...)
including entire branch history
000001 ... updating current version to 3.0.0
3c2151749025afd1: adding releasenotes/notes/uneven-split-3c2151749025afd1.yaml from 3.0.0
...
```
