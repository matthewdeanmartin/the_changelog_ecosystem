Title: semantic-release
Date: 2026-06-02
Slug: semantic-release
Ecosystem: Node
Tags: conventional-commits, extensible, github-integration, gitlab-integration, node, npm-cli-ci, package-publishing, release-notes, semantic-versioning, ci-cd, fully-automated, ci-native, npm-publish, github-releases, hands-on
Tool_URL: https://www.npmjs.com/package/semantic-release
Tool_Version: 24.2.5
Tool_Status: active
Experiment: examples/node/semantic-release/
Summary: Fully automated, CI-native release workflow for Conventional Commits projects; hands-on testing confirmed clean plugin loading but found that even --dry-run --no-ci requires an authenticated remote and cannot be exercised locally.



A reproducible hands-on experiment for this tool lives in [`examples/node/semantic-release/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/node/semantic-release).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), we could not drive semantic-release through the release life cycle offline. Even <code>--dry-run --no-ci</code> calls <code>git ls-remote</code> against the project's remote before analyzing a single commit and aborts on an authentication/connectivity failure — no version, no changelog, no preview. This is not a bug so much as the tool's CI-native design: it works as intended in a properly configured CI pipeline with a reachable, authenticated remote, but it is effectively not locally operable. Plan for a "set up CI first, then verify in CI" onboarding path. See the hands-on findings below.
</div>

## Overview

`semantic-release` is the fully automated release workflow for Conventional Commits projects. In CI, it analyzes commits, decides the next semantic version, generates release notes, publishes packages, tags releases, and updates GitHub or GitLab releases through plugins.

Its defining tradeoff is trust in automation: maintainers do not run an interactive release command or manually pick the version. The commit history is the release intent.

## Installation

```bash
npm install --save-dev semantic-release
```

## What It Does

- Determines the next version from commit types and breaking-change footers.
- Generates release notes using conventional-changelog behavior.
- Publishes npm packages and can publish to many other registries through plugins.
- Creates GitHub, GitLab, or other hosted releases.
- Supports plugin steps for verify conditions, analyze commits, generate notes, prepare, publish, success, and fail.

## Configuration

Configuration can live in `release.config.js`, `.releaserc`, or `package.json`. A minimal npm/GitHub setup is small:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/npm",
    "@semantic-release/github"
  ]
}
```

First-run setup is substantial in practice (the v1 review called it "moderate" — the hands-on run suggests that is optimistic): CI tokens, branch protection, npm publishing, a reachable authenticated remote, and commit discipline all need to be correct simultaneously before the tool produces any output. Once configured, the workflow is intentionally hands-off.

## Output Quality

Release notes are commit-derived, grouped into Features / Bug Fixes / Breaking Changes. They are consistent and automated, but only read well if the project treats commit messages as public release-note material. (The experiment could not reach the note-generation step locally — see below.)

## Ecosystem Fit

Semantic-release is extremely native to Node CI workflows and npm publishing. It also has enough plugins to reach other ecosystems, but Node remains its center of gravity.

It is less appropriate for teams that want a manual approval step, curated release PRs, or intentional change files. Changesets and release-it are better fits for those styles — and, as the experiment showed, are meaningfully more accessible from a developer laptop.

## Maintenance Status

- Latest version tested: **24.2.5** (25.x exists; the experiment pinned 24.2.5)
- Appears actively maintained.
- Repository: <a href="https://github.com/semantic-release/semantic-release" target="_blank" rel="noopener noreferrer">https://github.com/semantic-release/semantic-release</a>

The project remains one of the central Node release automation tools, with current documentation for plugins, branches, prereleases, and CI setup.

---

## Hands-On Findings

This section is grounded in actually running semantic-release, not reading its docs.

### What I actually ran

The experiment used a `node:20-slim` Docker container with semantic-release 24.2.5 and five plugins installed globally. A fresh git repo was initialized with a fixture app (`tipcalc`), and three commits were made in sequence:

1. `feat: compute tip for a single bill` — expected to trigger v1.0.0
2. `feat: split the bill evenly among diners` — expected to trigger v1.1.0
3. `feat!: split the bill unevenly by weight` — breaking change, expected to trigger v2.0.0

After each commit the script ran `semantic-release --dry-run --no-ci` — the local-simulation mode the docs describe. `--dry-run` skips writes; `--no-ci` skips the CI-environment check that would otherwise abort immediately.

### Real output

All three dry-run invocations produced identical results. Plugin loading succeeded:

```
[semantic-release] › ✔  Loaded plugin "verifyConditions" from "@semantic-release/changelog"
[semantic-release] › ✔  Loaded plugin "analyzeCommits" from "@semantic-release/commit-analyzer"
[semantic-release] › ✔  Loaded plugin "generateNotes" from "@semantic-release/release-notes-generator"
[semantic-release] › ✔  Loaded plugin "prepare" from "@semantic-release/npm"
[semantic-release] › ✔  Loaded plugin "publish" from "@semantic-release/npm"
```

Then, immediately after plugin loading and before reading a single commit:

```
[semantic-release] › ✘  An error occurred while running semantic-release:
ExecaError: Command failed with exit code 128:
  git ls-remote --heads 'https://github.com/example/tipcalc'

remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/example/tipcalc/'
```

No version was calculated. No changelog was written. The git-tags output file was empty at every stage. The fixture app itself ran correctly (`node src/index.js` produced the expected output), confirming the container and Node environment were healthy — the failure was entirely in semantic-release's startup path.

### Pros (observed)

**Plugin system is solid.** All five plugins resolved correctly from a global install via Node's module resolution, with no local `node_modules`. Loading completed in under a second.

**Configuration is clean and readable.** The `.releaserc.json` format is concise; the analyze → notes → changelog → bump → commit pipeline is about 20 lines and easy to follow.

**Commit conventions are well-specified.** Reliance on `feat:`/`fix:`/`feat!:` makes the bump rules unambiguous and machine-checkable — no version-bump subjectivity.

**Intended CI workflow is genuinely zero-touch.** In a properly configured CI pipeline with a real remote, `GITHUB_TOKEN`, and `NPM_TOKEN`, the tool does everything: analyze, version, changelog, bump, tag, publish, GitHub Release. Nothing is manual.

### Cons / pain points (observed)

**`--dry-run --no-ci` does not work without a real remote.** The central finding. The docs suggest dry-run is useful for local preview, but semantic-release calls `git ls-remote` against the project's remote before touching local state. The remote must be reachable and authenticated. The tool is almost completely opaque locally — you cannot preview what it would do without the full CI environment.

**The failure is not gracefully handled.** A missing remote surfaces as a verbose Node ExecaError stack trace rather than a single clear "no reachable remote" message.

**The error appears twice** — once without and once with ANSI codes — suggesting the error is caught at multiple layers.

**`--no-ci` solves the wrong problem for local use.** It skips the `CI=true` check, but the actual blocker is the unconditional remote-connectivity requirement. The flags available for local experimentation do not bypass the real barrier.

**Setup cost is non-trivial.** A hosted authenticated remote, correct branch protection, npm credentials (or `npmPublish: false`), `GITHUB_TOKEN`, and enforced Conventional Commits — all must be correct at once before any output appears.

**No local-only mode exists.** `release-it` and `changesets` can run without a remote; semantic-release is architecturally built around CI as the runtime environment.

### Docs vs. reality

The documentation describes `--dry-run` as showing "the next version and release notes without actually releasing anything." That is accurate for a project with a real authenticated remote, but misleading for anyone evaluating the tool locally — the dry run halts before version determination if the remote is unreachable.

The v1 review called first-run setup "moderate"; the experiment suggests that is optimistic. There is no feedback loop shorter than "push to CI and read the logs." The v1 review's description of the intended workflow — fully automated, CI-driven, commit-history-as-intent — is otherwise accurate. What it understated is how completely the tool declines to participate outside that environment.

## Verdict

**Verdict: Recommended — with a sharp scope caveat**

semantic-release remains the right choice when a team wants releases driven entirely by CI with no human approval step. The plugin system is mature, the configuration is clean, and the intended workflow is genuinely zero-touch once set up.

The hands-on experiment sharpens the scope caveat considerably: this tool is not locally operable in any meaningful sense. `--dry-run --no-ci` fails before analyzing a single commit if the remote is not authenticated. Teams evaluating it should plan for a "set up CI first, then verify in CI" onboarding path rather than expecting to validate configuration locally.

For teams that want a release tool they can run from a developer laptop — to preview a changelog, confirm version logic, or experiment before pushing — `release-it` or `changesets` are meaningfully more accessible. For teams already all-in on CI-native workflows with GitHub Actions and Conventional Commits, semantic-release's hands-off automation is a genuine productivity win the alternatives do not match.
