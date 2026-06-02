Tool: keepachangelog    Status: complete
- [x] Copied TEMPLATE, set TOOL in Makefile
- [x] Dockerfile installs keepachangelog==2.0.0 + git on python:3.12-slim
- [x] app/ is the tip calculator (pyproject.toml + 2 py files), runs & prints
- [x] scenario/ has the seed CHANGELOG.md (KAC format, v1.0.0 section)
- [x] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [x] make run completes end-to-end with only Docker installed
- [x] out/ contains final CHANGELOG.md + git-log.txt + git-tags.txt + transcript.txt
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + pros/cons/pain points captured in NOTES.md
- [x] content/articles/keepachangelog.v2.md written, grounded in the run
- [x] pelican build still clean

## Observations

### Tool version
keepachangelog 2.0.0

### What worked
- `keepachangelog show <version>` extracts release body cleanly
- `keepachangelog release <version>` promotes [Unreleased], stamps date, rewrites comparison links
- Library API: `to_dict` parsed all 3 releases; `from_dict` round-tripped cleanly
- Zero config required

### Bugs / pain points
1. **`keepachangelog show Unreleased CHANGELOG.md` crashes** with `TypeError: 'NoneType' object is not subscriptable` when the [Unreleased] section has no sub-entries. This is a real bug in 2.0.0.
2. **CLI arg surface is opaque.** The `release` command does not accept a positional file path (tried `release 2.0.0 CHANGELOG.md`; got "unrecognized arguments"). The file is always read from the CWD.
3. **No `add` command.** All changelog editing is manual.
4. **`release` prints only the version number** on success — minimal feedback.
5. **No draft/preview mode** before releasing.

### Diff from original article
- Bug in `show Unreleased` was absent from docs
- Comparison link auto-maintenance is a real strength worth highlighting more
- Library API round-trip is solid

## Transcript excerpt (key stage outputs)

### Stage 2: show 1.0.0
```
--- keepachangelog show 1.0.0 ---
### Added
- Compute the tip and total for a single restaurant bill.
```

### Stage 3: show Unreleased bug
```
TypeError: 'NoneType' object is not subscriptable
(show Unreleased failed — see NOTES.md for bug details)
```

### Stage 4a: release 2.0.0
```
2.0.0
--- keepachangelog show 2.0.0 ---
### Added
- Split the bill evenly among a fixed number of diners.
```

### Stage bonus: library API
```
Versions found: ['3.0.0', '2.0.0', '1.0.0']
v3.0.0 sections: ['metadata', 'added']
Round-trip Markdown length: 760 chars
```
