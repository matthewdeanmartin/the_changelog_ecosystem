# semantic-release Experiment Notes

## Environment
- Base image: node:20-slim (Debian Bookworm)
- Tool version: semantic-release 24.2.5
- Plugins installed globally: @semantic-release/changelog@6.0.3, @semantic-release/git@10.0.1, @semantic-release/npm@12.0.1, @semantic-release/exec@6.0.3
- Run date: 2026-06-01

## Observations

### What worked (in dry-run mode)
- Docker image built cleanly; all five plugins loaded without error.
- The fixture app (`tipcalc`) ran correctly at each stage:
  - Stage 1: `Bill: $80.00  Tip (18%): $14.40  Total: $94.40`
  - Stage 3: added even-split output
  - Stage 4: added uneven-split (breaking-change) output
- Plugin loading was successful in every invocation:
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
- The `.releaserc.json` config was parsed and plugins were resolved from the global install.

### What requires CI / remote
Everything beyond plugin loading. `semantic-release --dry-run --no-ci` halts at `git ls-remote` before it reads a single commit:

```
[semantic-release] › ✘  An error occurred while running semantic-release:
ExecaError: Command failed with exit code 128:
  git ls-remote --heads 'https://github.com/example/tipcalc'

remote: Invalid username or token. Password authentication is not supported
fatal: Authentication failed for 'https://github.com/example/tipcalc/'
```

This failure occurred identically across all three dry-run calls (Stages 2, 3, and 4a). The remote URL comes from `package.json`'s `repository.url` field. Even with `--dry-run --no-ci`, semantic-release resolves the remote and attempts an authenticated network call before touching the local git history.

The following capabilities were not reachable locally:
- Commit analysis (never reached)
- Version calculation (never reached)
- Changelog generation (no CHANGELOG.md was ever written)
- npm version bump (never reached)
- Git tag creation (git-tags.txt was empty)

### Surprising findings
1. **`--dry-run` does not mean "offline."** The flag prevents writes but does not skip the remote-verification step. Remote auth is treated as a precondition, not a publish-time concern.
2. **`--no-ci` only disables the CI-environment check**, not the remote connectivity requirement. The two flags together are insufficient to run semantic-release usefully without a real remote.
3. **Plugin resolution from a global install worked.** The Dockerfile installs globally (`npm install -g`) and `.releaserc.json` references bare plugin names; semantic-release found them all via Node's module resolution. No local `node_modules` was needed for plugin loading.
4. **The error surface is verbose.** The full ExecaError stack trace (including ANSI-colored duplicate) is printed to stdout/stderr on every failure, making the transcript long and noisy for a simple "no remote" error.
5. **The `repository.url` in package.json is the trigger.** semantic-release reads the remote from git config or falls back to `package.json`. A repo with no remote configured and no `repository.url` might fail earlier or differently.

## Full transcript

```
tool under test:
24.2.5

NOTE: semantic-release is a CI-native tool.
      Dry-run mode shows what it would do; actual release requires a remote.

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: semantic-release --dry-run (shows what v1 release would do) ====================

[3:39:02 AM] [semantic-release] › ℹ  Running semantic-release version 24.2.5
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "verifyConditions" from "@semantic-release/changelog"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "verifyConditions" from "@semantic-release/npm"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "verifyConditions" from "@semantic-release/git"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "analyzeCommits" from "@semantic-release/commit-analyzer"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "generateNotes" from "@semantic-release/release-notes-generator"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "prepare" from "@semantic-release/changelog"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "prepare" from "@semantic-release/npm"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "prepare" from "@semantic-release/git"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "publish" from "@semantic-release/npm"
[3:39:02 AM] [semantic-release] › ✔  Loaded plugin "addChannel" from "@semantic-release/npm"
[3:39:02 AM] [semantic-release] › ✘  An error occurred while running semantic-release: ExecaError: Command failed with exit code 128: git ls-remote --heads 'https://github.com/example/tipcalc'

remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/example/tipcalc/'
(dry-run output above)
(no CHANGELOG.md yet)

==================== STAGE 3: implement even split ====================

program output:
Bill: $80.00  Tip: $14.40  Total: $94.40
Split evenly among 4: $23.60 each
--- semantic-release --dry-run (v2 detection) ---
[3:39:03 AM] [semantic-release] › ℹ  Running semantic-release version 24.2.5
[... all plugins loaded ...]
[3:39:04 AM] [semantic-release] › ✘  An error occurred while running semantic-release: ExecaError: Command failed with exit code 128: git ls-remote --heads 'https://github.com/example/tipcalc'
(dry-run above)
(no CHANGELOG.md yet)

==================== STAGE 4a: implement uneven split (breaking), dry-run v3 detection ====================

--- semantic-release --dry-run (breaking change = major bump) ---
[3:39:04 AM] [semantic-release] › ℹ  Running semantic-release version 24.2.5
[... all plugins loaded ...]
[3:39:05 AM] [semantic-release] › ✘  An error occurred while running semantic-release: ExecaError: Command failed with exit code 128: git ls-remote --heads 'https://github.com/example/tipcalc'
(dry-run above)
(no CHANGELOG.md yet)

==================== BONUS: .releaserc.json config used ====================

{
  "branches": ["main", "master"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    ["@semantic-release/changelog", { "changelogFile": "CHANGELOG.md" }],
    ["@semantic-release/npm", { "npmPublish": false }],
    ["@semantic-release/git", {
      "assets": ["CHANGELOG.md", "package.json"],
      "message": "chore(release): ${nextRelease.version}"
    }]
  ]
}

==================== NOTE: what requires a real CI environment ====================

The following require a git remote, GITHUB_TOKEN, and CI:
  semantic-release          # actual release
  semantic-release --ci     # explicit CI mode

Local-demonstrable:
  semantic-release --dry-run --no-ci  # version analysis + changelog preview

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
-rw-r--r-- 1 root root   157 Jun  2 03:39 git-log.txt
-rw-r--r-- 1 root root     0 Jun  2 03:39 git-tags.txt
-rw-r--r-- 1 root root 20263 Jun  2 03:39 transcript.txt
```
