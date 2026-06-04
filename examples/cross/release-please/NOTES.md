Tool: release-please    Status: done (local-only subset — documents the offline limit)

# Experiment notes

release-please is a GitHub-API tool with **no fully offline mode**. Per the task brief,
this experiment drives the *local-only subset* and captures, empirically, the exact point
where the tool requires the GitHub API.

## Checklist
- [x] Copied TEMPLATE, set TOOL in Makefile
- [x] Dockerfile installs the tool + git on a pinned base image (node:20-slim + release-please@17.7.0)
- [x] app/ runs and prints (all three versions)
- [x] scenario/ has the tool's seed config (release-please-config.json + .release-please-manifest.json)
- [x] run_experiment.sh walks the local life-cycle stages, commits/tags in /work
- [x] `make run` completes end-to-end with only Docker installed (offline, via --network none)
- [x] out/ contains the config/manifest, git log/tags, transcript (NO CHANGELOG.md — see finding)
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + the offline-limit finding captured below
- [x] content/articles/release-please.v2.md written, grounded in the run
- [x] pelican build still clean

## Installed version
`release-please --version` => `17.7.0` (npm, on node:20-slim).

## The experiment design (why it differs)
The Makefile runs the container with `--network none`. The driver first does everything
that genuinely works locally — builds an isolated git repo with Conventional-Commit
history across the three tip-calculator versions, lays down release-please-config.json
(`release-type: python`, `package-name: tipcalc`, `include-v-in-tag: false`) and the
manifest seeded at 1.0.0, tags `tipcalc-1.0.0` — and *then* attempts
`release-please release-pr --local --local-path=/work/app --dry-run`. Offline, that fails;
the failure is the deliverable.

## Headline finding (verified, not inferred)
release-please has **no local-only release path**. Every subcommand calls the GitHub API
before doing any work:

- `release-pr --local --local-path … --dry-run` (offline) fails with:
  ```
  RequestError [HttpError]: getaddrinfo EAI_AGAIN api.github.com
      at GitHubApi.defaultBranch (.../github-api.js:314)
      at GitHubApi.create (.../github-api.js:306)
      at LocalGitHub.create (.../local-github.js:46)
    request: { method: 'GET', url: 'https://api.github.com/repos/example/tipcalc' }
  ```
  i.e. even in `--local` mode (`LocalGitHub.create`) the first thing it does is
  `GitHubApi.defaultBranch` → `GET /repos/{owner}/{repo}`. The `--local` flag controls the
  *clone* strategy, not the API dependency.
- With a network + a *fake* token (verified separately), the same call returns
  `401 Bad credentials` — so a real token is mandatory too.
- `debug-config` is **not** a local config inspector: it also immediately calls
  `GET /repos/{owner}/{repo}` and fails the same way. (Offline it printed usage then the
  API error.)

What *does* work locally: the repo + config + manifest setup, the tag scheme, and the
Conventional-Commit history that encodes the intended bumps (`feat` → minor,
`feat!`/`BREAKING CHANGE` → major). release-please's version inference would consume
exactly this — but only after it can reach GitHub.

## Per-stage output
### Stage 1 — no changelog
v1.0.0 committed, tagged `tipcalc-1.0.0`; app prints the single-bill total; no CHANGELOG.md
(release-please never writes one locally).

### Stage 2 — "changelog created"
`debug-config` attempted; reaches for the GitHub API. No local changelog is produced.

### Stage 3 — changelog updated
Even-split feature committed as `feat: split the bill evenly among diners`.

### Stage 4 — bump + release (the wall)
Uneven-split committed as `feat!: … / BREAKING CHANGE:`. git history release-please would
parse:
```
feat!: split the bill unevenly by weight
feat: split the bill evenly among diners
feat: compute the tip for a single bill   (tag: tipcalc-1.0.0)
```
`release-pr --local --dry-run` then hits the GitHub-API wall described above. Exit code 1.

## Pros (observed, of the local subset)
- The config + manifest model is clean and well-documented; `release-type` covers many
  ecosystems (python, node, rust, go, java, simple, …).
- Conventional-Commit history is the single source of truth for the bump — no fragments,
  no manual version edits.
- A genuine `--local` / `--local-path` flag exists, hinting at offline intent; it just
  doesn't remove the API dependency.

## Cons / pain points (observed)
- **No offline mode at all.** Cannot produce a CHANGELOG.md or a version bump without a
  reachable GitHub repo *and* a valid token. Even `--dry-run` and `--local` call the API
  first (`GET /repos/{owner}/{repo}` via `GitHubApi.defaultBranch`).
- `debug-config` sounds local but isn't — same API dependency.
- This makes release-please impossible to fully exercise in an isolated container the way
  fragment tools (towncrier, scriv, reno, logchange) can be.

## Docs vs. reality
- The original review calls it "GitHub-centered" and notes it "opens a release PR" and
  "creates GitHub Releases." **Confirmed and then some**: it is GitHub-*required*, not
  merely GitHub-centered. There is no local fallback for generating the changelog.
- The original review's installation snippet is the GitHub Action; the npm CLI exists but
  carries the identical API requirement.

## Revised verdict
Keep the original **Recommended** verdict *for its intended habitat* (GitHub repos with a
token in CI), but reclassify it for THIS site's experiment taxonomy as **server/API-bound**,
alongside glab/release-drafter — not a local CLI like logchange or towncrier. The
local-only subset is limited to repo + config setup and commit-convention modeling; the
actual changelog/release output requires a live GitHub repo + token.

## Raw transcript
See `out/transcript.txt` (regenerate with `make run`).
