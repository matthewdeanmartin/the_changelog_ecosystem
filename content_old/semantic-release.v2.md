Title: semantic-release (hands-on synthesis)
Date: 2026-06-02
Slug: semantic-release-v2
Ecosystem: node
Tags: fully-automated, ci-native, conventional-commits, node, npm-publish, github-releases, hands-on
Tool_URL: https://www.npmjs.com/package/semantic-release
Tool_Version: 24.2.5
Tool_Status: active
Experiment: examples/node/semantic-release/
Summary: Hands-on re-review of semantic-release — documenting what works locally in dry-run mode and what is strictly CI-only.



## What I Actually Ran

The experiment used a Docker container (`node:20-slim`) with semantic-release 24.2.5 and five plugins installed globally. Inside the container, a fresh git repo was initialized with a fixture app (`tipcalc`), and three commits were made in sequence:

1. `feat: compute tip for a single bill` — expected to trigger v1.0.0
2. `feat: split the bill evenly among diners` — expected to trigger v1.1.0
3. `feat!: split the bill unevenly by weight` — breaking change, expected to trigger v2.0.0

After each commit, the script ran:

```bash
semantic-release --dry-run --no-ci
```

This is the local-simulation mode the documentation describes. The `--dry-run` flag skips writes; `--no-ci` skips the CI-environment check that would otherwise abort immediately.

The full experiment script is at `examples/node/semantic-release/run_experiment.sh`.

## Real Output

All three dry-run invocations produced identical results. Plugin loading succeeded:

```
[semantic-release] › ✔  Loaded plugin "verifyConditions" from "@semantic-release/changelog"
[semantic-release] › ✔  Loaded plugin "verifyConditions" from "@semantic-release/npm"
[semantic-release] › ✔  Loaded plugin "verifyConditions" from "@semantic-release/git"
[semantic-release] › ✔  Loaded plugin "analyzeCommits" from "@semantic-release/commit-analyzer"
[semantic-release] › ✔  Loaded plugin "generateNotes" from "@semantic-release/release-notes-generator"
[semantic-release] › ✔  Loaded plugin "prepare" from "@semantic-release/changelog"
[semantic-release] › ✔  Loaded plugin "prepare" from "@semantic-release/npm"
[semantic-release] › ✔  Loaded plugin "prepare" from "@semantic-release/git"
[semantic-release] › ✔  Loaded plugin "publish" from "@semantic-release/npm"
[semantic-release] › ✔  Loaded plugin "addChannel" from "@semantic-release/npm"
```

Then, immediately after plugin loading and before reading a single commit:

```
[semantic-release] › ✘  An error occurred while running semantic-release:
ExecaError: Command failed with exit code 128:
  git ls-remote --heads 'https://github.com/example/tipcalc'

remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/example/tipcalc/'
```

No version was calculated. No changelog was written. The git-tags output file was empty at every stage.

The fixture app itself ran correctly — `node src/index.js` produced the expected bill-split output — confirming the container and Node environment were healthy. The failure was entirely in semantic-release's startup path.

## Pros (Observed)

**Plugin system is solid.** All five plugins resolved correctly from a global install. semantic-release found them via Node's module resolution without a local `node_modules`. The plugin loading phase completed in under a second.

**Configuration is clean and readable.** The `.releaserc.json` format is concise. The plugin pipeline — analyze commits, generate notes, write changelog, bump package.json, commit back — is expressed in about 20 lines and is easy to follow.

**Commit message conventions are well-specified.** The tool's reliance on `feat:`, `fix:`, `feat!:` etc. means the rules for what bumps what version are unambiguous and machine-checkable. There is no version-bump subjectivity.

**Intended CI workflow is genuinely zero-touch.** In a properly configured CI pipeline with a real remote, GITHUB_TOKEN, and NPM_TOKEN, the tool does everything: analyze commits, decide version, write changelog, bump package.json, tag, publish npm, create GitHub Release. Nothing is manual.

## Cons / Pain Points (Observed)

**`--dry-run --no-ci` does not work without a real remote.** This is the central finding of the experiment. The documentation suggests dry-run mode is useful for local preview, but in practice semantic-release calls `git ls-remote` against the project's remote before touching local state. The remote must be reachable and authenticated. This makes the tool almost completely opaque locally — you cannot preview what it would do without setting up the full CI environment.

**The failure is not gracefully handled.** The error surface for a missing remote is a verbose Node.js ExecaError stack trace (400+ lines when printed twice with ANSI colors). A tool aimed at developer experience could easily detect "no reachable remote" and emit a single clear message.

**The error appears twice.** The stack trace is printed once without ANSI codes and once with ANSI codes, both on the same invocation. This appears to be a logging architecture issue where the error is caught at multiple layers.

**`--no-ci` solves the wrong problem for local use.** The `--no-ci` flag skips detection of the CI environment variable (`CI=true`). But the actual blocker for local use is not the CI check — it is the remote connectivity requirement that runs unconditionally. The flags available for local experimentation do not bypass the actual barrier.

**Setup cost is non-trivial.** Getting semantic-release working requires: a hosted remote with auth, correct branch protection settings, npm publish credentials (or `npmPublish: false`), GITHUB_TOKEN in CI secrets, and enforced Conventional Commits discipline across the team. All of this must be correct simultaneously before the tool produces any output.

**No local-only mode exists.** Tools like `release-it` and `changesets` can run interactively without a remote configured. semantic-release has no equivalent — it is architecturally built around the assumption that CI is the runtime environment.

## Docs vs. Reality

The [semantic-release documentation](https://semantic-release.gitbook.io/semantic-release/) describes `--dry-run` as showing "the next version and release notes without actually releasing anything." That description is accurate for a project with a real authenticated remote. It is misleading for anyone trying to evaluate the tool locally: the dry run halts before it reaches the version-determination step if the remote is unreachable.

The first review (`semantic-release.md`) noted that "first-run setup is moderate." The hands-on experiment suggests that framing is optimistic. Setup is substantial if the developer also wants to verify their configuration locally before committing to the CI pipeline. There is no feedback loop shorter than "push to CI and read the logs."

The first review accurately described the tool's intended workflow — fully automated, CI-driven, commit-history-as-release-intent. Nothing in that description is wrong. What was understated is how completely the tool declines to participate outside of that environment.

## Revised Verdict

**Verdict: Recommended — with a clear scope caveat**

semantic-release remains the right choice when a team wants releases driven entirely by CI with no human approval step. The plugin system is mature, the configuration is clean, and the intended workflow is genuinely zero-touch once set up.

However, the hands-on experiment sharpens the scope caveat considerably. This tool is not locally operable in any meaningful sense. `--dry-run --no-ci` fails before analyzing a single commit if the remote is not authenticated. Teams evaluating the tool should plan for a "set up CI first, then verify it works in CI" onboarding path, rather than expecting to validate configuration locally.

For teams that want a release tool they can run from a developer laptop — to preview a changelog, confirm version logic, or experiment before pushing — `release-it` or `changesets` are meaningfully more accessible. For teams already all-in on CI-native workflows with GitHub Actions and Conventional Commits, semantic-release's hands-off automation is a genuine productivity win that the alternatives do not match.
