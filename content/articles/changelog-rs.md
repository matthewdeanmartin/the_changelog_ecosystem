Title: changelog-rs
Date: 2026-06-02
Slug: changelog-rs
Ecosystem: Rust
Tags: rust, cargo-install, git-history, changelog-file, legacy, archived, hands-on
Tool_URL: https://crates.io/crates/changelog
Tool_Version: 0.3.4
Tool_Status: archived
Experiment: examples/rust/changelog-rs/
Summary: Hands-on-grounded review of changelog-rs (the `changelog` crate) — an archived 2020-era tool that no longer installs cleanly; git-cliff is the modern replacement.



## Overview

`changelog-rs`, published as the `changelog` crate, is an older Rust command-line/library attempt at generating changelog entries from git commits and tags. It can inspect repository history, format commits, and prepend generated material to a changelog file.

In 2026, it is best treated as historical context rather than a current recommendation. The Rust ecosystem has largely moved toward `git-cliff` for commit-derived changelogs and `release-plz` or `cargo-release` for release orchestration.

A reproducible hands-on experiment for this tool lives in [`examples/rust/changelog-rs/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/changelog-rs).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), the <code>changelog</code> crate could not be installed at all. <code>cargo install changelog 0.3.4</code> failed during compilation because its transitive dependency chain (<code>git2 → libgit2-sys → openssl-sys</code>) needs system OpenSSL headers (<code>libssl-dev</code>) and <code>pkg-config</code>, which are absent from standard slim images. The crate has had no release since March 2020 and ships no pre-built binaries. It appears unmaintained / does not currently install out of the box. It is not unusable — you could add <code>libssl-dev</code>/<code>pkg-config</code> to your environment, or fork the crate and modernize its dependencies — but for most teams git-cliff is the practical replacement. See the hands-on findings below.
</div>

## Installation

```bash
cargo install changelog
```

As the warning above notes, this currently fails on a standard slim image without `libssl-dev` and `pkg-config` installed first. There are no pre-built binaries to fall back on.

## What It Does

- Reads git repository metadata and commit history.
- Discovers tags and computes diffs for a path.
- Formats commit lists into changelog entries.
- Prepends generated changelog text to an existing file.
- Exposes some of the same functionality as a Rust library.

## Configuration

The crate is small and older, with a CLI-oriented workflow rather than a modern, heavily documented config file. A basic usage pattern is closer to:

```bash
changelog --help
changelog > CHANGELOG.md
```

First-run setup is simple in principle, but the lack of an actively documented configuration story is a key weakness. Teams wanting custom grouping, templates, or CI policy will outgrow it quickly — and (per the hands-on run) most teams will not get it installed at all without fixing system dependencies first.

## Output Quality

We could not produce real output because the tool failed to install. (The original version of this article showed an *imagined* changelog block here; it has been removed because no real output was generated. See the hands-on findings for the actual failure transcript.)

Even if it had installed, the output would be 2020-era and utilitarian: raw commit lists with no conventional-commit grouping (`feat:` / `fix:` types are not understood), well below git-cliff's quality for any project using conventional commits.

## Ecosystem Fit

The tool is Rust-native in the narrow sense that it is a Cargo-installed Rust crate. It does not feel current compared with the rest of the Rust release ecosystem, especially now that `git-cliff` can do richer parsing and templating while remaining easy to install with Cargo — and ships musl binaries for every release, which this crate never has.

For new projects, there is little reason to start here unless you are preserving an existing workflow that already uses it (and are prepared to fix its build).

## Maintenance Status

- Latest version: **0.3.4**
- Last release: **2020-03-02** (over six years ago)
- GitHub shows no activity since 2020; known issues are open and unaddressed.
- Effectively **archived**.
- Repository: <a href="https://github.com/yoshuawuyts/changelog" target="_blank" rel="noopener noreferrer">https://github.com/yoshuawuyts/changelog</a>

The docs.rs API page still exists, but the release cadence indicates this is not an actively evolving changelog tool.

---

## Hands-on findings

This section is grounded in *attempting to run* the `changelog` crate in a container, not reading its docs. The reproducible experiment lives in [`examples/rust/changelog-rs/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/changelog-rs).

### What we ran

- **Base image:** `rust:1.87-slim`
- **Tool version attempted:** `changelog 0.3.4` (last release 2020-03-02)
- **Result:** `cargo install` failed — the tool could not be installed, so all changelog-generation stages were skipped and no `CHANGELOG.md` was produced.

### Real output

From the Docker build log (identical for both the `--locked` and unlocked attempts):

```
error: failed to run custom build command for `openssl-sys v0.9.54`
  Could not find directory of OpenSSL installation...
  Make sure you also have the development packages of openssl installed.
  For example, `libssl-dev` on Ubuntu or `openssl-devel` on Fedora.
  It looks like you're compiling on Linux and also targeting Linux. Currently this
  requires the `pkg-config` utility to find OpenSSL but unfortunately `pkg-config`
  could not be found.

error: failed to compile `changelog v0.3.4`
WARNING: changelog install failed (expected for an archived 2020 crate)
```

### What happened

The crate depends on `git2 → libgit2-sys → openssl-sys`, and the slim Debian image lacks `libssl-dev` and `pkg-config`. The `--locked` install pinned `git2 v0.11.0` (needing the old `openssl-sys v0.9.54`); the unlocked retry downloaded 213 crates and still failed on `openssl-sys v0.9.116`. Both paths hit the same wall. The experiment script handled the failure cleanly, falling through to a "tool not installed" branch.

### Pros (observed)

None to report — the tool did not install.

### Cons / pain points (observed)

- **Cannot install in a modern slim container without `libssl-dev` and `pkg-config`.** The transitive OpenSSL dependency is an immediate barrier. Most current Rust tooling has moved to pure-Rust TLS or static linking; this crate is stuck on system OpenSSL.
- **No pre-built binaries, ever.** With a broken dependency chain there is no fallback path (unlike git-cliff's musl binaries).
- **Six years without a commit.** Zero repository activity since 2020; open issues unaddressed; partially stale README links.
- **No conventional commit support.** Even installed, it reads raw git history without grouping by type — output quality well below git-cliff for projects using `feat:`/`fix:`.

### Docs vs. reality

The hands-on experiment confirms the assessment: this tool is effectively dead and has been for years. The dependency chain alone now blocks installation on standard images.

## Verdict

**Verdict: Unmaintained / does not install out of the box — fork it if you truly need it, otherwise use git-cliff.**

The `changelog` crate is effectively archived, ships no pre-built binaries, and cannot be installed on a standard slim image without first adding `libssl-dev` and `pkg-config` — and even then you would be running a 2020-era codebase with no conventional-commit support and no configuration system. It is not technically impossible to revive: you could install the missing system packages, or fork the crate and modernize its `git2`/`openssl` dependencies. But for any project that just wants a working changelog tool today, git-cliff is the correct replacement: conventional-commit parsing, configurable templates, pre-built binaries, and active maintenance — everything the `changelog` crate lacks.
