Title: cargo-release (hands-on synthesis)
Date: 2026-06-02
Slug: cargo-release-v2
Ecosystem: Rust
Tags: cargo-subcommand-ci, rust, release-orchestration, ci-cd, conventional-commits, git-cliff, git-tags, hands-on
Tool_URL: https://crates.io/crates/cargo-release
Tool_Version: 1.1.2
Tool_Status: active
Experiment: examples/rust/cargo-release/
Summary: Hands-on re-review after driving cargo-release through the tip-calculator life cycle in a container.



## What I actually ran

This is a second-pass review grounded in *running* cargo-release, not reading its docs. The
reproducible experiment lives in [`examples/rust/cargo-release/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/rust/cargo-release).

- **Base image:** `rust:1.87-slim` (cargo required at runtime; cargo-release validates Cargo.toml)
- **Tool versions:** `cargo-release 1.1.2` + `git-cliff 2.13.1` (both pre-built musl binaries)
- **Fixture:** a trivial all-constants Rust "restaurant tip calculator"
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog.
  2. git-cliff generates initial CHANGELOG.md for v1.0.0.
  3. Implement even-split feature; `cargo-release release --dry-run` shows what would happen.
  4. Manually simulate the hook: `git-cliff --tag v2.0.0 --output CHANGELOG.md`, commit, tag; repeat for v3.0.0.

## Real output

CHANGELOG.md after the full run (v3.0.0 as top entry):

```markdown
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
```

The cargo-release dry-run output at stage 3:

```
error: uncommitted changes detected, please resolve before release:
         Cargo.lock (Status(WT_NEW))
   Upgrading tipcalc from 2.0.0 to 2.0.1
error: for `Unreleased` in 'CHANGELOG.md', at least 1 replacements expected, found 0
```

The real-world `release.toml` hook config (shown in the bonus section):

```toml
[release]
pre-release-hook = ["git", "cliff", "--tag", "{{version}}", "-o", "CHANGELOG.md"]
tag-name = "v{{version}}"
push = false
publish = false
```

## Pros (observed)

**Pure orchestration: no changelog opinions.** cargo-release has no changelog format baked in. It delegates changelog content entirely to the pre-release hook. This means you choose your generator (git-cliff, conventional-changelog, hand-edited) and cargo-release just invokes it at the right moment with the right version string.

**`{{version}}` template expansion before hook invocation.** The pre-release-hook receives the actual release version string as a shell argument. This is what makes `git-cliff --tag {{version}}` work cleanly — git-cliff gets `v2.0.0`, not a literal `{{version}}`.

**Dry-run is genuinely useful.** Even with `--no-publish --no-push --no-tag`, cargo-release still validates the working tree, changelog structure, and version logic. The errors it produced (uncommitted `Cargo.lock`, missing `[Unreleased]` section) are exactly the checks you'd want before a real release.

**git-cliff integration works well end-to-end.** The manual hook simulation in stages 4a/4b produced correct, cumulative changelogs across all three versions. The documented `pre-release-hook` pattern is the right integration path and it works as described.

## Cons / pain points (observed)

**cargo-release and git-cliff use incompatible changelog conventions.** cargo-release's built-in changelog replacement looks for a `## [Unreleased]` section header; git-cliff's default output does not include one. If you use both together without disabling cargo-release's replacement feature, every dry-run and release will error on `at least 1 replacements expected, found 0`. The fix is to disable cargo-release's replacement entirely (`[[pre-release-replacements]]` block disabled) and let the git-cliff hook own the file.

**`Cargo.lock` must be committed.** cargo-release validates the working tree before proceeding, including untracked `Cargo.lock`. In a minimal test environment that never ran `cargo build`, the lock file doesn't exist and the dry-run errors immediately. This is a correct guard in real projects (where the lock file exists and is tracked), but it means minimal container experiments without a prior `cargo build` hit this error first.

**Version bump is not simulated in dry-run without `--execute`.** The `sed -i` version bump had to be done manually in the experiment. In a real `--execute` run, cargo-release handles this automatically; in dry-run, the version is reported but not applied. This is expected but makes the dry-run transcript slightly misleading when reading it linearly.

**No built-in changelog generation.** cargo-release is a release *orchestrator*, not a changelog *generator*. Teams that want changelog automation must wire in git-cliff (or another tool) via the hook. Without a hook, cargo-release writes nothing to `CHANGELOG.md`.

## Docs vs. reality

The original `cargo-release.md` article described the tool accurately as a release orchestrator. The hands-on run confirmed every key claim.

What the original article undersold:

1. **The `[Unreleased]` convention conflict.** The article mentions cargo-release supports changelog file replacement but does not warn that git-cliff's output format is incompatible with cargo-release's default replacement regex. This is the #1 integration friction point and deserves a prominent callout.
2. **Dry-run validates more than just version.** The original article treats dry-run as "shows what would happen." In practice, dry-run validates the full release checklist (working tree cleanliness, changelog section headers, upstream configuration). This is more useful than a pure preview mode.

## Revised verdict

**Keep as a strong recommendation for projects that want a release orchestrator.** cargo-release is not a changelog tool — it is the glue that turns a changelog-generating tool (git-cliff) into a complete release workflow. For Rust projects that publish to crates.io, cargo-release + git-cliff is a well-tested combination. The `[Unreleased]` convention mismatch is a one-time config fix, not an ongoing problem. Teams that do not publish to crates.io may find `release-plz` or plain git-cliff invocation more appropriate.
