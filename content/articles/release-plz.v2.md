Title: release-plz (hands-on synthesis)
Date: 2026-06-02
Slug: release-plz-v2
Ecosystem: Rust
Tags: github-integration, rust, semantic-versioning, release-pr, crates-io, changelog-file, ci-cd, git-cliff, hands-on
Tool_URL: https://crates.io/crates/release-plz
Tool_Version: 0.3.158
Tool_Status: active
Experiment: examples/rust/release-plz/
Summary: Hands-on re-review after driving release-plz through the tip-calculator life cycle in a container.



## What I actually ran

This is a second-pass review grounded in *running* release-plz, not reading its docs. The
reproducible experiment lives in [`examples/rust/release-plz/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/release-plz).

- **Base image:** `rust:1.87-slim` (cargo required at runtime; release-plz itself is a pre-built musl binary)
- **Tool version:** `release-plz 0.3.158`
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog.
  2. `release-plz changelog` — tested as a subcommand (spoiler: does not exist).
  3. Implement even-split feature; `release-plz update` — bumps version + writes CHANGELOG.md.
  4. Tag v2.0.0 manually; attempt `release-plz update` again for v3.0.0.

## Real output

CHANGELOG.md after `release-plz update` (stage 3):

```markdown
# Changelog

## [1.0.0] - 2026-06-02

### Features

- Compute tip for a single bill
- Split the bill evenly among diners
```

After a second `release-plz update` attempt for v3.0.0 (stage 4b), the tool printed:

```
INFO the repository is already up-to-date
```

No new CHANGELOG entry was written.

## Pros (observed)

**`release-plz update` works entirely offline with `publish = false`.** Setting `publish = false` and `git_release_enable = false` in `release-plz.toml` suppressed all network-dependent behavior. The tool ran in a headless Docker container with no internet access to the actual crate, produced a valid CHANGELOG.md, and bumped Cargo.toml version — in one command.

**Zero changelog config needed.** The tool parsed conventional commit messages (`feat:`) and produced a grouped, dated Keep-a-Changelog-compatible file without any `[git]` or `[changelog]` configuration beyond the top-level workspace settings.

**Clear, actionable warnings.** Every problem was flagged: missing remote URL, missing crates.io package, and "already up-to-date" status were all explicit INFO/WARN messages, not silent failures.

**Single command for the combined update.** One `release-plz update` bumps `Cargo.toml`, writes `CHANGELOG.md`, and optionally commits — all from a single invocation. Compared to the git-cliff workflow (generate changelog separately, bump version separately), this is significantly less ceremony.

## Cons / pain points (observed)

**`release-plz changelog` does not exist in v0.3.158.** The script tested this subcommand speculatively based on docs; the tool responded `error: unrecognized subcommand 'changelog'`. The only way to generate a changelog is `release-plz update`. This is a documentation/discoverability issue.

**crates.io is the version source of truth, not git tags.** release-plz uses the registry to determine "what is already released" and computes the next version as a delta. Because the `tipcalc` fixture is not published, the tool could not determine a second "next version" after v1.0.0 — a second `release-plz update` call reported `already up-to-date` regardless of new commits or local tags. This is a fundamental design constraint, not a bug: the tool is designed for published crates with a real registry history.

**Multi-release simulation fails in a purely local scenario.** In the experiment, only one changelog entry was ever produced (v1.0.0), even though three versions and commits existed. The two features (even-split and uneven-split) were both attributed to `1.0.0` in the changelog because release-plz could not distinguish them without crates.io history.

**No hyperlinks in changelog without a remote.** The `Cannot determine repo url` warning is harmless but means the generated CHANGELOG has no release comparison links (`[1.0.0]: https://...`). These links are standard in Keep a Changelog format.

**`release-plz release-pr` and `release-plz release` require GitHub.** These are the primary value-add commands (open a release PR, publish after merge) — and neither can be demonstrated in a local container experiment. The tool's main workflow is fundamentally CI-native.

## Docs vs. reality

The original `release-plz.md` article accurately described the tool's overall workflow and noted its crates.io dependency. What it did not make explicit:

1. **The `changelog` subcommand does not exist** (at least in 0.3.158). Docs and blog posts refer to `release-plz changelog` as a way to preview notes — this was not a working command in the version tested.
2. **The local-only workflow is limited to a single release cycle.** For multi-release simulations (the full scenario we use for every tool), release-plz cannot advance past v1.0.0 without a real published crate. The original article does not call this out.
3. **The tool is primarily a CI automation layer over git-cliff.** Locally, `release-plz update` is useful for seeing what the next release would look like, but the full value requires GitHub tokens, a real remote, and crates.io.

The original article's description of the PR-based release workflow is accurate — we just cannot demonstrate it locally.

## Revised verdict

**Downgrade from "works anywhere" to "CI-native tool with limited local utility."** release-plz is an excellent choice for Rust projects that publish to crates.io and use GitHub, where it delivers a fully automated release PR → publish workflow. Locally it is a changelog previewer and version bumper, but the crates.io dependency means it cannot simulate a multi-version history in isolation. For teams that need a pure local changelog generator, git-cliff is the better fit; for teams that need the full release automation story, release-plz delivers.
