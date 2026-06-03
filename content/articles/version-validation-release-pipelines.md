Title: Version Validation in Release Pipelines
Date: 2026-06-02
Slug: version-validation-release-pipelines
Ecosystem: Cross
Tags: versioning, validation, ci-cd, package-publishing
Tool_Status: research
Summary: The CI checks that prevent bad releases — duplicate versions, mismatched tags, downgrade accidents, registry-syntax rejections, and missing changelog entries — and which tools handle each one.

## Overview

A release pipeline can fail in at least five distinct version-related ways: publishing a version that already exists, publishing a version the registry rejects, tagging a version that doesn't match the manifest, publishing without release notes, or accidentally downgrading a version. Each failure mode has a different root cause and a different point in the pipeline where it should be caught.

This article maps each check, explains where it should run, and identifies which tools perform it automatically versus which require custom scripting.

## The Five Failure Modes

### 1. Duplicate Version

**What goes wrong:** A version number is published that already exists in the registry. Most registries treat this as a hard error (crates.io, PyPI, npm), some as a warning (Maven with non-SNAPSHOT releases), and some allow re-publishing (RubyGems with yanked versions).

**Where to catch it:** Before `publish`, after the version is known but before the upload. Running a dry-run publish or a registry API check is sufficient.

**Tool coverage:**

| Tool | How it handles this |
|---|---|
| `cargo publish --dry-run` | Warns (not errors) when version already exists on crates.io |
| `cargo-release` | Checks version existence before tagging; aborts if already published |
| `npm publish --dry-run` | Does not check existing versions; fails at upload |
| `semantic-release` | Reads the last release from git tags; skips release if no new commits since last tag |
| `release-please` | Will not open a release PR if the proposed version already has a tag |
| `release-it` | Skips publish if git tag already exists (configurable) |
| PyPI / `twine upload` | Rejects at upload; no pre-check in twine by default |
| Custom script | `curl https://registry.npmjs.org/pkg/version` → 404 means safe |

**Best practice:** Check the registry before tagging. A tag is harder to undo than a failed upload.

---

### 2. Registry-Invalid Version Syntax

**What goes wrong:** The version string in the manifest is syntactically valid locally (e.g. passes `semver.parse()`) but is rejected by the target registry's stricter rules. Examples:

- Publishing `1.0.0+build.sha` to npm — build metadata is stripped and may collide with a plain `1.0.0`.
- Publishing `1.0.0-alpha.01` to crates.io — leading zeros in numeric prerelease identifiers are rejected by strict SemVer parsers.
- Publishing `1.0.0.post1` to crates.io — PEP 440 post-release syntax is not valid SemVer.
- Publishing a NuGet SemVer 2.0 package (`1.0.0-alpha.1`) to a server that only understands legacy NuGet versioning.

**Where to catch it:** During CI, before any upload. This requires knowing the target registry's parser, not just a generic SemVer validator.

**Tool coverage:**

| Tool | Coverage |
|---|---|
| `cargo publish` | Validates SemVer 2.0 compliance before upload |
| `twine check` | Checks wheel/sdist metadata; does not validate PEP 440 version syntax specifically |
| `npm pack` + `npm publish` | Validates SemVer 2.0 at pack time; build metadata causes a warning, not error |
| GitVersion | Generates version strings; can be configured to output ecosystem-specific formats |
| Nerdbank.GitVersioning | Generates version for .NET; outputs valid NuGet versions by design |
| Custom script | Parse the version with the registry's own library (e.g. `packaging.version.Version` for PyPI) |

**Best practice:** Validate the version string with the target registry's own parser, not a generic one. PyPI uses `packaging.version.Version`; npm uses the `semver` package; crates.io uses Cargo's own `semver` crate.

---

### 3. Tag / Manifest Mismatch

**What goes wrong:** The Git tag pushed (`v1.2.3`) doesn't match the version in the package manifest (`package.json`, `Cargo.toml`, `pyproject.toml`, etc.), or multiple manifest files disagree with each other in a monorepo.

**Symptoms:**
- A `v1.2.3` tag on a commit where `package.json` still says `"version": "1.2.2"`.
- `Cargo.toml` says `1.2.3` but the crate published from that commit was `1.2.3` — seemingly fine, until you notice the changelog still says `1.2.2`.
- A monorepo where `packages/core/package.json` was bumped but `packages/cli/package.json` was not.

**Where to catch it:** In CI immediately after the version bump commit, before tagging.

**Tool coverage:**

| Tool | How it handles this |
|---|---|
| `semantic-release` | Updates manifest files as part of the release; tag and manifest are always consistent |
| `release-please` | Updates all configured version files in the release PR; mismatch is visible at review time |
| `cargo-release` | Updates `Cargo.toml`, commits, and tags in one command |
| `release-it` | Updates configured version files before tagging |
| GitVersion | Derives the version from git history; manifest files are written from the derived version |
| Custom script | `grep "version" Cargo.toml | grep "$(git describe --tags --abbrev=0)"` pattern |

**Best practice:** Use a release tool that updates manifests and creates the tag in a single atomic step. Manual processes (bump, commit, push, then tag separately) introduce a window where they can diverge.

---

### 4. Accidental Downgrade

**What goes wrong:** The proposed version is lower than the last published version. This can happen when:
- A branch with an old version is mistakenly merged and the release runs from it.
- A developer manually edits a version file and types the wrong number.
- A monorepo automation bumps a package to `1.0.1` when `1.1.0` was already published.

**Where to catch it:** Before tagging, by comparing the proposed version against the highest existing tag or the registry's latest version.

**Tool coverage:**

| Tool | Coverage |
|---|---|
| `semantic-release` | Derives version from commit history; cannot produce a downgrade unless history is rewritten |
| `release-please` | Reads the manifest and only proposes increments; cannot produce a downgrade from its own PR |
| GitVersion | Calculates version from git tags; a branch with an old base produces a lower version that CI can detect |
| `cargo-release` | Does not explicitly check for downgrades; validates SemVer format only |
| Custom script | Compare `proposed_version > latest_git_tag` with a semver library |

**Best practice:** Add an explicit downgrade check in CI: fetch the latest git tag, parse both versions, and fail if `proposed < latest`. This is a two-line script in any language with a semver library and catches the failure before the registry does (with a worse error message).

---

### 5. Missing Release Notes / Changelog Entry

**What goes wrong:** A version is tagged and published but there is no corresponding changelog entry or release notes file. Users and downstream consumers see a version bump with no explanation.

**Where to catch it:** Pre-release, after the version is known. The check is: "does a changelog entry exist for this version?"

**Tool coverage:**

| Tool | How it handles this |
|---|---|
| `keepachangelog show <version>` | Exits non-zero if version heading is missing from `CHANGELOG.md` |
| `towncrier build` | Fails if no fragments exist and `--draft` mode doesn't suppress the requirement |
| `changie latest` | Returns exit code 1 if no unreleased fragments exist |
| `reno report` | Always generates a report; does not fail on empty sections |
| `semantic-release` | Will not produce a release if no releasable commits exist |
| `release-please` | Will not open a release PR if no releasable commits have merged |
| Custom script | Parse `CHANGELOG.md` for `## [proposed_version]` heading presence |

**Best practice:** For KAC-format changelogs, run `keepachangelog show <proposed_version>` as a required CI step before publish. For fragment-based tools, the fragment-exists check at PR time (see [Changelog Validation Boundaries]({filename}changelog-validation-boundaries.md)) means this check is already done incrementally.

---

## Pipeline Placement

The right time for each check:

| Check | When to run | Hard fail? |
|---|---|---|
| Duplicate version (registry) | Before `publish`, after version is known | Yes |
| Registry-invalid syntax | At CI start, when manifest is read | Yes |
| Tag / manifest mismatch | After bump commit, before tagging | Yes |
| Accidental downgrade | After bump commit, before tagging | Yes |
| Missing release notes | After bump commit, before tagging | Yes |

All five checks should fail hard and fast. A release that passes these checks and then fails at the registry level is a partially-completed release — the tag exists but the package does not — which is expensive to clean up.

## Tool-Owned vs. Custom Scripted

**Automatically handled by the release tool (no script needed):**

- semantic-release and release-please: duplicate version, tag/manifest consistency, and missing-notes (no releasable commits → no release).
- cargo-release: duplicate version (aborts before publish), tag/manifest consistency.
- GitVersion / Nerdbank.GitVersioning: registry-invalid syntax (they generate ecosystem-correct version strings by design).

**Requires a custom CI step:**

- Accidental downgrade (all tools — none check this explicitly by default).
- Registry-invalid syntax when the tool is not ecosystem-aware (e.g. a generic CI script pushing to PyPI).
- Missing changelog entry when using an accumulated `CHANGELOG.md` with a non-automated release flow.

A minimal downgrade guard for any CI system:

```bash
LATEST_TAG=$(git tag --list 'v*' --sort=-version:refname | head -1)
PROPOSED=$(cat VERSION)  # or grep from Cargo.toml / package.json
if [ -n "$LATEST_TAG" ]; then
  python3 -c "
import sys
from packaging.version import Version
latest = Version('${LATEST_TAG#v}')
proposed = Version('$PROPOSED')
if proposed <= latest:
    print(f'Downgrade detected: {proposed} <= {latest}', file=sys.stderr)
    sys.exit(1)
"
fi
```

## Summary

Most release automation tools handle the common cases (duplicate version, tag/manifest consistency, missing releasable commits) when they own the entire release flow. The gaps are:

1. **Accidental downgrade** — no mainstream tool checks this by default; add a custom script.
2. **Registry-invalid syntax** — only caught if the tool is ecosystem-aware; validate explicitly against the target registry's parser.
3. **Missing changelog for manual release flows** — add `keepachangelog show <version>` or equivalent as a required CI step.

## Related Tools

- [GitVersion]({filename}gitversion.md)
- [Nerdbank.GitVersioning]({filename}nerdbank-gitversioning.md)
- [release-it]({filename}release-it.md)
- [semantic-release]({filename}semantic-release.md)
- [release-please]({filename}release-please.md)
- [cargo-release]({filename}cargo-release.md)
- [Version Schema Survey]({filename}version-schema-survey.md)
- [Changelog Validation Boundaries]({filename}changelog-validation-boundaries.md)
