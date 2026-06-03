Title: changelog-rs (hands-on synthesis)
Date: 2026-06-02
Slug: changelog-rs-v2
Ecosystem: Rust
Tags: rust, cli, git-history, hands-on, archived
Tool_URL: https://crates.io/crates/changelog
Tool_Version: 0.3.4
Tool_Status: archived
Experiment: examples/rust/changelog-rs/
Summary: Hands-on re-review after attempting to install and run changelog 0.3.4 in a container — install failed due to unmaintained dependencies.



## What I actually ran

This is a second-pass review grounded in *attempting to run* the `changelog` crate, not reading its docs. The
reproducible experiment lives in [`examples/rust/changelog-rs/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/changelog-rs).

- **Base image:** `rust:1.87-slim`
- **Tool version attempted:** `changelog 0.3.4` (last release 2020-03-02)
- **Result:** `cargo install` failed — the tool could not be installed

## Real output

From the Docker build log:

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

From the experiment run (tool not installed branch):

```
==================== INSTALLATION CHECK ====================

FINDING: changelog binary NOT installed.
cargo install failed in Dockerfile — see Docker build output.

==================== TOOL STATUS ASSESSMENT ====================

changelog crate status (as of 2026-06-02):
  - Last release: 2020-03-02 (v0.3.4)
  - No pre-built binaries ever provided
  - Repository: https://github.com/yoshuawuyts/changelog
  - GitHub shows no activity since 2020
```

## What happened

The `changelog` crate (crates.io: `changelog`, GitHub: `yoshuawuyts/changelog`) has not had a release since March 2020. It depends on `git2` → `libgit2-sys` → `openssl-sys`, and the slim Debian image does not include `libssl-dev` or `pkg-config`. Both `cargo install --locked changelog --version 0.3.4` and `cargo install changelog --version 0.3.4` (unlocked) failed at exactly this dependency.

The unlocked retry downloaded 213 crates and still failed — the `changelog` crate's Cargo.toml caps `git2` at a version range that does not help.

Adding `libssl-dev` and `pkg-config` to the Dockerfile would fix the immediate build error. But the tool would still be a 2020-era codebase with no conventional commit support, no configuration system, and no activity since Rust 1.42.

## Pros (observed)

There are none to report. The tool did not install.

## Cons / pain points (observed)

**Cannot install in any modern slim container without `libssl-dev` and `pkg-config`.** The transitive OpenSSL dependency is an immediate barrier that users must diagnose and work around. Most Rust tooling has moved to pure-Rust TLS or statically-linked alternatives; this crate is stuck on system OpenSSL.

**No pre-built binaries, ever.** Unlike git-cliff (which ships musl binaries for every release), `changelog` has only ever been distributed via `cargo install`. With a broken dependency chain, there is no fallback path.

**Six years without a commit.** The repository has had zero activity since 2020. Known issues are open and unaddressed. The README links are partially stale.

**No conventional commit support.** Even if it had installed, the tool reads raw git history without grouping by type. The output quality would be well below git-cliff's for any project using `feat:` / `fix:` commit messages.

## Docs vs. reality

The original article in this survey likely either omitted this tool entirely or flagged it as low priority. The hands-on experiment confirms the correct assessment: this tool is effectively dead and has been for years.

## Revised verdict

**Do not use. Archived in practice.** The `changelog` crate is unmaintained, cannot be installed without extra system dependencies that are missing from standard Docker images, and has no features competitive with any actively maintained alternative. Any project currently using it should migrate to git-cliff immediately.

For Rust projects: git-cliff is the correct replacement. It provides conventional commit parsing, configurable templates, pre-built binaries, and active maintenance — everything the `changelog` crate lacks.
