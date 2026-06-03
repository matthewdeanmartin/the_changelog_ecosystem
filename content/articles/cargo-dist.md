Title: cargo-dist
Date: 2026-06-02
Slug: cargo-dist
Ecosystem: Rust
Tags: cargo-subcommand-ci, github-integration, rust, release-orchestration, artifacts, installers, ci-cd, github-releases, hands-on
Tool_URL: https://crates.io/crates/cargo-dist
Tool_Version: 0.32.0
Tool_Status: active
Experiment: examples/rust/cargo-dist/
Summary: Hands-on-grounded review of cargo-dist, a Rust release distribution tool that ships artifacts/installers to GitHub Releases; it consumes (but never generates) changelogs.



## Overview

`cargo-dist` is release distribution infrastructure for Rust applications. It generates CI workflows, builds release artifacts, creates installers, uploads checksums and manifests, and announces releases through GitHub Releases or related hosting.

It is adjacent to changelog tooling rather than a primary changelog editor. Its importance here is that many Rust CLI projects need release notes to travel with binaries, installers, and GitHub Releases, and `cargo-dist` is one of the strongest tools for that final distribution step.

A reproducible hands-on experiment for this tool lives in [`examples/rust/cargo-dist/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-dist).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), cargo-dist could not be driven through any non-trivial command in an offline container. Every command (<code>init</code>, <code>plan</code>, <code>manifest</code>) failed with <em>"Github CI support requires you to specify the URL of your repository"</em> because there is no <code>--local</code>/<code>--skip-ci</code> mode. The tool is not unusable — it is simply designed to run against a real GitHub remote inside CI. To exercise it locally you must pre-seed a <code>repository</code> URL in <code>Cargo.toml</code>. See the hands-on findings below.
</div>

## Installation

```bash
cargo install cargo-dist
```

Note: the binary shipped in axodotdev's release tarball is named `dist`, not `cargo-dist`. `cargo install` handles the naming, but manual/binary installs require a rename (the experiment's Dockerfile renames `dist` → `cargo-dist`).

## What It Does

- Generates GitHub Actions workflows for release builds.
- Builds platform artifacts for Rust binaries and other supported projects.
- Produces installers and installation scripts for end users.
- Publishes artifacts, checksums, and manifests to GitHub Releases or other configured hosts.
- Can interoperate with tools such as `cargo-release`, Release Drafter, or a manually maintained release notes file.

It does **not** generate changelogs. It can *consume* an existing `CHANGELOG.md` (via `changelog-path` in the `[dist]` config) to populate the GitHub Release body, but a separate tool (git-cliff, release-plz, etc.) must produce that file.

## Configuration

Newer projects can use `dist-workspace.toml` or `dist.toml`; Rust projects may also have older `[workspace.metadata.dist]` style configuration. `dist init` creates the baseline config and generated CI workflow.

```toml
[dist]
cargo-dist-version = "0.32.0"
ci = ["github"]
installers = ["shell", "powershell"]
targets = ["x86_64-unknown-linux-gnu", "x86_64-pc-windows-msvc", "aarch64-apple-darwin"]
create-release = true
publish-jobs = ["homebrew"]
changelog-path = "CHANGELOG.md"  # used for the GitHub Release body
```

First-run setup is moderate because the tool touches CI, target platforms, hosting, installers, and release announcements. Changelog configuration is usually handled by a companion tool or by release notes already present in the repository.

## Output Quality

The user-facing output is a release announcement with artifacts attached, not a changelog file. When properly configured against a GitHub remote and running in CI, cargo-dist packages and publishes upstream release notes cleanly. If the project has no changelog discipline, cargo-dist will not fix that by itself.

(The original version of this article showed an imagined release-announcement block here. We removed it because we were unable to produce real release output in the offline experiment — see the hands-on transcript below for the actual behavior.)

## Ecosystem Fit

For Rust CLI applications, cargo-dist fits beautifully: it understands Cargo, target triples, generated CI, installers, and GitHub Releases. It fills a gap that crates.io publishing does not cover, especially for end users who expect downloadable binaries.

For libraries, it is usually unnecessary. Library crates care more about crates.io, semver, and changelog text than binary distribution.

## Maintenance Status

- Latest version: **0.32.0**
- Last release: **2026-05-22**
- GitHub stars: **2,044**
- Appears actively maintained.
- Repository: <a href="https://github.com/axodotdev/cargo-dist" target="_blank" rel="noopener noreferrer">https://github.com/axodotdev/cargo-dist</a>

The current docs cover config files, generated CI, custom jobs, publish phases, installer options, GitHub release behavior, and integration patterns with tools such as `cargo-release`.

---

## Hands-on findings

This section is grounded in *running* cargo-dist in a container, not reading its docs. The reproducible experiment lives in [`examples/rust/cargo-dist/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-dist).

### What we ran

- **Base image:** `rust:1.87-slim` (Debian Bookworm; cargo required at runtime)
- **Tool version:** `cargo-dist 0.32.0` (pre-built musl binary, renamed from `dist` to `cargo-dist` in the Dockerfile)
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle attempted:**
  1. v1.0.0 code committed and tagged.
  2. `cargo-dist init` — add dist config and generate CI workflows.
  3. `cargo-dist plan` — show what would be built for a release.
  4. `cargo-dist manifest` — show the dist manifest JSON.

### Real output

`cargo-dist init` partial output:

```
let's setup your dist config...

✔ added [profile.dist] to your workspace Cargo.toml
✔ added [dist] to your root dist-workspace.toml
✔ dist is setup!

running 'dist generate' to apply any changes

  × Github CI support requires you to specify the URL of your repository
  help: Set the repository = "https://github.com/..." key in these manifests:
        /work/app/Cargo.toml
```

`cargo-dist plan` and `cargo-dist manifest` (and every subsequent command):

```
  × Github CI support requires you to specify the URL of your repository
  help: Set the repository = "https://github.com/..." key in these manifests:
        /work/app/Cargo.toml
```

`dist-manifest.json` was written as an empty file (0 bytes) because `manifest` failed before writing anything. No `.github/` CI workflow was generated.

### Pros (observed)

- **Error messages are clear and actionable.** Every failure named the exact file and key that needed to be set. The tool never crashed silently.
- **`cargo-dist init` writes useful partial config.** Even though it failed on `dist generate`, it successfully wrote `[profile.dist]` to `Cargo.toml` and created `dist-workspace.toml` with a `[dist]` section. These stubs are genuinely useful to inspect.
- **The pre-built binary is clean.** The Docker rename (`dist` → `cargo-dist`) was transparent to all commands.
- **The changelog integration model is explicit.** cargo-dist consumes an existing `CHANGELOG.md` for the GitHub Release body; it does not pretend to generate one. A clear, honest boundary.

### Cons / pain points (observed)

- **Every non-trivial command requires a `repository` URL.** `plan`, `manifest`, and `init` all fail identically if `Cargo.toml` lacks `repository = "https://github.com/..."`. There is no `--local` or `--skip-ci` flag to bypass this for local experimentation — making cargo-dist effectively untestable in an offline container.
- **No fully non-interactive mode in a headless container.** `cargo-dist init` without a TTY fails with `IO error: not a terminal`; the wizard requires a terminal. The only workaround is pre-seeding the `repository` key.
- **`--yes` is not a recognized flag** in v0.32.0; attempting it does not give a non-interactive shortcut.
- **It is not a changelog tool at all.** Zero changelog generation capability. It is in this survey only because it is the standard distribution step for Rust CLI tools where changelogs end up.

### Docs vs. reality

The original article correctly classified cargo-dist as "adjacent to changelog tooling." The hands-on run confirms and deepens that. What the original did not address:

1. **Local use is essentially impossible.** The repository URL requirement blocks all non-trivial commands offline. `cargo-dist plan` is *not* a useful local dry-run without a full GitHub remote config.
2. **The `--yes` flag doesn't exist.** Non-interactive operation is not as easy as docs imply without pre-seeding the repository URL.
3. **The binary is named `dist`, not `cargo-dist`.** Binary/tarball installs require a rename.

## Verdict

**Verdict: Situational — and correctly classified as *not* a changelog tool.**

Use `cargo-dist` when the release problem is "ship binaries and installers with solid GitHub Releases," and expect to run it against a real GitHub remote inside CI. Teams evaluating *changelog generators* should look at `git-cliff`, `release-plz`, or `cargo-release` instead.

For teams that do use cargo-dist, the workflow composes cleanly: `git-cliff` (or `release-plz`) writes `CHANGELOG.md` → cargo-dist reads it at release time to populate the GitHub Release body, then publishes artifacts and installers. The catch confirmed by the hands-on run: this only works once cargo-dist has its repository URL and is running in CI — there is no meaningful offline/local mode today. If you need that, you would have to fork it and add a `--local` path yourself.
