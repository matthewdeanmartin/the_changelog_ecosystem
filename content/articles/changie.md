Title: changie
Date: 2026-06-02
Slug: changie
Ecosystem: Go
Tags: go, go-cli, keep-a-changelog, news-fragments, custom-templates, version-management, changelog-file, language-agnostic, fragment-tool, hands-on
Tool_URL: https://changie.dev/
Tool_Version: 1.24.0
Tool_Status: active
Experiment: examples/go/changie/
Summary: File-based, language-agnostic changelog management distributed as a single Go binary — hands-on testing confirms a solid fragment workflow with a couple of well-defined rough edges.



## Overview

`changie` is a file-based changelog tool: each change is captured while the work is fresh, later batched into a release version, and finally merged into the main changelog. It is written in Go and shipped as a single binary, but the workflow is intentionally language-agnostic.

The closest mental model is Towncrier or Changesets without being tied to Python or Node. It is a good fit for teams that want contributors to write release-note fragments instead of trying to reconstruct user impact from commits at release time.

> A reproducible hands-on experiment for this tool lives in [`examples/go/changie/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/changie). We drove changie through a real three-release life cycle in an offline Docker container; the real output and findings are at the end of this article.

## Installation

```bash
# Single binary from GitHub Releases — no runtime needed:
curl -L https://github.com/miniscruff/changie/releases/download/v1.24.0/changie_1.24.0_linux_amd64.tar.gz | tar xz

# Homebrew and other package managers are also available:
# https://github.com/miniscruff/changie
```

## What It Does

- Creates change files with `changie new`.
- Batches unreleased changes into a version file with `changie batch`.
- Merges version files into a parent `CHANGELOG.md` with `changie merge`.
- Tracks change kinds such as added, changed, deprecated, removed, fixed, and security.
- Can compute version bumps from change metadata.
- Supports templates, custom prompts, custom fields, multiple projects, and replacements.

## Configuration

Changie uses `.changie.yaml`, normally created by `changie init`. The config names the change directory, changelog path, version format, change kinds, and output templates.

```yaml
changesDir: .changes
changelogPath: CHANGELOG.md
versionFormat: '## {{.Version}} - {{.Time.Format "2006-01-02"}}'
changeFormat: '- {{.Body}}'
kinds:
  - label: Added
    auto: minor
  - label: Fixed
    auto: patch
  - label: Security
    auto: patch
```

First-run setup is low to moderate. The init command creates a starting point, but teams should tune kinds, version formatting, and any custom prompts before asking contributors to use it. Note the Go `text/template` date convention (`2006-01-02` reference time) — writing `YYYY-MM-DD` produces garbled dates with no error. Config keys are camelCase (`versionFormat`, not `version_format`); snake_case keys are silently ignored.

## Ecosystem Fit

For Go teams, changie fits well because it is a static CLI binary and works cleanly in CI without language runtime setup. It is also useful in polyglot repositories where GoReleaser would be too Go-specific and Changesets would be too Node-specific.

It does not build binaries or publish GitHub Releases. Pair it with GoReleaser, GitHub Actions, or a package-specific release process when publication is needed.

## Maintenance Status

- Latest version: **1.24.0**
- Last release: **2025-11-22**
- GitHub stars: **879**
- Appears actively maintained.
- Repository: <a href="https://github.com/miniscruff/changie" target="_blank" rel="noopener noreferrer">https://github.com/miniscruff/changie</a>

The documentation is active and covers quick start, configuration, batching, merging, templates, project support, backups, and CLI commands.

---

## Hands-On Findings

We built a Docker container (`debian:bookworm-slim`), downloaded the `changie_1.24.0_linux_amd64` binary from GitHub Releases, and ran a scripted three-release life cycle (v1.0.0 → v2.0.0 → v3.0.0) against a minimal shell-script fixture. **No Go toolchain was involved** — the experiment is intentionally language-agnostic. Full transcript and artifacts are in [`examples/go/changie/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/changie).

The sequence per release: `changie init` (once) → drop a pre-written `.changie.yaml` → copy hand-written fragment `.yaml` files into `.changes/unreleased/` → `changie batch vX.Y.Z` → `changie merge`.

**The tool worked.** All three release cycles completed end-to-end without a single error.

### Real output

The final `CHANGELOG.md` (newest-first, automatically re-sorted by `merge`):

```markdown
## v3.0.0 - 2026-06-02
### Added
- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2) — output format changed## v2.0.0 - 2026-06-02
### Added
- Split the bill evenly among 4 diners## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total
```

(That run-together formatting is not a transcription error — it is a real bug, see below.)

### Pros (observed)

- **Single binary, truly zero runtime dependencies.** The tar.gz from GitHub Releases extracted to one ~9 MB file and worked immediately on a bare Debian image. This is the clearest advantage over Python-based tools like scriv or towncrier.
- **Fragment-first workflow is low-friction.** `changie batch` consumes the unreleased fragments and writes the version file in one atomic step, so there is no risk of double-counting. `changie merge` reads every `.changes/v*.md` and prepends the newest version without requiring any state beyond the files themselves.
- **Newest-first ordering is automatic.** Each `merge` re-sorts version files in descending semver order; you never maintain the ordering yourself.
- **Config uses Go templates throughout** (`versionFormat`, `kindFormat`, `changeFormat`), powerful enough for any reasonable changelog style.
- **Language-agnostic by design.** It knows nothing about Go modules, npm, or any build system — it reads and writes Markdown. A reasonable default for polyglot monorepos.

### Cons (observed)

- **No blank line between version sections.** The generated `CHANGELOG.md` runs all `##` version headings together with no separator (visible in the output above). The raw file fails Markdown linters and looks cluttered. This is a template gap: the default `versionFormat` has no trailing newline and `merge` does not insert one. Workaround: end `versionFormat` with `\n` — but the docs do not mention this, and the `changie init` defaults ship broken in this regard.
- **`changie new` is interactive-only.** There is no `--kind`/`--body` flag for non-interactive use in v1.24.0. Scripted pipelines must drop hand-written `.yaml` files directly into `.changes/unreleased/`. Not hard, but undocumented in the quick-start.
- **No native breaking-change signal.** The fragment schema has `kind` and `body` (plus optional custom fields). There is no `breaking: true` field that changie renders differently; we encoded the breaking note in the body text.
- **`changie init` overwrites silently.** Running it a second time on a directory that already has `.changie.yaml` silently overwrites it — no `--no-clobber` guard or prompt, and no `--config` flag to seed from a template file.
- **The `v` prefix is baked into the default config.** The default `versionFormat` renders `## v1.0.0 - …`. If your tags lack a `v` prefix you must adjust the template, which is not mentioned prominently.

### Docs vs. reality

The documentation describes the `init → new → batch → merge` workflow accurately, and the changie.dev quick-start matches what the binary does. Two gaps: the docs do not warn about the missing blank line between sections, and the non-interactive fragment workflow (bypassing `changie new`) is not covered at all — teams automating changie in CI will have to read the fragment `.yaml` schema from source or via trial-and-error.

## Verdict

**Verdict: Recommended with caveats.**

Hands-on use confirms the core workflow is solid: `batch` and `merge` do exactly what they promise, and the tool is genuinely language-agnostic with zero runtime baggage. For a Go or polyglot project that wants fragment-based changelogs without pulling in a language runtime, changie is still the strongest single-binary option.

Two issues deserve mention before adopting: the missing blank-line-between-sections bug is a real daily friction point with the default config, and the interactive-only `changie new` is a gap for CI pipelines. Neither is a blocker — both have workarounds — but teams should know about them up front. Pair changie with a reviewed `.changie.yaml` that fixes the newline template, and the day-to-day experience is smooth. It complements GoReleaser nicely when release publication is handled elsewhere.
