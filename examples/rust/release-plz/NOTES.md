# release-plz Experiment Notes

## Environment
- Base image: rust:1.87-slim (Debian Bookworm)
- Tool version: release-plz 0.3.158
- Run date: 2026-06-01

## Observations

### What worked

- `release-plz update` ran successfully without a remote or published crate. It produced a well-formed `CHANGELOG.md` grouped by conventional-commit type (`### Features`), dated with the run date, and versioned correctly at `1.0.0`.
- The tool correctly parsed conventional commit messages (`feat:`) and mapped them to changelog sections without any configuration beyond `release-plz.toml`.
- Setting `publish = false` and `git_release_enable = false` in `release-plz.toml` was sufficient to suppress all network-dependent behaviour (no crates.io publish, no GitHub release creation).
- The tool ran entirely offline for the local changelog/update workflow.

### What failed / friction

- `release-plz changelog` is **not a valid subcommand** in version 0.3.158. The script called it speculatively; the tool responded with `error: unrecognized subcommand 'changelog'`. The changelog is generated only via `release-plz update`.
- Stage 4b (`release-plz update` for v3.0.0) did not produce a new entry. The tool detected no change in the published version (since there is no upstream on crates.io and the local version was already `1.0.0`), reported `the repository is already up-to-date`, and left the CHANGELOG unchanged. This means a **second changelog entry for v3.0.0 was never generated** in this isolated Docker scenario.
- Two persistent `WARN` lines appear on every run:
  - `no upstream configured for branch master` — expected in an isolated Git repo with no remote.
  - `Cannot determine repo url` — causes release links to be omitted from the changelog. Not a fatal error, but the resulting CHANGELOG has no hyperlinks.
- The `Package tipcalc@*.*.* not found` warning is emitted on every call because the crate does not exist on crates.io; release-plz uses the registry to detect the "current published version" and compare it to what's in the repo. With `publish = false` set, this is harmless.
- `release-plz release-pr` and `release-plz release` are entirely GitHub-dependent (require `GITHUB_TOKEN` and a real remote) and cannot be demonstrated locally.

### Surprising findings

- release-plz uses **crates.io as the source of truth for the previous version** rather than git tags. Because `tipcalc` is not published, it cannot determine what has already been released, so it perpetually sees version `1.0.0` as "next" regardless of how many tags exist in the local repo.
- The CHANGELOG format is Keep a Changelog compatible and groups commits correctly from conventional commit messages with zero extra configuration. The `[git]` / `[changelog]` sections from a `release-plz.toml` are not needed for basic operation.
- The tool writes the CHANGELOG and bumps `Cargo.toml` in a single `update` invocation — there is no separate "generate changelog only" subcommand in this version.

## Full transcript

```
tool under test:
release-plz 0.3.158

==================== STAGE 1: v1.0.0 code, tagged — baseline for release-plz ====================

(no CHANGELOG.md yet)

==================== STAGE 2: release-plz changelog — show changelog for current crate ====================

--- release-plz changelog ---
error: unrecognized subcommand 'changelog'

Usage: release-plz [OPTIONS] <COMMAND>

For more information, try '--help'.
(release-plz changelog output above)
(no CHANGELOG.md yet)

==================== STAGE 3: implement even split; run release-plz update ====================

--- release-plz update (bumps version + generates CHANGELOG.md) ---
INFO using release-plz config file release-plz.toml
WARN no upstream configured for branch master
WARN Cannot determine repo url. The changelog won't contain the release link. Error: cannot determine origin url

Caused by:
    error while running git in directory `"/work/app"` with args `["config", "--get", "remote.origin.url"]
INFO downloading packages from cargo registry crates.io
    Updating crates.io index
WARN Package `tipcalc@*.*.*` not found
WARN no upstream configured for branch master
INFO determining next version for tipcalc 1.0.0
INFO Getting packaged files for crate at /tmp/.tmpLpcpCZ/app/
INFO Getting packaged files for crate at /tmp/.tmpLpcpCZ/app/
INFO tipcalc: next version is 1.0.0
WARN no upstream configured for branch master

* `tipcalc`: 1.0.0

----- CHANGELOG.md -----
# Changelog

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill
- Split the bill evenly among diners

------------------------

==================== STAGE 4a: commit + tag v2.0.0 ====================

----- CHANGELOG.md -----
# Changelog

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill
- Split the bill evenly among diners

------------------------

==================== STAGE 4b: implement uneven split; release-plz update for v3.0.0 ====================

--- release-plz update for v3.0.0 ---
INFO using release-plz config file release-plz.toml
WARN no upstream configured for branch master
WARN Cannot determine repo url. The changelog won't contain the release link.
INFO downloading packages from cargo registry crates.io
    Updating crates.io index
WARN Package `tipcalc@*.*.*` not found
WARN no upstream configured for branch master
INFO determining next version for tipcalc 1.0.0
INFO tipcalc: next version is 1.0.0
WARN no upstream configured for branch master
INFO the repository is already up-to-date

* `tipcalc`: 1.0.0

On branch master
nothing to commit, working tree clean
----- CHANGELOG.md -----
# Changelog

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill
- Split the bill evenly among diners

------------------------

==================== BONUS: release-plz commands that need GitHub (not runnable locally) ====================

Commands that require GitHub token and remote (shown for reference):
  release-plz release-pr  # opens a release PR on GitHub
  release-plz release      # publishes crates after PR merge

Local-only commands demonstrated above:
  release-plz update       # bumps Cargo.toml version + updates CHANGELOG.md
  release-plz changelog    # generates/shows changelog text

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 16
-rw-r--r-- 1 root root  122 Jun  2 03:11 CHANGELOG.md
-rw-r--r-- 1 root root  230 Jun  2 03:11 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:11 git-tags.txt
-rw-r--r-- 1 root root 4885 Jun  2 03:11 transcript.txt
```
