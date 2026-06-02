# Experiment Notes: GitReleaseManager 0.20.0

**Run date:** 2026-06-02
**Environment:** Docker, mcr.microsoft.com/dotnet/sdk:8.0
**NuGet package:** gitreleasemanager.tool 0.20.0
**Binary:** dotnet-gitreleasemanager

---

## Key Finding: GitHub-API-Only, No Offline Mode

Every subcommand (`create`, `publish`, `close`, `export`) immediately rejects invocations
without a `--token` argument. There is no local changelog mode.

### Token is a required argument — not an optional one

The CLI uses `CommandLineParser` and marks `--token` as `Required = true`. This means
argument validation happens before any network call, so even a purely offline test
(fake owner, fake repo, no network) fails at the argument-parsing stage:

```
ERROR(S):
  Required option 'token' is missing.
```

This was confirmed for all four of the main operational subcommands:

| Subcommand | Error observed                                   |
|------------|--------------------------------------------------|
| `create`   | Required option 'token' is missing.              |
| `export`   | Required option 'token' is missing. + fileOutputPath missing |
| `publish`  | Required option 'token' is missing.              |
| `close`    | Required option 'token' is missing.              |

### NuGet package ID correction

The NuGet package is **`gitreleasemanager.tool`** (not `GitReleaseManager`).
Attempting to install `GitReleaseManager` directly fails at build time with:

```
The settings file in the tool's NuGet package is invalid: Settings file
'DotnetToolSettings.xml' was not found in the package.
```

This is a discoverable gotcha — the tool's own README and NuGet page use different
identifiers, and the `.tool` suffix package is the correct one.

### Two additional required arguments at compile time

Beyond `--token`, `--owner` (`-o`) and `--repository` (`-r`) are also required. A working
invocation requires a minimum of three arguments before any business logic executes.

The `export` subcommand additionally requires `--fileOutputPath` (`-f`) for the output
file path.

### Subcommand surface

```
create    Creates a draft release notes from a milestone.
discard   Discards a draft release.
addasset  Adds an asset to an existing release.
close     Closes the milestone.
open      Opens the milestone.
publish   Publishes the Release.
export    Exports all the Release Notes in markdown format.
init      Creates a sample Yaml Configuration file in root directory
showconfig  Shows the current configuration
label     Deletes existing labels and replaces with set of default labels.
```

Only `init` and `showconfig` are plausibly runnable without a live GitHub connection.

---

## Full Experiment Transcript

```
==================== TOOL UNDER TEST: GitReleaseManager 0.20.0 ====================

NuGet package: gitreleasemanager.tool
Binary: dotnet-gitreleasemanager
GitReleaseManager 0.20.0+f0911e4b5480846c34f0026b2be8fb40871b7c25

GitReleaseManager is a GitHub-API-driven CLI.
All subcommands require: --owner, --repository, and a valid --token.
There is no offline mode.

==================== STAGE 1: v1.0.0 code committed — no changelog yet ====================

Git log after stage 1:
9914d6d (HEAD -> master, tag: v1.0.0) feat: compute tip for a single bill
----- gitreleasemanager output captured above -----
(no local CHANGELOG.md — tool operates exclusively via GitHub Releases API)
---------------------------------------------------

==================== STAGE 2: attempt 'gitreleasemanager create' (no token — expected to fail) ====================

Command: gitreleasemanager create --owner test --repository test --milestone 1.0.0
Expected: authentication error or GitHub API connection error

GitReleaseManager 0.20.0+f0911e4b5480846c34f0026b2be8fb40871b7c25
Copyright (c) 2015 - Present - GitTools Contributors

ERROR(S):
  Required option 'token' is missing.

  [... full create subcommand help omitted for brevity ...]

==================== STAGE 3: v2 commit then attempt 'gitreleasemanager export' (no token — expected to fail) ====================

Git log after stage 3:
3d11e8f (HEAD -> master, tag: v2.0.0) feat: split the bill evenly among diners
9914d6d (tag: v1.0.0) feat: compute tip for a single bill

Command: gitreleasemanager export --owner test --repository test --tagName v1.0.0
Expected: authentication error or GitHub API connection error

ERROR(S):
  Required option 'token' is missing.
  Required option 'f, fileOutputPath' is missing.

==================== STAGE 4: attempt 'publish' and 'close' subcommands (no token — expected to fail) ====================

--- publish ---
ERROR(S):
  Required option 'token' is missing.

--- close ---
ERROR(S):
  Required option 'token' is missing.

==================== STAGE 6: SUMMARY — GitReleaseManager is GitHub-API-only ====================

Findings:
  1. Every subcommand (create, publish, close, export) requires:
       --owner        GitHub repository owner
       --repository   GitHub repository name
       --token        Personal access token or CI token
  2. Without a valid token, every command fails immediately.
  3. There is no local changelog file mode — the tool reads/writes
     GitHub Milestones, Issues, and the Releases API exclusively.
  4. The 'export' subcommand fetches release notes from the Releases
     API rather than generating them from local git history.
  5. Verdict: CI-only — do not use without GitHub credentials
     and a live remote.

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 24
-rw-r--r-- 1 root root   137 Jun  2 14:24 git-log.txt
-rw-r--r-- 1 root root    14 Jun  2 14:24 git-tags.txt
-rw-r--r-- 1 root root 14702 Jun  2 14:24 transcript.txt
```

---

## Conclusion

`GitReleaseManager` 0.20.0:

- Requires `--token`, `--owner`, `--repository` for every operational subcommand.
- Has zero local changelog capability — all data comes from the GitHub Releases and
  Milestones APIs.
- The `export` subcommand reads from GitHub Releases (not local git history), so it
  also requires live API access.
- The correct NuGet package ID is `gitreleasemanager.tool`, not `GitReleaseManager`.
- **Verdict: CI-only — do not use without GitHub credentials and a live remote.**
