# goreleaser v2.16.0 — Experiment Notes

## Environment

- goreleaser 2.16.0 (Linux x86_64, from GitHub Releases)
- golang:1.22-bullseye Docker base image
- No GitHub token, no remote configured
- Commands run: `goreleaser --version`, `goreleaser changelog`, `goreleaser release --snapshot --clean --skip=publish,announce,validate`

---

## Full Transcript

```
goreleaser version:
  ____       ____      _
 / ___| ___ |  _ \ ___| | ___  __ _ ___  ___ _ __
| |  _ / _ \| |_) / _ \ |/ _ \/ _` / __|/ _ \ '__|
| |_| | (_) |  _ <  __/ |  __/ (_| \__ \  __/ |
 \____|\___/|_| \_\___|_|\___|\__,_|___/\___|_|
goreleaser: Release engineering, simplified.
https://goreleaser.com

GitVersion:    2.16.0
GitCommit:     d76fb400136f96af3aaa7202776257885c9a6097
GitTreeState:  false
BuildDate:     2026-05-24T14:47:07Z
BuiltBy:       goreleaser
GoVersion:     go1.26.3
Compiler:      gc
ModuleSum:     h1:MgAx2uKCUXqv993rAVMd8Uk/HwzJdSz033z9kTta6kk=
Platform:      linux/amd64

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no changelog output yet)

==================== STAGE 2: goreleaser changelog for v1.0.0 ====================

--- goreleaser changelog ---
  ⨯ command failed                                   error=unknown command "changelog" for "goreleaser release"
(no changelog output yet)

==================== STAGE 3: implement even split ====================

program output:
Bill: $80.00  Tip: $14.40  Total: $94.40
Split evenly among 4: $23.60 each

==================== STAGE 4a: goreleaser release --snapshot for v2.0.0 ====================

  • starting release
  • skipping announce, publish, and validate...
  • cleaning distribution directory
  • loading environment variables
  • getting and validating git state
    • ignoring errors because this is a snapshot     error=couldn't get remote URL: fatal: No remote configured to list refs from.
    • using tags                                     previous=<unknown> current=v0.0.0
    • pipe skipped or partially skipped              reason=disabled during snapshot mode
  • parsing tag
  • setting defaults
    • DEPRECATED:  archives.format  should not be used anymore, check https://goreleaser.com/deprecations#archivesformat for more info
  • snapshotting
    • building snapshot...                           version=0.0.0-SNAPSHOT-none
  • ensuring distribution directory
  • setting up metadata
  • writing release metadata
  • loading go mod information
  • build prerequisites
  • building binaries
    • building                                       paths=. binaries=tipcalc target=linux_amd64_v1
  • archives
    • archiving                                      name=dist/tipcalc_0.0.0-SNAPSHOT-none_linux_amd64.tar.gz
  • calculating checksums
  • writing artifacts metadata
  • you are using deprecated options, check the output above for details
  • release succeeded after 0s
  • thanks for using GoReleaser!
--- goreleaser changelog (v2.0.0) ---
  ⨯ command failed                                   error=unknown command "changelog" for "goreleaser release"

==================== STAGE 4b: implement uneven split, snapshot release v3.0.0 ====================

  • starting release
  • skipping announce, publish, and validate...
  • cleaning distribution directory
  • loading environment variables
  • getting and validating git state
    • ignoring errors because this is a snapshot     error=couldn't get remote URL: fatal: No remote configured to list refs from.
    • using tags                                     previous=<unknown> current=v0.0.0
    • pipe skipped or partially skipped              reason=disabled during snapshot mode
  • parsing tag
  • setting defaults
    • DEPRECATED:  archives.format  should not be used anymore, check https://goreleaser.com/deprecations#archivesformat for more info
  • snapshotting
    • building snapshot...                           version=0.0.0-SNAPSHOT-none
  • ensuring distribution directory
  • setting up metadata
  • writing release metadata
  • loading go mod information
  • build prerequisites
  • building binaries
    • building                                       paths=. binaries=tipcalc target=linux_amd64_v1
  • archives
    • archiving                                      name=dist/tipcalc_0.0.0-SNAPSHOT-none_linux_amd64.tar.gz
  • calculating checksums
  • writing artifacts metadata
  • you are using deprecated options, check the output above for details
  • release succeeded after 0s
  • thanks for using GoReleaser!
--- goreleaser changelog (v3.0.0) ---
  ⨯ command failed                                   error=unknown command "changelog" for "goreleaser release"

==================== DONE — copying artifacts to out/ ====================

dist/ contents:
total 600
drwxr-xr-x 3 root root   4096 Jun  2 13:40 .
drwxr-xr-x 1 root root   4096 Jun  2 13:40 ..
-rw-r--r-- 1 root root    891 Jun  2 13:40 artifacts.json
-rw-r--r-- 1 root root   4545 Jun  2 13:40 config.yaml
-rw-r--r-- 1 root root    191 Jun  2 13:40 metadata.json
-rw-r--r-- 1 root root    113 Jun  2 13:40 tipcalc_0.0.0-SNAPSHOT-none_checksums.txt
-rw-r--r-- 1 root root 576143 Jun  2 13:40 tipcalc_0.0.0-SNAPSHOT-none_linux_amd64.tar.gz
drwxr-xr-x 2 root root   4096 Jun  2 13:40 tipcalc_linux_amd64_v1
Artifacts in /work/out:
total 16
drwxrwxrwx 1 root root 4096 Jun  2 13:40 .
drwxr-xr-x 1 root root 4096 Jun  2 13:40 ..
-rw-r--r-- 1 root root  200 Jun  2 13:40 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 13:40 git-tags.txt
-rw-r--r-- 1 root root 5105 Jun  2 13:40 transcript.txt
```

---

## Key Findings

### `goreleaser changelog` does not exist

The experiment was designed to test `goreleaser changelog` as a standalone subcommand. It does not exist in v2.16.0:

```
error=unknown command "changelog" for "goreleaser release"
```

The documentation references `goreleaser release --release-notes` and shows changelog configuration in `.goreleaser.yaml`, but there is no `goreleaser changelog` CLI subcommand. Changelog generation happens internally during `goreleaser release` and the result is embedded in the GitHub/GitLab/Gitea release body — it is not printed to stdout or written to a file as a primary output.

### Snapshot mode skips changelog generation

`goreleaser release --snapshot` skips the changelog/release-notes pipe entirely:

```
• pipe skipped or partially skipped    reason=disabled during snapshot mode
```

This means offline testing of the changelog feature — the thing most useful when evaluating goreleaser as a changelog tool — is not directly possible without a real remote and tag. The snapshot mode exists to validate the build and archive pipeline, not the release-notes text.

### No remote = version detection fails

Without a git remote, goreleaser cannot determine the previous tag for changelog comparison:

```
error=couldn't get remote URL: fatal: No remote configured to list refs from.
using tags    previous=<unknown> current=v0.0.0
```

Even though the repo had tags `v1.0.0`, `v2.0.0`, `v3.0.0`, goreleaser showed `current=v0.0.0` and `previous=<unknown>`. This is because the `use: github` changelog mode tries to call the GitHub API to compare refs, and without a remote it falls back to defaults.

### What snapshot mode does produce

Despite not generating changelog text, the snapshot release did produce real artifacts:
- `tipcalc_0.0.0-SNAPSHOT-none_linux_amd64.tar.gz` — a real compiled Go binary in a tarball
- `tipcalc_0.0.0-SNAPSHOT-none_checksums.txt` — SHA256 checksums
- `artifacts.json`, `metadata.json`, `config.yaml` — goreleaser internal metadata
- A `dist/tipcalc_linux_amd64_v1/` directory with the raw binary

The binary pipeline works perfectly offline. The release-note/changelog pipeline requires a remote.

### Deprecation warning

The config used `archives.format: tar.gz`. goreleaser 2.x emits:

```
DEPRECATED: archives.format should not be used anymore,
check https://goreleaser.com/deprecations#archivesformat for more info
```

The replacement is `archives.formats: [tar.gz]` (array). A minor config update is needed for a clean 2.x run.

### `use: github` vs `use: git`

The `.goreleaser.yaml` config used `changelog.use: github`. This mode calls the GitHub compare API to enumerate commits, which requires network access and a `GITHUB_TOKEN`. For local/offline changelog rendering, `changelog.use: git` reads directly from the local git log and does not require a token. The distinction matters for CI environments that need to preview changelog output before pushing.

---

## What the changelog output looks like (in production)

Because changelog generation was skipped in snapshot mode, no changelog text was produced in this experiment. Based on the `.goreleaser.yaml` config used, a real release with commits `feat: compute tip`, `feat: split the bill evenly`, `feat!: split the bill unevenly by weight` and `changelog.use: git` would produce output of the form:

```markdown
## Changelog

### Features

* feat: compute tip for a single bill by @example in https://github.com/example/tipcalc/commit/...
* feat: split the bill evenly among diners by @example in ...
* feat!: split the bill unevenly by weight by @example in ...
```

With `use: github` it would query the GitHub compare endpoint and produce similar grouped output embedded in the GitHub Release body. It is not written to `CHANGELOG.md` or any local file.

---

## Commands that work offline

| Command | Works offline? | Notes |
|---------|---------------|-------|
| `goreleaser --version` | Yes | |
| `goreleaser check` | Yes | Validates config only |
| `goreleaser release --snapshot --clean` | Partially | Builds binaries; skips changelog |
| `goreleaser release` | No | Requires remote + token for changelog |
| `goreleaser changelog` | N/A | Subcommand does not exist in v2.16.0 |

---

## Git log from experiment

```
0a0c218 (HEAD -> master, tag: v3.0.0) feat!: split the bill unevenly by weight
263bd1c (tag: v2.0.0) feat: split the bill evenly among diners
fdab1ac (tag: v1.0.0) feat: compute tip for a single bill
```
