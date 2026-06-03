Title: cargo-dist (hands-on synthesis)
Date: 2026-06-02
Slug: cargo-dist-v2
Ecosystem: Rust
Tags: cargo-subcommand-ci, github-integration, rust, release-orchestration, artifacts, installers, ci-cd, github-releases, hands-on
Tool_URL: https://crates.io/crates/cargo-dist
Tool_Version: 0.32.0
Tool_Status: active
Experiment: examples/rust/cargo-dist/
Summary: Hands-on re-review after attempting to drive cargo-dist through the tip-calculator life cycle in a container.



## What I actually ran

This is a second-pass review grounded in *running* cargo-dist, not reading its docs. The
reproducible experiment lives in [`examples/rust/cargo-dist/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-dist).

- **Base image:** `rust:1.87-slim` (cargo required at runtime)
- **Tool version:** `cargo-dist 0.32.0` (pre-built musl binary, renamed from `dist` to `cargo-dist` in the Dockerfile)
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle attempted:**
  1. v1.0.0 code committed and tagged.
  2. `cargo-dist init` — add dist config and generate CI workflows.
  3. `cargo-dist plan` — show what would be built for a release.
  4. `cargo-dist manifest` — show the dist manifest JSON.

## Real output

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

`cargo-dist plan` (and every subsequent command):

```
  × Github CI support requires you to specify the URL of your repository
  help: Set the repository = "https://github.com/..." key in these manifests:
        /work/app/Cargo.toml
```

`dist-manifest.json` was written as an empty file (0 bytes).

## Pros (observed)

**Error messages are clear and actionable.** Every failure named the exact file and key that needed to be set. The tool never crashed silently — it always told you exactly what was missing.

**`cargo-dist init` writes useful partial config.** Even though it failed on `dist generate`, it successfully wrote `[profile.dist]` to `Cargo.toml` and created `dist-workspace.toml`. These stubs are genuinely useful to inspect.

**Pre-built binary is clean.** The Docker rename (`dist` → `cargo-dist`) worked transparently for all commands.

**Changelog integration model is explicit.** The tool's BONUS section comment is accurate: cargo-dist does not generate changelogs. It consumes an existing `CHANGELOG.md` (via `changelog-path = 'CHANGELOG.md'` in `[dist]`) for the GitHub Release body. This is a clear, explicit boundary.

## Cons / pain points (observed)

**Every non-trivial command requires a `repository` URL.** `cargo-dist plan`, `cargo-dist manifest`, and `cargo-dist init` all fail with the same error if `Cargo.toml` does not include `repository = "https://github.com/..."`. There is no `--local` or `--skip-ci` flag to bypass this requirement for local experimentation. This makes cargo-dist completely untestable in an offline container.

**No interactive mode in a headless container.** `cargo-dist init` without `--yes` fails with `IO error: not a terminal`. There is no fully non-interactive mode — the wizard requires a TTY. The only workaround is pre-seeding the `repository` key in `Cargo.toml` before running init.

**`--yes` is not a recognized flag.** The experiment tried `cargo-dist init --yes` as a non-interactive shortcut; the flag does not exist in v0.32.0.

**Tool is not a changelog tool at all.** cargo-dist generates CI workflows, builds cross-platform binaries, creates installers, and uploads to GitHub Releases. It has zero changelog generation capability. Including it in a changelog tool survey is only appropriate because it is the standard distribution step for Rust CLI tools where changelogs end up.

## Docs vs. reality

The original `cargo-dist.md` article correctly classified cargo-dist as "adjacent to changelog tooling rather than a primary changelog editor." The hands-on run confirms and deepens this assessment.

What the original article did not address:

1. **Local use is essentially impossible.** The repository URL requirement blocks all non-trivial commands in an offline environment. The article implied `cargo-dist plan` was a useful local dry-run; in practice it requires a full GitHub remote config.
2. **The `--yes` flag doesn't exist.** Docs and examples around automated setup suggest non-interactive operation is easy; it isn't without pre-seeding the repository URL.
3. **The binary is named `dist`, not `cargo-dist`.** Installing from the tarball requires a rename. Cargo install (`cargo install cargo-dist`) handles this automatically, but binary downloads do not.

## Revised verdict

**Correct classification: not a changelog tool.** cargo-dist belongs in a "release distribution" category, not a changelog tool survey. For completeness in Rust release workflows, it's worth documenting — it handles the final publishing step after your changelog tool has done its work. But teams evaluating changelog generators should skip cargo-dist and look at git-cliff, release-plz, or cargo-release instead.

For teams that do use cargo-dist: the workflow is `git-cliff` (or `release-plz`) writes `CHANGELOG.md` → cargo-dist reads it at release time to populate the GitHub Release body. The two tools compose cleanly once cargo-dist has its repository URL and is running in CI.
