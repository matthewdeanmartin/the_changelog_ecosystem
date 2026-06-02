Title: release-it (hands-on synthesis)
Date: 2026-06-02
Slug: release-it-v2
Ecosystem: node
Tags: release-automation, conventional-commits, node, cli, changelog-file, hands-on
Tool_URL: https://www.npmjs.com/package/release-it
Tool_Version: 17.10.0
Tool_Status: active
Experiment: examples/node/release-it/
Summary: Hands-on re-review after driving release-it through the tip-calculator life cycle.



## What I actually ran

This is a second-pass review grounded in running release-it, not reading its docs. The reproducible
experiment lives in [`examples/node/release-it/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/node/release-it).

- **Base image:** `node:20-slim`
- **Tool version:** `release-it 17.10.0` (installed globally via `npm install -g`)
- **Plugin:** `@release-it/conventional-changelog 8.0.2` (also installed globally)
- **Fixture:** a trivial Node.js restaurant tip calculator CLI
- **Config:** `.release-it.json` with `"push": false`, `"publish": false`, `"github.release": false`, conventional-changelog plugin set to angular preset
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog yet.
  2. `release-it --ci --dry-run` — preview of what the first release would do.
  3. Implement even-split feature; `release-it --ci` — actual release (became 1.1.0).
  4. Implement uneven-split with a breaking change commit; `release-it --ci` — next release.

One fix was required before the experiment ran: the default git config requires an upstream branch
even when `"push": false` is set. Adding `"requireUpstream": false` and `"requireBranch": false` to
the `git` block in `.release-it.json` resolved the failure.

## Real output

CHANGELOG.md after the full two-release run:

```markdown


## [1.1.1](https://github.com/example/tipcalc/compare/v1.1.0...v1.1.1) (2026-06-02)

# [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([cdeadb6](https://github.com/example/tipcalc/commit/cdeadb6670d63df79ae0fe7b9ff3c3b8eb51f7c8))
```

Notable problems visible in this output:

- The 1.1.1 entry (the breaking-change release) has no content — no features, no `BREAKING CHANGES` section.
- The two release headings use inconsistent Markdown levels (`#` for 1.1.0, `##` for 1.1.1).
- No entry exists for v1.0.0 (the initial tagged commit, created before release-it was involved).

The dry-run preview from stage 2 (before any feature commits were added):

```
🚀 Let's release tipcalc (1.0.0...1.0.1)
Changelog:
## [1.0.1](https://github.com/example/tipcalc/compare/v1.0.0...v1.0.1) (2026-06-02)
! npm version 1.0.1 --no-git-tag-version
$ Writing changelog to CHANGELOG.md
$ git status --short --untracked-files=no
Empty changeset
! git add . --update
! git commit --message chore(release): 1.0.1
! git tag --annotate --message Release 1.0.1 v1.0.1
🏁 Done (in 0s.)
```

The `!` prefix marks steps that would execute; `$` marks steps already completed. This is a useful
audit trail, but it is mixed into stdout alongside the changelog preview.

## Pros (observed)

**The dry-run is genuinely useful.** `--dry-run` shows each planned git step and the full changelog
preview before touching anything. The distinction between `$` (already done) and `!` (would run)
gives a clear picture of what will change before committing.

**Changeset diff before commit.** The real run printed `A  CHANGELOG.md` and `M package.json`
before committing — a quick sanity check that exactly the right files are staged.

**`feat:` -> minor bump works correctly.** The conventional-changelog plugin correctly detected the
`feat: split the bill evenly among diners` commit and bumped 1.0.0 -> 1.1.0.

**Incremental CHANGELOG accumulation works.** The second release prepended a new entry at the top
while preserving the prior entry below it. No duplication occurred.

**Fast.** Each release run completed in under one second, including git operations.

**Config is compact.** A single `.release-it.json` covering git, npm, GitHub, and the plugin fits
in about 20 lines. No separate workflow file or config language is needed.

## Cons / pain points (observed)

**Upstream check fires even with `"push": false`.** The most jarring first-run failure: the tool
aborts with "No upstream configured for current branch" before it even checks whether a push would
actually occur. The fix (`requireUpstream: false` and `requireBranch: false`) is not in the
getting-started docs. It required reading GitHub issue threads.

**`feat!` breaking change ignored for version bumping.** This is the most significant finding. The
commit `feat!: split the bill unevenly by weight` should trigger a major bump (1.1.0 -> 2.0.0)
under the Conventional Commits spec. Instead, release-it with the angular preset bumped patch:
1.1.0 -> 1.1.1. The `!` shorthand in the subject line is not handled; only `BREAKING CHANGE:` in
the commit body footer is reliably recognized by the angular preset.

**Empty CHANGELOG entry for the breaking change.** The 1.1.1 section has only a heading and date —
no content. A CHANGELOG entry with a version heading and nothing else is worse than no entry; it
implies nothing changed.

**Inconsistent heading levels across releases.** The first release used `#` (h1) and the second
used `##` (h2). This appears to depend on whether the entry is the first or a subsequent one in the
file. The result fails standard Markdown linters and looks inconsistent to readers.

**No v1.0.0 entry in the changelog.** release-it does not backfill history for tags it did not
create. Any commits before the first release-it invocation are invisible in the changelog.

**Dry-run version does not predict actual release version.** The stage-2 dry-run proposed 1.0.1 (a
patch bump from the only commit at that point). The actual first release in stage 4a produced 1.1.0
because a `feat:` commit had been added by then. This is technically correct but can mislead
developers who run a dry-run early and expect the same version in the real run.

## Docs vs. reality

The original `release-it.md` described the tool accurately at a high level: plugins, CI mode,
interactive mode, version bumping, and changelog generation are all real capabilities.

Three gaps between the docs review and the hands-on run:

1. **The upstream check is unmentioned.** The original article says release-it runs
"non-interactively in CI." It does not mention that `--ci` fails without a configured upstream
branch even when push is disabled. This is a significant first-run friction point.

2. **`feat!` semver compliance was assumed, not tested.** The original article describes release-it
as capable of computing the next version from commits. The hands-on run showed that the angular
preset silently mis-classifies `feat!` as a patch. This is a material correctness issue for projects
using the shorthand breaking-change notation.

3. **Changelog heading level inconsistency was not visible from docs.** The original article showed
clean output. The actual tool produces inconsistent h1/h2 heading levels that fail linting.

## Revised verdict

**Downgrade from Recommended to Conditional.**

release-it is a reasonable choice for teams that want a human-invoked release command with a
dry-run preview. The interactive workflow remains its strongest differentiator: you see the planned
version and changelog before confirming.

However, the `feat!` -> major bump failure is a hard limitation. Any project relying on the
exclamation-mark breaking-change syntax will silently produce incorrect version numbers and empty
changelog entries. Until this is fixed — or the team switches to `BREAKING CHANGE:` footer trailers
in commit bodies — release-it cannot be recommended for projects that depend on automated semver
correctness.

**When to use it:** Node libraries where a human runs the release locally and can verify the
proposed version; teams that use `BREAKING CHANGE:` footer trailers rather than `!`; projects that
want the dry-run preview as a release gate.

**When to avoid it:** Fully automated CI pipelines where no human reviews the proposed version;
projects using `feat!` shorthand and expecting correct major bumps; monorepos (use Changesets
instead); projects requiring a clean, validated CHANGELOG format.
