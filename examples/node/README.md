# Node tool experiments

Six Node/npm changelog/release tools, each driven through the tip-calculator life cycle in Docker.
Run any experiment with `make run` from its directory. Artifacts land in `out/`.

## Results (run date: 2026-06-02)

| Tool | Version | Outcome | Headline finding |
|------|---------|---------|-----------------|
| [conventional-changelog-cli](conventional-changelog-cli/) | 5.0.0 | ✅ Ran, but deprecated | npm warns at install: deprecated, use the underlying `conventional-changelog` package. `feat!` breaking-change shorthand produces a **silent empty body** in the CHANGELOG — no warning, exit 0. `-u` (unreleased preview) flag works and is useful. |
| [release-it](release-it/) | 17.10.0 | ⚠️ Runs with caveats | `feat!` silently mis-classified as a patch bump; produces an empty CHANGELOG entry with only a heading. Also needs `requireUpstream: false` + `requireBranch: false` for local use (undocumented). Dry-run output is excellent. |
| [standard-version](standard-version/) | 9.5.0 | ✅ Works on Node 20 | Surprise: still fully functional despite being archived since 2022. `feat!` correctly triggers major bump + `⚠ BREAKING CHANGES`. Four transitive deprecation warnings at install (noise only). Migration to commit-and-tag-version is the right call for new projects — not because it's broken, but because it's archived. |
| [semantic-release](semantic-release/) | 24.2.5 | ❌ Strictly CI-only | `--dry-run --no-ci` still runs `git ls-remote` with an authenticated remote call before any local commit analysis. Completely opaque without a real remote. No CHANGELOG produced. Plugin loading from global install works fine. |
| [changesets](changesets/) | 2.27.12 | ✅ Full success | File-based intent workflow works cleanly. `changeset version` needs no remote. `changeset status` fails on local-only repos (non-fatal). Default `access: "restricted"` in config.json silently blocks public npm publishes. Best fit for multi-package monorepos with PR-review culture. |
| [commit-and-tag-version](commit-and-tag-version/) | 12.5.0 | ✅ Perfect run | Zero failures. `feat!` → correct major bump + `⚠ BREAKING CHANGES` section. Auto-generates comparison links from `repository` field. The clear winner for local-only changelog generation in this Node batch. |

## Recommended by use case

- **Local changelog generation (single package):** commit-and-tag-version
- **Multi-package monorepo with PR workflow:** changesets
- **Fully automated CI releases:** semantic-release (requires GitHub Actions or equivalent)
- **Interactive release with preview:** release-it (use `BREAKING CHANGE:` footer, not `feat!` subject shorthand)
- **Migrating from standard-version:** commit-and-tag-version (drop-in replacement, same flags)

## Key gotchas

- **`feat!` support varies widely.** commit-and-tag-version and standard-version handle it correctly. release-it and conventional-changelog-cli silently ignore it or produce empty entries. Always test breaking-change detection before relying on it.
- **semantic-release `--dry-run` is not offline.** The flag prevents writes but not the `git ls-remote` remote-auth call that happens first. There is no flag combination that makes it work without a real remote.
- **release-it requires `requireUpstream: false` for local use.** The `"push": false` setting does not suppress the upstream check; it must be disabled separately.
- **changesets `access: "restricted"` default.** The generated `.changeset/config.json` sets `access: "restricted"`. Change to `"public"` before `changeset publish` on a public npm package or publishes will silently fail.
- **conventional-changelog-cli is deprecated.** npm prints a deprecation warning at install time. The underlying `conventional-changelog` package is the maintained path.
