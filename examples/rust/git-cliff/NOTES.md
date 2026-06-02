# git-cliff Experiment Notes

## Environment
- Base image: debian:bookworm-slim (runtime) + rust:1.87-slim (build stage)
- Tool version: git-cliff 2.13.1 (pre-built musl binary, no cargo install)
- Run date: 2026-06-02

## Observations

### What worked
- Pre-built musl binary downloads cleanly from GitHub Releases and runs with zero shared lib dependencies
- All four life-cycle stages completed successfully
- `--unreleased` preview flag works exactly as documented — shows pending changes without writing the file
- `--latest` produces only the most recent release section — useful for GitHub Release body copy-paste
- `--init` scaffolds a heavily-commented cliff.toml covering all common patterns
- Tera template variables (`version`, `timestamp | date(...)`, `group_by(attribute="group")`) all work as documented
- `filter_unconventional = false` correctly retains `docs:` commits in the output

### What failed / friction
- Blank lines between release sections are absent in generated output — the body template ends without a trailing `\n`, so `## [2.0.0]` and `## [3.0.0]` sections are not separated by a blank line. A one-line fix to the template body resolves this.
- `docs: add changelog` commit appeared as a real "Documentation" entry in v2.0.0's section — this is expected given the cliff.toml, but requires discipline about which commits get `docs:` prefixes.
- `--init` mixes ANSI escape codes into stdout (`[32;1mINFO[0m`) — messy in transcripts; CI would want to strip or redirect stderr.
- First attempt at the tarball path used `git-cliff-2.13.1-x86_64-unknown-linux-musl/git-cliff` (wrong) before correcting to `git-cliff-2.13.1/git-cliff` (correct). Always list the tarball before extracting.

### Surprising findings
- The default `--init` config is opinionated: emoji group prefixes (`🚀 Features`), HTML-comment sort keys (`<!-- 0 -->`), and a catch-all `💼 Other` group. Very different from the minimal config in most docs examples.
- `filter_unconventional` defaults to `true` in `--init` output, meaning non-conventional commits are silently dropped unless you set it to `false`.

## Full transcript

```
tool under test:
git-cliff 2.13.1

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: git-cliff generates first CHANGELOG.md for v1.0.0 ====================

----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== STAGE 3: implement even split; preview unreleased notes ====================

--- git-cliff --unreleased (draft preview) ---
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Documentation

- Add changelog for 1.0.0

### Features

- Split the bill evenly among diners

----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== STAGE 4a: tag v2.0.0, regenerate full CHANGELOG.md ====================

----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-06-02

### Documentation

- Add changelog for 1.0.0

### Features

- Split the bill evenly among diners
## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== STAGE 4b: implement uneven split, tag v3.0.0, regenerate ====================

----- CHANGELOG.md -----
# Changelog

All notable changes to this project will be documented in this file.

## [3.0.0] - 2026-06-02

### Features

- Split the bill unevenly by weight
## [2.0.0] - 2026-06-02

### Documentation

- Add changelog for 1.0.0

### Features

- Split the bill evenly among diners
## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== BONUS: git-cliff --latest (release notes for v3.0.0 only) ====================

# Changelog

All notable changes to this project will be documented in this file.

## [3.0.0] - 2026-06-02

### Features

- Split the bill unevenly by weight


==================== BONUS: git-cliff --init in a temp dir to show default config ====================

[INFO] git_cliff > Saving the configuration file to cliff.toml
[default cliff.toml content — see out/transcript.txt for full config]

==================== DONE — artifacts in /work/out ====================
```
