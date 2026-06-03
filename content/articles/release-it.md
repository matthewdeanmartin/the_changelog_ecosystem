Title: release-it
Date: 2026-06-02
Slug: release-it
Ecosystem: Node
Tags: extensible, github-integration, gitlab-integration, node, npm-cli, package-publishing, semantic-versioning, changelog-preview, interactive, release-automation, conventional-commits, changelog-file, hands-on
Tool_URL: https://www.npmjs.com/package/release-it
Tool_Version: 17.10.0
Tool_Status: active
Experiment: examples/node/release-it/
Summary: Human-invoked release command with dry-run previews and a plugin system; hands-on testing found a strong interactive workflow but a config-fix first-run hurdle and a silent feat!-to-major-bump failure with the conventional-changelog plugin.



A reproducible hands-on experiment for this tool lives in [`examples/node/release-it/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/node/release-it).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), release-it would not run until we disabled an upstream-branch check that fires even when push is disabled, and — more seriously — the conventional-changelog (angular preset) plugin silently mis-classified a <code>feat!:</code> breaking-change commit as a <em>patch</em> bump (1.1.0 → 1.1.1) instead of a major, writing an empty changelog entry. The tool is far from unusable, but projects relying on automated semver correctness or the <code>!</code> breaking-change shorthand should use <code>BREAKING CHANGE:</code> footer trailers or verify each bump. See the hands-on findings below.
</div>

## Overview

`release-it` is an explicit release command for projects that want automation without handing the entire release decision to CI. It can run interactively for local releases or non-interactively in CI, bump versions, create tags, generate changelog previews, publish packages, and create GitHub/GitLab releases.

It sits between semantic-release and manual scripts: more guided and plugin-friendly than a custom npm script, but less dogmatic than fully automated commit-driven publishing.

## Installation

```bash
npm install --save-dev release-it
```

## What It Does

- Prompts for or computes the next version.
- Runs git checks, commits, tags, and pushes release changes.
- Generates a changelog preview from commits or plugins.
- Publishes to npm and creates GitHub or GitLab releases.
- Supports plugins for Conventional Commits, workspaces, containers, Slack, and custom release steps.

## Configuration

Configuration can live in `.release-it.json`, `.release-it.js`, or `package.json`. A compact setup might look like:

```json
{
  "git": {
    "commitMessage": "chore: release v${version}",
    "tagName": "v${version}",
    "requireUpstream": false,
    "requireBranch": false
  },
  "github": {
    "release": true
  },
  "npm": {
    "publish": true
  },
  "plugins": {
    "@release-it/conventional-changelog": {
      "preset": "conventionalcommits"
    }
  }
}
```

The `requireUpstream: false` / `requireBranch: false` entries are not in the getting-started docs but were required in the hands-on run — without them the tool aborts on a missing upstream branch even with `"push": false`. First-run setup is otherwise moderate: decide what should be local, what should run in CI, and which plugins own changelog text.

## Output Quality

With the conventional-changelog plugin, release notes follow the familiar Features / Bug Fixes grouping with auto-linked commit SHAs. The hands-on run, however, surfaced inconsistent heading levels (h1 vs h2 across releases) and an empty entry for a breaking-change commit — see the hands-on section below for the real output rather than an idealized example.

## Ecosystem Fit

`release-it` fits Node projects that want a human-invoked release command, especially libraries and apps where a maintainer still wants to approve the version. Its plugin system makes it adaptable beyond npm.

For fully automated CI releases, semantic-release is cleaner. For monorepo package intent, Changesets is usually better.

## Maintenance Status

- Latest version tested: **17.10.0** (newer 20.x releases exist; the experiment pinned 17.10.0)
- Appears actively maintained.
- Repository: <a href="https://github.com/release-it/release-it" target="_blank" rel="noopener noreferrer">https://github.com/release-it/release-it</a>

The project is actively maintained with current docs for config files, interactive mode, CI mode, plugins, npm, GitHub, and GitLab releases.

---

## Hands-On Findings

This section is grounded in actually running release-it, not reading its docs.

### What I actually ran

- **Base image:** `node:20-slim`
- **Tool version:** `release-it 17.10.0` (installed globally)
- **Plugin:** `@release-it/conventional-changelog 8.0.2` (also global), angular preset
- **Fixture:** a trivial Node.js restaurant tip calculator CLI
- **Config:** `.release-it.json` with `"push": false`, `"publish": false`, `"github.release": false`
- **Life cycle, in an isolated in-container git repo:**
  1. v1.0.0 code committed and tagged — no changelog yet.
  2. `release-it --ci --dry-run` — preview of the first release.
  3. Implement even-split feature; `release-it --ci` — actual release (became 1.1.0).
  4. Implement uneven-split with a breaking-change commit; `release-it --ci` — next release.

One fix was required before the experiment ran at all: the default git config requires an upstream branch even with `"push": false`. Adding `"requireUpstream": false` and `"requireBranch": false` to the `git` block resolved it. That workaround is not in the getting-started docs — it came from GitHub issue threads.

### Real output

CHANGELOG.md after the full two-release run:

```markdown


## [1.1.1](https://github.com/example/tipcalc/compare/v1.1.0...v1.1.1) (2026-06-02)

# [1.1.0](https://github.com/example/tipcalc/compare/v1.0.0...v1.1.0) (2026-06-02)


### Features

* split the bill evenly among diners ([cdeadb6](https://github.com/example/tipcalc/commit/cdeadb6670d63df79ae0fe7b9ff3c3b8eb51f7c8))
```

Notable problems visible here:

- The 1.1.1 entry (the breaking-change release) has no content — no features, no `BREAKING CHANGES` section.
- The two release headings use inconsistent Markdown levels (`#` for 1.1.0, `##` for 1.1.1).
- No entry exists for v1.0.0 (the initial tagged commit, created before release-it was involved).

The dry-run preview from stage 2 (before any feature commits):

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

The `!` prefix marks steps that would execute; `$` marks steps already completed — a useful audit trail, though it is mixed into stdout alongside the changelog preview.

### Pros (observed)

**The dry-run is genuinely useful.** It shows each planned git step and the full changelog preview before touching anything; the `$`/`!` distinction gives a clear picture of what will change.

**Changeset diff before commit.** The real run printed `A  CHANGELOG.md` and `M package.json` before committing — a quick sanity check that the right files are staged.

**`feat:` → minor bump works correctly.** The plugin detected `feat: split the bill evenly among diners` and bumped 1.0.0 → 1.1.0.

**Incremental CHANGELOG accumulation works.** The second release prepended a new entry while preserving the prior one. No duplication.

**Fast.** Each release run completed in under a second, git operations included.

**Config is compact.** A single `.release-it.json` covering git, npm, GitHub, and the plugin fits in about 20 lines.

### Cons / pain points (observed)

**Upstream check fires even with `"push": false`.** The most jarring first-run failure: the tool aborts with "No upstream configured for current branch" before checking whether a push would even occur. The fix (`requireUpstream: false`, `requireBranch: false`) is undocumented in the getting-started flow.

**`feat!` breaking change ignored for version bumping.** The most significant finding. `feat!: split the bill unevenly by weight` should trigger a major bump (1.1.0 → 2.0.0). Instead release-it with the angular preset bumped patch: 1.1.0 → 1.1.1. The `!` subject-line shorthand is not handled; only a `BREAKING CHANGE:` footer in the commit body is reliably recognized by the angular preset.

**Empty CHANGELOG entry for the breaking change.** The 1.1.1 section has only a heading and date — worse than no entry, since it implies nothing changed.

**Inconsistent heading levels across releases** (`#` for the first, `##` for subsequent), which fails standard Markdown linters.

**No v1.0.0 entry in the changelog.** release-it does not backfill history for tags it did not create.

**Dry-run version does not predict the actual release version.** The stage-2 dry-run proposed 1.0.1; the actual first release produced 1.1.0 because a `feat:` commit had been added by then. Technically correct, but can mislead developers who run a dry-run early.

**Fetches from the remote even with `push: false`** — the dry-run shows a `! git fetch` step. In an air-gapped or remoteless repo this warns but does not block.

### Docs vs. reality

The v1 article described the tool accurately at a high level — plugins, CI mode, interactive mode, version bumping, changelog generation are all real. Three gaps surfaced hands-on:

1. **The upstream check is unmentioned.** `--ci` fails without a configured upstream even when push is disabled — a significant first-run friction point.
2. **`feat!` semver compliance was assumed, not tested.** The angular preset silently mis-classifies `feat!` as a patch — a material correctness issue for projects using the shorthand.
3. **Changelog heading-level inconsistency was not visible from docs.** The actual tool produces inconsistent h1/h2 headings that fail linting.

## Verdict

**Verdict: Conditional (downgraded from Recommended)**

release-it is a reasonable choice for teams wanting a human-invoked release command with a dry-run preview. The interactive workflow remains its strongest differentiator: you see the proposed version and changelog before confirming.

However, the `feat!` → major bump failure is a hard limitation. Any project relying on the exclamation-mark breaking-change syntax will silently produce incorrect version numbers and empty changelog entries. Until that is fixed — or the team switches to `BREAKING CHANGE:` footer trailers in commit bodies — release-it cannot be recommended for projects depending on automated semver correctness.

**When to use it:** Node libraries where a human runs the release locally and verifies the proposed version; teams that use `BREAKING CHANGE:` footer trailers rather than `!`; projects that want the dry-run preview as a release gate.

**When to avoid it:** fully automated CI pipelines with no human review; projects using `feat!` shorthand and expecting correct major bumps; monorepos (use Changesets); projects requiring a clean, validated CHANGELOG format.
