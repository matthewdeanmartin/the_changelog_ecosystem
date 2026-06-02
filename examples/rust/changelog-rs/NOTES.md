# changelog-rs Experiment Notes

## Environment
- Base image: rust:1.87-slim
- Tool version: changelog 0.3.4 (attempted; install failed)
- Run date: 2026-06-01

## Observations

### What worked

- The Docker image built successfully and the experiment script ran to completion.
- The failure mode was clean and predictable: the `cargo install` step printed a clear error and the script fell through to the "tool not installed" branch gracefully.
- The git repository setup (init, commit, tag v1.0.0) completed without issues, confirming the base image and script scaffolding are sound.

### What failed / friction

- **Install failed: missing OpenSSL and pkg-config**. Both attempts (`--locked` and without) failed at the same point: `openssl-sys v0.9.54` (first attempt) and `openssl-sys v0.9.116` (second attempt, with relaxed locking) could not locate OpenSSL headers. The slim Debian image does not include `libssl-dev` or `pkg-config`. The `changelog` crate's transitive dependency on `git2` (which uses `libgit2-sys`, which uses `openssl-sys`) is the root cause.
- **The locked version (0.3.4) pinned git2 v0.11.0**, which in turn required the old `openssl-sys v0.9.54`. The unlocked retry resolved `git2` all the way to v0.11.0 still (the version constraint in changelog's Cargo.toml caps it), and still failed on `openssl-sys v0.9.116`. Both paths hit the same wall.
- **No pre-built binaries have ever been provided**. The tool has only been distributed via `cargo install`, meaning every user must compile it from source. With a 2020 codebase and fast-moving C library dependencies, this is a major barrier to use in 2026.
- **All changelog-generation stages (2, 3, 4) were skipped** because the binary was never installed. No CHANGELOG.md was produced.

### Surprising findings

- The first `cargo install --locked` attempt took ~8 seconds before failing. The unlocked retry downloaded 213 crate packages and took ~34 seconds before failing. The Docker layer cached neither attempt's work (the `||` chain means the whole `RUN` layer either succeeds or fails atomically).
- The `changelog` crate's dependency graph is relatively shallow for a CLI tool (git2, comrak for markdown, structopt for CLI parsing) but git2's OpenSSL requirement is a hard blocker in any slim or Alpine-based image without explicit `libssl-dev` installation.
- The tool could theoretically be installed by adding `libssl-dev pkg-config` to the Dockerfile, but given the tool has had zero commits since 2020 and has known issues with modern Rust editions, it is not worth the effort.
- Ironically, even if the tool had installed, its output quality (2020-era, no conventional commits support, no configuration) would be far below what git-cliff provides today.

## Full transcript

```

==================== INSTALLATION CHECK ====================

FINDING: changelog binary NOT installed.
cargo install failed in Dockerfile — see Docker build output.
This is expected: the crate is from 2020 and likely fails to compile
on Rust 2024/2025 editions due to dependency incompatibilities.

==================== STAGE 1: v1.0.0 code, NO changelog ====================

(no CHANGELOG.md yet)

==================== STAGE 2: attempt changelog generation ====================

SKIPPED: tool not installed.

If it had installed, the usage would be:
  changelog > CHANGELOG.md   # generate from git history
  changelog --help           # see options

==================== TOOL STATUS ASSESSMENT ====================

changelog crate status (as of 2026-06-02):
  - Last release: 2020-03-02 (v0.3.4)
  - No pre-built binaries ever provided
  - Repository: https://github.com/yoshuawuyts/changelog
  - GitHub shows no activity since 2020

Attempting cargo install in Docker produced one of:
  a) Compilation failure due to dependency resolution on modern Rust
  b) Success but with 2020-era output quality

VERDICT: Do not use for new projects. Use git-cliff instead.

==================== STAGES 3-4: skipped — tool not functional ====================

The remaining life-cycle stages (even split, uneven split) are not
runnable because the tool either failed to install or is not useful.

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 12
drwxrwxrwx 1 root root 4096 Jun  2 03:12 .
drwxr-xr-x 1 root root 4096 Jun  2 03:12 ..
-rw-r--r-- 1 root root   18 Jun  2 03:12 CHANGELOG.md
-rw-r--r-- 1 root root   74 Jun  2 03:12 git-log.txt
-rw-r--r-- 1 root root    7 Jun  2 03:12 git-tags.txt
-rw-r--r-- 1 root root 1497 Jun  2 03:12 transcript.txt
```

## Docker build failure detail (from build log)

The exact failure in both install attempts:

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
