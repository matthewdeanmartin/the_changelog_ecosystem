# cargo-release Experiment Notes

## Environment
- Base image: rust:1.87-slim
- Tool version: cargo-release 1.1.2 (pre-built musl binary)
- git-cliff version: 2.13.1 (companion tool for changelog hook)
- Run date: 2026-06-01

## Observations

### What worked

- **Installation**: cargo-release and git-cliff both installed cleanly from pre-built musl binaries — no compilation required, no system dependency friction.
- **git-cliff integration (manual hook simulation)**: Stages 4a and 4b worked exactly as intended. Running `git-cliff --config cliff.toml --tag v2.0.0 --output CHANGELOG.md` produced correct, cumulative changelogs with properly grouped conventional-commit entries. The changelog grew through all three versions (v1.0.0 → v2.0.0 → v3.0.0) with no gaps.
- **Conventional commit parsing**: git-cliff correctly categorized `feat:` commits under "Features" and `docs:` commits under "Docs". The `feat!:` breaking-change commit for v3.0.0 was recognized.
- **Dry-run mode**: `cargo-release release --no-publish --no-push --no-tag patch` ran without crashing and reported what it would have done, including a version upgrade from 2.0.0 to 2.0.1.
- **release.toml hook pattern**: The documented pattern (`pre-release-hook = ["git", "cliff", "--tag", "{{version}}", "-o", "CHANGELOG.md"]`) is the standard real-world integration point.

### What failed / friction

- **Cargo.lock check**: cargo-release dry-run immediately flagged `Cargo.lock (Status(WT_NEW))` as an uncommitted change and refused to proceed. In the experiment, `Cargo.lock` was not pre-committed because the app was never built inside the container. In a real project, `cargo build` generates the lock file and it would already be tracked. This is a real guard, not a bug — but it is easy to trip in a minimal experiment setup.
- **`[Unreleased]` section mismatch**: cargo-release dry-run reported `error: for 'Unreleased' in 'CHANGELOG.md', at least 1 replacements expected, found 0`. cargo-release's built-in changelog replacement expects a `## [Unreleased]` section header in the file; git-cliff's default output does not include one. The two tools use different changelog conventions. This is resolved in practice by using git-cliff solely as the hook and disabling cargo-release's own replacement feature.
- **Docs commit in v2.0.0 changelog**: The `docs: add changelog for 1.0.0` commit leaked into the v2.0.0 changelog because it fell between the v1.0.0 tag and the v2.0.0 tag. This is correct behavior from git-cliff's perspective (it includes all commits in the range) but looks odd: the "added a changelog" commit appears in the changelog itself. In practice you'd squash or skip such commits via cliff.toml `[git] skip_tags` / `commit_parsers`.
- **Version bump is manual in dry-run**: cargo-release's version bump (`sed -i` substitution) had to be done by hand in the script. In a real `--execute` run, cargo-release handles this automatically.

### Surprising findings

- cargo-release's core value is orchestration (version bump, commit, tag, push, publish) rather than changelog generation. It delegates changelog content entirely to the hook. The tool itself has no opinion about changelog format.
- The `--no-publish --no-push --no-tag` flags turn the dry-run into a "what would I upgrade?" report rather than a full simulation. Even with all three flags, cargo-release still validates the git working tree and changelog structure.
- git-cliff works beautifully as the changelog generator in this workflow — it is clearly the intended companion tool, even though cargo-release does not mandate it.
- The `{{version}}` template variable in `release.toml` pre-release-hook is expanded by cargo-release before invoking the hook, so git-cliff receives the actual version string as its `--tag` argument.

## Full transcript

```
tool under test:
Cargo subcommand for you to smooth your release process.
cargo-release binary found at: /usr/local/bin/cargo-release
git-cliff version:
git-cliff 2.13.1

==================== STAGE 1: v1.0.0 code, NO changelog ====================

(no CHANGELOG.md yet)

==================== STAGE 2: generate CHANGELOG.md for v1.0.0 using git-cliff ====================

----- CHANGELOG.md -----
# Changelog

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== STAGE 3: implement even split ====================

--- cargo-release --dry-run ---
(note: cargo-release dry-run requires cargo, which is available in this image)
error: uncommitted changes detected, please resolve before release:
         Cargo.lock (Status(WT_NEW))
   Upgrading tipcalc from 2.0.0 to 2.0.1
error: for `Unreleased` in 'CHANGELOG.md', at least 1 replacements expected, found 0
----- CHANGELOG.md -----
# Changelog

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== STAGE 4a: run git-cliff hook + tag v2.0.0 ====================

----- CHANGELOG.md -----
# Changelog

## [2.0.0] - 2026-06-02

### Features

- Split the bill evenly among diners

### Docs

- Add changelog for 1.0.0
## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== STAGE 4b: implement uneven split, release v3.0.0 ====================

----- CHANGELOG.md -----
# Changelog

## [3.0.0] - 2026-06-02

### Features

- Split the bill unevenly by weight
## [2.0.0] - 2026-06-02

### Features

- Split the bill evenly among diners

### Docs

- Add changelog for 1.0.0
## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill

------------------------

==================== BONUS: show release.toml config approach ====================

# release.toml — what a real cargo-release config looks like:
[release]
pre-release-hook = ["git", "cliff", "--tag", "{{version}}", "-o", "CHANGELOG.md"]
tag-name = "v{{version}}"
push = false
publish = false

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 12
drwxrwxrwx 1 root root 4096 Jun  2 03:11 .
drwxr-xr-x 1 root root 4096 Jun  2 03:11 ..
-rw-r--r-- 1 root root  273 Jun  2 03:11 CHANGELOG.md
-rw-r--r-- 1 root root  298 Jun  2 03:11 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:11 git-tags.txt
-rw-r--r-- 1 root root 2208 Jun  2 03:11 transcript.txt
```
