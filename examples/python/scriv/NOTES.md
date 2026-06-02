Tool: scriv    Status: complete
- [x] Copied TEMPLATE, set TOOL in Makefile
- [x] Dockerfile installs scriv==1.8.0 + git on python:3.12-slim
- [x] app/ is the tip calculator (pyproject.toml + 2 py files), runs & prints
- [x] scenario/ has scriv_config.toml and pre-written fragment files
- [x] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [x] make run completes end-to-end with only Docker installed
- [x] out/ contains final CHANGELOG.md + git-log.txt + git-tags.txt + transcript.txt
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + pros/cons/pain points captured in NOTES.md
- [x] content/articles/scriv.v2.md written, grounded in the run
- [x] pelican build still clean

## Observations

### Tool version
scriv 1.8.0

### What worked
- Config appended to pyproject.toml via `cat >> pyproject.toml` worked first time
- `version = "literal: pyproject.toml: project.version"` correctly read version
- `scriv collect` ran with no errors; warning on first run ("Changelog doesn't exist") is benign
- Fragment files were deleted after collect (no leftovers)
- Stable HTML anchors (`<a id='changelog-X.Y.Z'>`) generated automatically
- Run completed in <1s per collect step

### Bugs / pain points
1. **No draft/preview mode.** Unlike towncrier's `--draft`, `collect` always consumes and deletes fragments. Preview requires manual inspection.
2. **Heading level is `##` not `###`.** Fragment files with `## Added` headings produce `## Added` in the output, not `### Added` per KAC convention. Teams wanting KAC-style output must write `### Added` in fragments.
3. **No `[Unreleased]` section.** Output uses version-dated `#` headings. Not compatible with `keepachangelog` library parser.
4. **`mkdir -p changelog.d` needed between stages.** After `collect` empties the dir, git drops it. The TEMPLATE already warns about this.
5. **No non-interactive `scriv create`.** Fragments must be pre-written files; `scriv create` opens an editor. There is no `--content` or stdin mode for CI automation.

### Scriv fragment format used
```markdown
## Added

- Compute the tip and total for a single restaurant bill.
```

### Config used
```toml
[tool.scriv]
format = "md"
changelog = "CHANGELOG.md"
fragment_directory = "changelog.d"
version = "literal: pyproject.toml: project.version"
categories = "Added, Changed, Deprecated, Removed, Fixed, Security"
```

## Transcript excerpt (key outputs)

### Stage 2: collect stdout
```
Collecting from changelog.d
Reading changelog CHANGELOG.md
warning: Changelog CHANGELOG.md doesn't exist
Deleting fragment file 'changelog.d/20260101_initial.md'
```

### Stage 4a: CHANGELOG after v2.0.0 collect
```

<a id='changelog-2.0.0'></a>
# 2.0.0 — 2026-06-02

## Added

- Split the bill evenly among a fixed number of diners.

<a id='changelog-1.0.0'></a>
# 1.0.0 — 2026-06-02

## Added

- Compute the tip and total for a single restaurant bill.
```
