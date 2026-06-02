# Rust tool experiments

Six Rust changelog/release tools, each driven through the tip-calculator life cycle in Docker.
Run any experiment with `make run` from its directory. Artifacts land in `out/`.

## Results (run date: 2026-06-02)

| Tool | Version | Outcome | Headline finding |
|------|---------|---------|-----------------|
| [git-cliff](git-cliff/) | 2.13.1 | ✅ Full success | Best-in-class. Pre-built musl binary, Tera templates, `--unreleased`/`--latest` flags all work. Minor: missing blank lines between release sections (template whitespace issue). |
| [cargo-release](cargo-release/) | 1.1.2 | ✅ Full success | Pure orchestrator — no changelog opinions. Use git-cliff as a hook. Two config notes: `[Unreleased]` header mismatch with git-cliff format; Cargo.lock must be committed before release. |
| [release-plz](release-plz/) | 0.3.158 | ⚠️ Limited locally | `release-plz update` works offline for one release, but crates.io is the version source of truth — second release never generated without a published crate. `release-plz changelog` subcommand does not exist in this version. |
| [cargo-dist](cargo-dist/) | 0.32.0 | ❌ Not a changelog tool | All commands require a `repository` GitHub URL — no offline/local mode. Reads `CHANGELOG.md` for GitHub Release body but generates nothing itself. |
| [cargo-smart-release](cargo-smart-release/) | 0.21.11 | ⚠️ Works with setup | Needs `rust:1.89-slim` + `libssl-dev` + `pkg-config` (not rust:1.87). `feat!` → `New Features (BREAKING)` works. `<csr-id-SHA/>` sentinel tags in the file enable idempotent generation but make manual editing impractical. Unusable for private/unpublished crates without removing `publish = false`. |
| [changelog-rs](changelog-rs/) | 0.3.4 | ❌ Dead | `cargo install` fails: unmaintained OpenSSL dependency. No pre-built binaries. Last release 2020. Replace with git-cliff. |

## Recommended stack

- **Changelog generation:** git-cliff
- **Release orchestration (publishes to crates.io):** cargo-release + git-cliff hook, or release-plz
- **Distribution (CI binary packaging):** cargo-dist (reads the changelog git-cliff wrote)
- **Multi-crate workspace (gitoxide-style):** cargo-smart-release (requires published crates + remote)

## Key gotchas

- `cargo-release` and `git-cliff` use incompatible changelog conventions by default: cargo-release looks for `## [Unreleased]`; git-cliff doesn't write one. Disable cargo-release's replacement feature and let the git-cliff hook own the file entirely.
- `release-plz` uses crates.io as the version source of truth, not git tags. It cannot simulate a multi-version history for unpublished crates.
- `cargo-dist init` requires a `repository = "https://github.com/..."` key in `Cargo.toml` before any command works — including `plan` and `manifest`.
- `cargo-smart-release` enforces a clean working tree. Even `Cargo.lock` being untracked blocks every command.
