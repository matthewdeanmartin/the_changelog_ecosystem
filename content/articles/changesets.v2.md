Title: Changesets (hands-on synthesis)
Date: 2026-06-02
Slug: changesets-v2
Ecosystem: node
Tags: file-based, monorepo, node, npm-publish, changelog-file, hands-on
Tool_URL: https://www.npmjs.com/package/@changesets/cli
Tool_Version: 2.27.12
Tool_Status: active
Experiment: examples/node/changesets/
Summary: Hands-on re-review after driving Changesets through the tip-calculator life cycle — testing the file-based intent workflow.



## What I Actually Ran

The experiment ran `@changesets/cli@2.27.12` inside a `node:20-slim` Docker container against a minimal single-package project called `tipcalc`. The driver script (`run_experiment.sh`) simulated the full contributor workflow without a TTY by seeding changeset files directly from `scenario/` — the same files a developer would create by running `changeset add` interactively.

Three stages executed in sequence:

1. **v1.0.0** — a bare tip-calculator app, no changelog machinery yet.
2. **v1.1.0** — a `minor` changeset declaring "Split the bill evenly among a fixed number of diners." `changeset version` consumed the file, bumped `package.json` from `1.0.0` to `1.1.0`, and wrote `CHANGELOG.md`.
3. **v2.0.0** — a `major` changeset declaring "Split the bill unevenly by per-person weight; output format changed." A second `changeset version` run prepended the new section and bumped to `2.0.0`.

The tool was installed globally (`npm install -g @changesets/cli@2.27.12`). No monorepo workspace setup was needed because `tipcalc` is a single package.

## Real Output

The final `CHANGELOG.md` produced by the experiment:

```markdown
# tipcalc

## 2.0.0

### Major Changes

- 3bc5b64: Split the bill unevenly by per-person weight; output format changed

## 1.1.0

### Minor Changes

- e428baa: Split the bill evenly among a fixed number of diners
```

Observations on the output format:

- Sections are headed by version number (not a date or release tag).
- Each entry carries a short commit hash (`3bc5b64:`, `e428baa:`) that traces back to the commit that *staged the changeset file*, not the commit that introduced the code.
- Entries are grouped under `### Minor Changes` or `### Major Changes` headings — a clean semantic grouping that conventional-commit parsers also attempt but with more parsing risk.
- The `init`-default changelog generator (`@changesets/cli/changelog`) produces these hash prefixes. The `@changesets/changelog-github` plugin would replace them with linked PR numbers, but that requires a remote repo and a GitHub token.

## Pros (Observed)

**No commit message parsing.** The bump level and prose live in a `.changeset/*.md` file, not a commit message subject line. There is no regex parser, no ambiguity about squash-merge vs. merge-commit history, and no footgun from rewriting commit messages during a PR rebase.

**Contributor-written prose.** The changeset body is whatever the contributor typed at `changeset add` time — reviewed alongside the code diff, not generated after the fact. The two entries in the experiment are readable sentences, not raw commit subjects.

**Strict semver arithmetic.** `changeset version` computes the correct bump from the highest-level changeset present. The experiment confirmed this end-to-end: a `minor` file gave `1.1.0`, a `major` file gave `2.0.0`, no configuration required.

**Multi-package ready out of the box.** The changeset frontmatter names the package explicitly (`"tipcalc": minor`). In a monorepo with ten packages, each changeset file names only the affected packages, and `changeset version` applies independent bumps per package. No other changelog tool handles this as cleanly.

**Accumulating CHANGELOG.** Each `changeset version` run prepends a new section without clobbering existing history. The file grew correctly across two release cycles.

**Changeset files are reviewable artifacts.** Because `.changeset/*.md` files are committed to the repo, they appear in the PR diff. Reviewers can push back on an undersized bump or imprecise prose before the release, not after.

## Cons / Pain Points (Observed)

**`changeset status` requires a remote-tracked `main` branch.** This was the most jarring failure in the experiment. Running `changeset status` in a fresh local-only git repo produces:

```
🦋  error Error: Failed to find where HEAD diverged from "main".
    Does "main" exist and it's synced with remote?
```

The error is benign — `changeset version` does not care about git topology and succeeded every time — but `changeset status` is the command developers use to see what is pending. In a CI environment without a full remote checkout, this command is broken. Teams using shallow clones need to explicitly `git fetch origin main` before `changeset status` is usable.

**File overhead accumulates in large teams.** Every contributor creates a file per PR in `.changeset/`. In a busy monorepo this adds dozens of files per sprint. The files are deleted on `changeset version`, but during active development they accumulate and the directory becomes noisy.

**`changeset add` is interactive-only.** There is no `--non-interactive` flag for scripted CI. Seeding files manually (as this experiment does) is a valid workaround but requires knowing the file format. Automation that wants to pre-populate a changeset (e.g., from a Jira ticket field) must write the Markdown directly.

**Default `access: "restricted"` is a footgun.** Out of the box, `changeset init` sets `"access": "restricted"` in `config.json`. A developer who does not read this will find that `changeset publish` refuses to push their package to npm as a public package. Changing it to `"public"` is a one-line fix, but the default is wrong for the common solo or open-source case.

**Hash prefixes without a GitHub remote are opaque.** The default changelog format prefixes each entry with a commit hash (`e428baa:`). Without the `changelog-github` plugin and a remote repo, these hashes are not hyperlinked. In a GitHub-hosted project the experience is better, but it means the out-of-the-box experience depends on the presence of a configured remote.

**The non-conventional-commit model requires team habit adoption.** Changesets adds a new mandatory step to the contributor workflow: every PR with user-visible package changes must include a changeset file or the release automation will skip it. Teams must enforce this via CI lint (the `changeset status` check) or rely on social enforcement. There is no automatic fallback the way semantic-release has `--no-ci` modes.

## Docs vs. Reality

The v1 review (`changesets.md`) described the tool accurately in broad strokes. A few details deserve correction or nuance:

- The v1 article listed `@changesets/changelog-github` as the default `changelog` config. In practice, `changeset init` sets `"@changesets/cli/changelog"` (the local hash-based generator), not the GitHub plugin. The GitHub plugin is an optional upgrade.
- The v1 article presented `changeset status` as a straightforward "shows pending changesets" command. In practice, it requires a remote-tracked branch and fails in local-only repos, which is a common bootstrap scenario.
- The v1 article said "first-run setup is moderate." In practice, `changeset init` is a single command that takes under a second. The real friction is not setup but ongoing habit enforcement — every PR must have a changeset file or be explicitly exempt.
- The v1 article called Changesets "the dominant file-based release intent workflow for Node package monorepos." Hands-on, this reads as accurate. The workflow is coherent, the monorepo multi-package story is genuinely first-class, and the alternatives (semantic-release, release-it) solve a different problem.

## Revised Verdict

**Verdict: Recommended with caveats**

The core workflow — seed a file, run `changeset version`, get a correctly bumped CHANGELOG — worked exactly as documented with zero configuration beyond `changeset init`. For a team publishing npm packages from a monorepo and willing to treat changeset files as part of the PR review, this is the right tool.

The caveats are real:

- Solo developers or teams on single-package repos may find the file-per-PR overhead heavier than benefit. `release-it` or a simple `npm version` workflow is lighter.
- `changeset status` is unreliable outside a fully configured remote-tracking setup. CI pipelines should be written to call `changeset version` directly rather than gating on `status`.
- The default `access: restricted` and hash-only changelog format both require immediate post-`init` configuration. Neither default is wrong for its design intent, but both catch new users off guard.

The v1 verdict of "Recommended" holds. The hands-on evidence refines it: Changesets is specifically excellent for multi-package npm monorepos with PR-review culture. The further your project is from that profile, the more the overhead outweighs the benefit.
