# cargo-dist Experiment Notes

## Environment
- Base image: rust:1.87-slim (Debian Bookworm)
- Tool version: cargo-dist 0.32.0 (binary renamed from `dist` to `cargo-dist` in Dockerfile)
- Run date: 2026-06-01

## Observations

### What worked

- `cargo-dist init` partially succeeded on the first attempt (non-interactive mode via `--yes` equivalent). It wrote `[profile.dist]` to `Cargo.toml` and created a `dist-workspace.toml` with a `[dist]` section, logging `dist is setup!` before failing on `dist generate`.
- The tool's error messages are clear and actionable: it explicitly told us which file needs `repository = "https://github.com/..."` and what key to set.
- The `cargo-dist` binary in the container works as expected — the rename from `dist` to `cargo-dist` in the Dockerfile was transparent to all commands.

### What failed / friction

- `cargo-dist init` fails with `IO error: not a terminal` when called without `--yes` (interactive fallback), and fails with `Github CI support requires you to specify the URL of your repository` when `--yes` is used and no `repository` key is present in `Cargo.toml`. Both forms of init fail in a headless container without a `repository` key pre-set.
- `cargo-dist plan` and `cargo-dist manifest` both fail with the same `Github CI support requires you to specify the URL of your repository` error. **All non-trivial cargo-dist commands require a `repository` URL** even for local dry-runs — there is no offline/no-remote mode.
- The `dist-manifest.json` output artifact is empty (0 bytes) because `cargo-dist manifest` failed before writing anything.
- No `.github/` CI workflow was generated due to the init failure.
- cargo-dist has **no changelog generation capability**. It is a release distribution tool (binary packaging, installer scripts, GitHub Releases), not a changelog tool.

### Surprising findings

- The `repository` URL requirement is enforced even for `cargo-dist plan`, which conceptually just describes what would be built. There is no `--skip-ci` or `--local` flag to bypass the GitHub URL check for local experimentation.
- cargo-dist is architecturally a two-phase tool: `init` writes config and generates CI YAML; `plan`/`manifest` describe the release artifacts. Both phases are tightly coupled to GitHub Actions — it is not designed for use outside of a CI pipeline.
- The tool's changelog integration is passive: it reads a `CHANGELOG.md` (configurable via `changelog-path` in `[dist]`) to populate the GitHub Release body, but it does not write or generate changelogs. A separate tool (git-cliff, release-plz, etc.) must produce the file.
- The binary shipped by axodotdev is named `dist` inside the release tarball; the Dockerfile must rename it. This is a minor packaging quirk that could trip up manual installs.
- cargo-dist v0.32.0 is a fairly mature release but the non-interactive init experience in a container is poor: `--yes` is not a recognized flag name (the tool uses a wizard), leading to the double-invocation pattern in the script.

## Full transcript

```
tool under test:
cargo-dist 0.32.0

==================== STAGE 1: v1.0.0 code, NO dist config ====================

(no CHANGELOG.md yet)

==================== STAGE 2: cargo-dist init — add dist config and CI workflows ====================

--- cargo-dist init (non-interactive with defaults) ---
let's setup your dist config...

✔ added [profile.dist] to your workspace Cargo.toml

✔ added [dist] to your root dist-workspace.toml
✔ dist is setup!

running 'dist generate' to apply any changes

  × Github CI support requires you to specify the URL of your repository
  help: Set the repository = "https://github.com/..." key in these manifests:
        /work/app/Cargo.toml

let's setup your dist config...

  × IO error: not a terminal

(init failed — see below)

--- Cargo.toml [workspace.metadata.dist] section ---
(no dist metadata added)

(no .github/ generated)
(no CHANGELOG.md yet)

==================== STAGE 3: cargo-dist plan — shows what would be built ====================

--- cargo-dist plan ---
  × Github CI support requires you to specify the URL of your repository
  help: Set the repository = "https://github.com/..." key in these manifests:
        /work/app/Cargo.toml

(cargo-dist plan output above)
(no CHANGELOG.md yet)

==================== STAGE 4a: v2.0.0 — show dist plan for even-split release ====================

--- cargo-dist plan for v2.0.0 ---
  × Github CI support requires you to specify the URL of your repository
  help: Set the repository = "https://github.com/..." key in these manifests:
        /work/app/Cargo.toml

(no CHANGELOG.md yet)

==================== STAGE 4b: v3.0.0 — uneven split, show manifest ====================

--- cargo-dist manifest (JSON) ---
  × Github CI support requires you to specify the URL of your repository
  help: Set the repository = "https://github.com/..." key in these manifests:
        /work/app/Cargo.toml

(no CHANGELOG.md yet)

==================== BONUS: cargo-dist changelog integration note ====================

cargo-dist does NOT generate changelogs.
Release notes come from:
  1. A companion tool: git-cliff, release-plz, etc.
  2. A CHANGELOG.md file read at release time.
  3. GitHub's auto-generated release notes.

The dist.toml / Cargo.toml [dist] section can specify a changelog file:
  [dist]
  changelog-path = 'CHANGELOG.md'  # used for GitHub Release body

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 12
-rw-r--r-- 1 root root    0 Jun  2 03:12 dist-manifest.json
-rw-r--r-- 1 root root  237 Jun  2 03:12 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 03:12 git-tags.txt
-rw-r--r-- 1 root root 2485 Jun  2 03:12 transcript.txt
```
