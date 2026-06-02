# changesets Experiment Notes

## Environment
- Base image: node:20-slim
- Tool version: @changesets/cli 2.27.12
- Run date: 2026-06-01

## Observations

### What worked
- `changeset init` ran without errors and produced a valid `.changeset/config.json`.
- `changeset version` consumed the seeded changeset files and correctly produced `CHANGELOG.md` with versioned sections.
- Minor bump (changeset declared `minor`) correctly moved the package from 1.0.0 to 1.1.0, not 2.0.0 — verifying that Changesets reads the bump type from the file, not from commit messages.
- Major bump (changeset declared `major`) correctly moved the package from 1.1.0 to 2.0.0.
- The CHANGELOG.md accumulated entries across multiple `changeset version` runs — old entries were preserved, new entries prepended.
- Each changelog entry includes a short commit hash prefix (e.g., `e428baa:`) that traces back to the commit that staged the changeset file.
- The butterfly (`🦋`) emoji CLI output is distinctive and human-friendly for interactive use.

### What failed / friction
- `changeset status` errored consistently with: `Failed to find where HEAD diverged from "main". Does "main" exist and it's synced with remote?`
  This is a known limitation: the status command requires a remote-tracked `main` branch. In a fresh local-only git repo (as used in this experiment), there is no remote and no tracking branch, so the diverge detection fails. The `|| echo` catch in the script kept the experiment from aborting.
- The error does not affect `changeset version` — that command succeeds based purely on the presence of `.changeset/*.md` files, ignoring git topology.
- Default `access` in `config.json` is `"restricted"`, meaning packages would not publish publicly without a config change. This is a footgun for solo developers expecting `npm publish` to work out of the box.
- The default `changelog` is `"@changesets/cli/changelog"`, which adds a bare commit hash before each entry. The `@changesets/changelog-github` package (not installed here) would produce linked PR references instead, but that requires a configured GitHub repo. The offline default is functional but visually noisier than tools like git-cliff.

### Surprising findings (especially around the file-based workflow)
- The changeset file format is purely declarative: a YAML frontmatter declaring `"package-name": bump-level` and a freeform Markdown body. No commit message conventions, no regex parsers, no footguns from squash-merge history loss.
- The workflow inverts who writes the changelog: the contributor writes it at PR time (as part of `changeset add`), not a robot after the fact. This produces more intentional prose.
- `changeset version` is destructive by design — it deletes the `.changeset/*.md` files after consuming them. This is the intended "intent consumed" signal; the files only exist until the next release.
- The commit hash prefix in entries comes from the commit that added the changeset file, not the commit that introduced the actual code change. In a real PR workflow these are typically the same commit (or the PR merge commit), but in the seeded scenario they differ.
- Version numbering starts from whatever is in `package.json`. The experiment started at `1.0.0` and bumped to `1.1.0` (minor) then `2.0.0` (major), confirming strict semver arithmetic without any configuration.

## Full transcript

```
tool under test:
2.27.12

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: changeset init — set up .changeset/ config ====================

🦋  Thanks for choosing changesets to help manage your versioning and publishing
🦋  
🦋  You should be set up to start using changesets now!
🦋  
🦋  info We have added a `.changeset` folder, and a couple of files to help you out:
🦋  info - .changeset/README.md contains information about using changesets
🦋  info - .changeset/config.json is our default config
--- .changeset/config.json ---
{
  "$schema": "https://unpkg.com/@changesets/config@3.1.4/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "restricted",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": []
}
(no CHANGELOG.md yet)

==================== STAGE 3: add v2 changeset, implement even split ====================

--- changeset status ---
🦋  error Error: Failed to find where HEAD diverged from "main". Does "main" exist and it's synced with remote?
🦋  error     at getDivergedCommit (...)
🦋  error     at async getChangedFilesSince (...)
🦋  error     at async Object.getChangedPackagesSinceRef (...)
🦋  error     at async getVersionableChangedPackages (...)
🦋  error     at async status (...)
🦋  error     at async run (...)
(status above)
--- changeset version (bumps package.json + writes CHANGELOG.md) ---
🦋  All files have been updated. Review them and commit at your leisure
----- CHANGELOG.md -----
# tipcalc

## 1.1.0

### Minor Changes

- e428baa: Split the bill evenly among a fixed number of diners
------------------------

==================== STAGE 4a: commit v2.0.0 release ====================

----- CHANGELOG.md -----
# tipcalc

## 1.1.0

### Minor Changes

- e428baa: Split the bill evenly among a fixed number of diners
------------------------

==================== STAGE 4b: add v3 changeset (major), version, release ====================

🦋  All files have been updated. Review them and commit at your leisure
----- CHANGELOG.md -----
# tipcalc

## 2.0.0

### Major Changes

- 3bc5b64: Split the bill unevenly by per-person weight; output format changed

## 1.1.0

### Minor Changes

- e428baa: Split the bill evenly among a fixed number of diners
------------------------

==================== BONUS: changeset status after all releases ====================

🦋  error Error: Failed to find where HEAD diverged from "main". Does "main" exist and it's synced with remote?
🦋  error     at getDivergedCommit (...)
(no pending changesets)

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 16
-rw-r--r-- 1 root root  213 Jun  2 03:38 CHANGELOG.md
-rw-r--r-- 1 root root  385 Jun  2 03:38 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:38 git-tags.txt
-rw-r--r-- 1 root root 4180 Jun  2 03:38 transcript.txt
```
