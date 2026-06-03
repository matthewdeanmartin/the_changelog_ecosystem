Title: git-cliff
Date: 2026-06-02
Slug: git-cliff
Ecosystem: Rust
Tags: backfill, cli, conventional-commits, custom-templates, release-notes, rust, keep-a-changelog, git-tags, ci-cd, github-integration, gitlab-integration, hands-on
Tool_URL: https://crates.io/crates/git-cliff
Tool_Version: 2.13.1
Tool_Status: active
Experiment: examples/rust/git-cliff/
Summary: Hands-on-grounded review of git-cliff, the highly customizable Rust changelog generator — the default to evaluate first, with one template-whitespace gotcha.



## Overview

`git-cliff` is the Rust-written changelog generator that has become a cross-language default. It reads git history, groups commits with Conventional Commits or custom regex parsers, and renders Markdown or other text formats through configurable templates.

For Rust projects, it is often the changelog engine inside a larger release flow: use it directly for `CHANGELOG.md`, call it from `cargo-release`, or let `release-plz` use it under the hood.

A reproducible hands-on experiment for this tool lives in [`examples/rust/git-cliff/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/git-cliff).

## Installation

```bash
cargo install git-cliff
```

In the experiment we used the pre-built musl binary from GitHub Releases instead — it is self-contained, has no shared-library dependencies, and needs no Rust toolchain at runtime.

## What It Does

- Generates changelog files from tags, commit ranges, or the whole repository history.
- Parses Conventional Commits out of the box and supports custom commit parsers for nonstandard histories.
- Renders output with Tera templates, so teams can target Keep a Changelog, GitHub Releases, AsciiDoc, or local house style.
- Can include remote metadata from supported Git hosting providers, such as pull request numbers and authors.
- Supports backfilling old releases and writing directly to `CHANGELOG.md`.
- Can fail CI when commits do not match configured rules (`fail_on_unmatched_commit`, which defaults to `false`).

## Configuration

`git-cliff --init` creates `cliff.toml`, and Rust projects can also keep configuration in `Cargo.toml`. The config controls tag selection, commit grouping, filtering, preprocessing, and output templates.

```toml
[changelog]
header = "# Changelog\n\n"
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }}\
{% endfor %}
{% endfor %}
"""

[git]
conventional_commits = true
filter_unconventional = true
tag_pattern = "v[0-9]*"

commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Bug Fixes" },
  { message = "^docs", group = "Documentation" },
]
```

First-run setup is easy if the project already uses Conventional Commits. It becomes more involved, but also more powerful, when the team needs custom categories, monorepo-specific scopes, or strict CI filtering.

Two things the hands-on run surfaced that are worth knowing before you start editing config:

- **The default `--init` config is opinionated.** It is much more elaborate than the minimal example above: emoji group prefixes (`🚀 Features`, `🐛 Bug Fixes`), HTML-comment sort keys (`<!-- 0 -->`), `commit_preprocessors`, security body matchers, and a catch-all `💼 Other` group. It is heavily commented, so it works well as a starting point.
- **`filter_unconventional` defaults to `true`** in the `--init` output, which silently drops non-conventional commits. Set it to `false` if you want commits like `docs: …` to appear (the experiment confirmed they then land under a "Documentation" group).

## Output Quality

Out of the box, `git-cliff` produces readable release-note sections from commit metadata. Here is the *real* output from the hands-on run (replacing the imagined example the original article showed) — the full `CHANGELOG.md` after a three-version life cycle:

```markdown
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
```

(Note the missing blank line between release sections — that is a template-whitespace artifact discussed in the hands-on findings, not a bug.)

The output can be excellent, but the tool cannot turn vague commit messages into good user-facing prose. Its real strength is letting teams encode their release-note structure once and then regenerate consistent output repeatedly.

## Ecosystem Fit

`git-cliff` feels native to Rust because it is available as a Cargo-installed binary, can read `Cargo.toml` configuration, and is widely paired with Rust release tools. It is also intentionally cross-language, which matters for Rust workspaces that include bindings, npm packages, or generated artifacts.

It is the right primitive when the team wants commit-derived changelogs. It is not a fragment workflow like Towncrier or Changesets; the commit history remains the source of truth.

## Maintenance Status

- Latest version: **2.13.1**
- Last release: **2026-04-26**
- GitHub stars: **11,909**
- Appears actively maintained.
- Repository: <a href="https://github.com/orhun/git-cliff" target="_blank" rel="noopener noreferrer">https://github.com/orhun/git-cliff</a>

The official docs are active and cover initialization, configuration, custom templates, custom parsers, GitHub/GitLab metadata, and CI-oriented failure modes.

---

## Hands-on findings

This section is grounded in *running* git-cliff in a container, not reading its docs. The reproducible experiment lives in [`examples/rust/git-cliff/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/git-cliff).

### What we ran

- **Base image:** `debian:bookworm-slim` (runtime); `rust:1.87-slim` (build stage for the tipcalc fixture app)
- **Tool version:** `git-cliff 2.13.1` (pre-built musl binary from GitHub Releases — no `cargo install`)
- **Fixture:** a trivial all-constants "restaurant tip calculator" CLI written in Rust
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog yet.
  2. `git-cliff --config cliff.toml --output CHANGELOG.md` — first changelog generated.
  3. Implement even-split feature; `--unreleased` preview of pending changes.
  4. Tag v2.0.0, regenerate full changelog; repeat for v3.0.0.
  5. Bonus: `git-cliff --latest` for just the last release; `git-cliff --init` to show default config.

All four life-cycle stages completed successfully.

### Real output

The `--unreleased` preview mid-run (before tagging v2.0.0):

```markdown
## [Unreleased]

### Documentation

- Add changelog for 1.0.0

### Features

- Split the bill evenly among diners
```

`--latest`, run after tagging v3.0.0, produced only the most recent release section — handy for pasting into a GitHub Release body. (The full three-version `CHANGELOG.md` is shown in Output Quality above.)

### Pros (observed)

- **Works with zero registry round-trips.** The pre-built musl binary downloaded in seconds and was self-contained — no shared libraries, no runtime Rust toolchain.
- **Tera templates are genuinely powerful.** The experiment's `cliff.toml` uses `group_by(attribute="group")` and `trim_start_matches(pat="v")`; it reads like Jinja2 and works as documented.
- **Incremental commands compose well.** `--unreleased` previews the next release without writing the file, `--latest` isolates the last tag, `--output` writes in place. These cover the major CI use cases without extra tools.
- **`--init` is a useful scaffolding entry point** — verbose but heavily commented.
- **`filter_unconventional = false` works as a safety net** — the `docs:` commit was retained under "Documentation" rather than silently dropped.

### Cons / pain points (observed)

- **Missing blank lines between release sections.** The body template ends without a trailing `\n`, so `## [2.0.0]` and `## [3.0.0]` run together. This is a one-line template fix (careful `\n` handling, or a `postprocessors` regex), not a fundamental problem.
- **A `docs:` maintenance commit leaks into the changelog.** The `docs: add changelog` commit appeared as a real "Documentation" entry. Expected given the config, but it means you must either skip `docs:` commits or be disciplined about what gets committed.
- **`--init` mixes ANSI escape codes into stdout** (`[32;1mINFO[0m`), which looks messy in transcripts; CI would want to strip/redirect stderr.
- **Timestamp precision.** All three releases show the same date because they were created in one container run; the changelog does not distinguish intra-day releases.
- A minor packaging note: list the release tarball before extracting — the binary path is `git-cliff-2.13.1/git-cliff`, not nested under a target-triple directory.

### Docs vs. reality

The original article described the tool accurately: Tera templates, `--unreleased`, `--latest`, `--init`, and Conventional Commits support all work exactly as documented. What it undersold:

1. **Template whitespace discipline** — missing newlines produce cramped output, which the hands-on run made immediately visible.
2. **The default config is opinionated about emoji and sort keys** — useful to know before editing.

## Verdict

**Verdict: Recommended — the default Rust-era changelog generator to evaluate first.**

git-cliff is the most capable and most actively maintained Rust changelog generator. The pre-built binary means zero Rust toolchain dependency at runtime, and the Tera template engine is expressive enough to cover every format we tested elsewhere (Keep a Changelog, plain markdown, release-notes-only). The hands-on run reproduced this cleanly; the only real gotcha is the blank-line-between-sections whitespace issue, which is a one-line template fix.

Use it directly when commits are the source of truth, and pair it with `release-plz`, `cargo-release`, or `cargo-dist` when changelog generation is only one step in a larger release pipeline. Pin a specific version in CI to get reproducible output.
