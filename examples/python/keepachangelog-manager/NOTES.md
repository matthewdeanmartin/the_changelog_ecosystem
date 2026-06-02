Tool: keepachangelog-manager-fork    Status: complete
- [x] Copied TEMPLATE, set TOOL in Makefile
- [x] Dockerfile installs keepachangelog-manager-fork==5.2.0 + git on python:3.12-slim
- [x] app/ is the tip calculator (pyproject.toml + 2 py files), runs & prints
- [x] scenario/ has version swap files
- [x] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [x] make run completes end-to-end with only Docker installed
- [x] out/ contains final CHANGELOG.md + git-log.txt + git-tags.txt + transcript.txt
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + pros/cons/pain points captured in NOTES.md
- [x] content/articles/keepachangelog-manager.v2.md written, grounded in the run
- [x] pelican build still clean

## Observations

### Tool version
keepachangelog-manager-fork 5.2.0 (CLI: `changelogmanager`)

### Version discovery
`changelogmanager --version` fails (SystemExit 2). Version must be obtained via `pip show keepachangelog-manager-fork`.

### What worked
- `create` scaffolds a valid KAC 1.1.0 file
- `add --change-type added --message "..."` adds entries without manual editing
- `release --override-version X.Y.Z --yes` promotes [Unreleased] non-interactively
- `validate` runs silently on a valid file (exit 0, no output)
- Release confirmation message: "Released X.Y.Z" — clean one-liner

### Bugs / pain points
1. **`--section` flag does not exist.** Docs mention sections; the actual flag is `--change-type` (lowercase type names: `added`, `changed`, etc.).
2. **`[Unreleased]` section is dropped after `release`.** The released file contains no empty `## [Unreleased]` block. Tools that assert the section exists will fail.
3. **No comparison links.** `release` does not generate `[x.y.z]: https://...compare/...` link definitions. The plain `keepachangelog` library generates these.
4. **`--override-version` required for explicit versioning.** Without it, version auto-detection did not apply in this scenario.
5. **Dependency footprint.** Requires inquirer, blessed, jinxed, readchar — a heavier install than the plain `keepachangelog` library.

### Diff from original article
- `--section` flag doesn't exist; it's `--change-type`
- Missing [Unreleased] after release not noted in original
- No comparison links not noted in original
- `--yes` flag for non-interactive use not mentioned

## Transcript excerpt (key stage outputs)

### Stage 2: after create
```
## [Unreleased]
### Added
- Compute the tip and total for a single restaurant bill.
```

### Stage 2: after release 1.0.0
```
Released 1.0.0
```

### Stage 4a: final CHANGELOG fragment
```
## [2.0.0] - 2026-06-02
### Added
- Split the bill evenly among a fixed number of diners.

## [1.0.0] - 2026-06-02
### Added
- Compute the tip and total for a single restaurant bill.
```

Note: no [Unreleased] section, no comparison links.
