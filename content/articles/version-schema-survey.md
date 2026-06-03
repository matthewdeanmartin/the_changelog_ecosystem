Title: Version Schema Survey
Date: 2026-06-02
Slug: version-schema-survey
Ecosystem: Cross
Tags: versioning, validation, package-registries
Tool_Status: research
Summary: A survey of version schemes across ecosystems — SemVer, PEP 440, Maven, NuGet, Cargo, RubyGems, Go modules, and CalVer — covering valid syntax, ordering rules, prerelease support, registry constraints, and what release tools need to normalize.

## Overview

Every package registry has a version scheme. The schemes are related but not identical: most borrow from Semantic Versioning but add epoch handling, prerelease label alphabetics, or ecosystem-specific constraints. Release tools that target multiple ecosystems must understand which parts of a version string are universal and which require normalization.

## SemVer 2.0.0

[Semantic Versioning 2.0.0](https://semver.org/) is the reference scheme that most others derive from or align to.

**Format:** `MAJOR.MINOR.PATCH[-prerelease][+buildmetadata]`

- `1.2.3` — release
- `1.2.3-alpha.1` — prerelease with dot-separated identifiers
- `1.2.3+20250601.abc123` — release with build metadata (ignored for ordering)
- `1.2.3-alpha.1+sha.5114f85` — both

**Ordering rules:**
- Numeric release segments compare numerically: `1.9.0 < 1.10.0`.
- A prerelease version is lower than its release: `1.0.0-alpha < 1.0.0`.
- Prerelease identifiers compare left to right: numeric identifiers compare numerically, alphanumeric identifiers compare lexicographically. A numeric identifier always has lower precedence than an alphanumeric one: `1.0.0-1 < 1.0.0-alpha`.
- Build metadata (`+...`) is ignored entirely for ordering and equality.

**Git tag convention:** `v1.2.3` (the `v` prefix is near-universal but not part of the spec).

---

## PEP 440 (Python / PyPI)

[PEP 440](https://peps.python.org/pep-0440/) governs Python package versions on PyPI.

**Format:** `[N!]N(.N)*[{a|b|rc}N][.postN][.devN]`

- `1.2.3` — release
- `1.2.3a1` — alpha (also written `1.2.3.alpha1`, normalized to `1.2.3a1`)
- `1.2.3b2` — beta
- `1.2.3rc1` — release candidate
- `1.2.3.post1` — post-release (e.g. re-uploaded with fixed metadata)
- `1.2.3.dev0` — development snapshot
- `1!2.0.0` — epoch 1 restart (used when a project must renumber)

**Ordering (ascending):** `.devN < aN < bN < rcN < release < .postN`

So: `1.0.dev0 < 1.0a1 < 1.0b1 < 1.0rc1 < 1.0 < 1.0.post1`

**Key differences from SemVer:**
- Epochs (`1!`) allow projects to escape from an existing version sequence; SemVer has no equivalent.
- Post-releases (`1.0.post1`) are higher than the release; SemVer has no equivalent.
- Dev releases (`1.0.dev0`) sort below pre-releases; SemVer pre-releases sort below the release but above nothing.
- Build metadata is not part of PEP 440; `+` is not a valid separator.

**Normalization:** PyPI normalizes many alternate forms: `1.0-alpha1` → `1.0a1`, `1.0.0-final` → `1.0.0`. Tools that generate versions for PyPI must produce normalized forms.

---

## Maven (Java)

Maven's [ComparableVersion](https://maven.apache.org/ref/3.5.2/maven-artifact/apidocs/org/apache/maven/artifact/versioning/ComparableVersion.html) handles a wide range of version strings.

**Format:** Flexible. Common patterns: `1.2.3`, `1.2.3-SNAPSHOT`, `1.2.3-alpha1`, `1.2.3.Final`.

**Well-known qualifiers (case-insensitive), ordered lowest to highest:**
`alpha` = `a` < `beta` = `b` < `milestone` = `m` < `rc` = `cr` < `snapshot` < `""` = `ga` = `final` < `sp`

**Ordering:**
- `1.0-alpha1 < 1.0-beta1 < 1.0-RC1 < 1.0-SNAPSHOT < 1.0 < 1.0.1 < 1.1`
- Unknown qualifiers sort after known ones, alphabetically.
- `SNAPSHOT` sits between release candidates and the final release — it is *not* a published artifact but a placeholder for a moving build.
- Transition between digits and letters is an implicit separator: `1.0alpha1` parses as `[1, 0, alpha, 1]`.

**Registry constraints:** Maven Central rejects SNAPSHOT versions for publication. Snapshots live in a separate snapshot repository. Release versions are immutable once published; re-uploading the same version is rejected.

**Git tag convention:** Varies by project. `1.2.3`, `v1.2.3`, `project-1.2.3`, and `project-parent-1.2.3` are all common.

---

## NuGet (.NET)

NuGet supports two modes: a legacy scheme and [SemVer 2.0.0](https://learn.microsoft.com/en-us/nuget/concepts/package-versioning).

**Format (SemVer 2.0.0 mode, NuGet 4.3.0+):** `MAJOR.MINOR.PATCH[-prerelease][+buildmetadata]`

- `1.2.3-alpha.1` — SemVer 2.0 prerelease with dot separator (numeric part sorts numerically)
- `1.2.3-alpha` — legacy-compatible prerelease (no dot)
- `1.2.3+githash` — build metadata (display only, ignored for ordering)

**Ordering:** SemVer 2.0 rules apply when the version uses dot-separated prerelease labels. `1.0.1-rc.10 > 1.0.1-rc.2` (numeric comparison). Legacy prerelease labels (no dots) sort lexicographically.

**Registry constraints:**
- `1.0` and `1.0.0` are treated as identical by NuGet; the registry will not host both.
- SemVer 2.0 packages (dot prerelease or build metadata) are only visible to NuGet clients 4.3.0 and above; older clients see them as unlisted.
- Build metadata is stripped for package identity; two packages differing only in `+buildmetadata` are the same package.

**Git tag convention:** `v1.2.3` or bare `1.2.3`.

---

## Cargo (Rust / crates.io)

Cargo follows SemVer 2.0.0 closely, with a few registry-level rules.

**Format:** `MAJOR.MINOR.PATCH[-prerelease][+buildmetadata]`

- `1.2.3-alpha.1` — prerelease
- `0.1.0` — pre-1.0 (minor bumps are breaking per Cargo convention)
- `1.2.3+sha.abc123` — build metadata (ignored for dependency resolution)

**Ordering:** Standard SemVer 2.0 rules. Pre-1.0 versions treat minor as the breaking signal by convention (not enforcement).

**Registry constraints:**
- crates.io does not allow yanking to fully remove a version; yank makes it unavailable for new dependency resolution but existing lockfiles can still use it.
- Once published, a version is permanent. Re-publishing the same version number is rejected.
- Build metadata is allowed in `Cargo.toml` but crates.io strips it; `1.0.0+sha.abc` and `1.0.0` are the same version on the registry.

**Git tag convention:** `v1.2.3` (the `v` prefix is the strong convention for all Cargo release tools).

---

## RubyGems (Ruby)

**Format:** A series of dot-separated segments, each either an integer or a string. A version containing any string segment is a prerelease.

- `1.2.3` — release
- `1.0.0.pre` — prerelease
- `1.0.0.rc1` — release candidate (string segment `rc1`)
- `2.0.0.alpha.3` — alpha (two string segments)

**Ordering:**
- Integer segments compare numerically.
- String segments compare alphabetically (Ruby string sort).
- Any prerelease version sorts below the equivalent release: `1.0.0.pre < 1.0.0`.
- Mixed segments: `1.0.a10` parses as `[1, 0, "a", 10]` — the numeric `10` sorts after `9`.

**Registry constraints:** Gems with string segments are prerelease and require `gem install --pre` to install. `gem push` accepts any version that is not already taken.

**Git tag convention:** `v1.2.3` is conventional; some older gems use bare `1.2.3`.

---

## Go Modules

Go's module system has the most unusual versioning rules of any major ecosystem.

**Format:** SemVer `vMAJOR.MINOR.PATCH` (the `v` prefix is mandatory in `go.mod`).

**Major version suffix rule:** For v2 and above, the module path itself must include the major version: `module github.com/example/repo/v2`. This means a single repository can host `v1` and `v2` as distinct module paths. Tools and import paths must change when the major version changes.

**Pre-1.0 convention:** `v0.x.y` modules are not expected to be stable. The module system treats them identically to `v1.x.y` for resolution purposes.

**Pseudo-versions:** When a commit is not tagged, `go get` generates a pseudo-version:

```
v0.0.0-20260601120000-abcdefabcdef
```

Format: `vX.Y.(Z+1)-0.yyyymmddhhmmss-<12-char commit hash>` (or `vX.0.0-...` if there are no prior tags). Pseudo-versions are valid in `go.mod` but should not appear in release tooling.

**Registry constraints:** The Go module proxy (proxy.golang.org) caches module versions immutably. Once fetched, a version cannot be changed at the origin. `GONOSUMCHECK` and `GONOSUMDB` allow bypassing this for private modules.

**Git tag naming:**
- Root module: `v1.2.3`
- Sub-module at `pkg/foo`: `pkg/foo/v1.2.3`
- Major v2+: tag is `v2.0.0` but the module path in `go.mod` must end with `/v2`

---

## CalVer (Calendar Versioning)

[CalVer](https://calver.org/) replaces MAJOR with a date-based segment, making the release date part of the version number.

**Common formats:**

| Format | Example | Used by |
|---|---|---|
| `YY.MM` | `26.6` | Ubuntu (short year, zero-padded month) |
| `YYYY.MM.DD` | `2026.06.02` | Some Python tools |
| `YY.MINOR.MICRO` | `26.0.1` | pip |
| `YYYY-MM-DD` | `2026-06-01` | Stripe API versions |

**Ordering:** Lexicographic date ordering works for zero-padded formats. `26.06 > 26.05` is correct. Non-zero-padded formats (`26.6 < 26.10` is wrong lexicographically but right numerically) require numeric comparison per segment.

**SemVer compatibility:** CalVer is not SemVer. Tools that require SemVer input (semantic-release, release-please) cannot work directly with CalVer output without a custom version strategy.

**Prerelease:** CalVer has no standard prerelease convention. Projects typically append `-alpha`, `-rc.1`, or a `.devN` suffix, borrowing from SemVer or PEP 440.

---

## Normalization Table

The table below summarizes what release tools encounter when targeting multiple ecosystems and what normalization is required.

| Ecosystem | Scheme | `v` prefix in tag | Prerelease format | Build metadata | Epoch/renumber |
|---|---|---|---|---|---|
| npm | SemVer 2.0 | Optional | `-alpha.1` | `+sha` ignored | No |
| PyPI | PEP 440 | No | `a1`, `b1`, `rc1` | Not valid | `1!` epoch |
| Maven Central | Maven Comparable | Optional | `-alpha1`, `-RC1` | No standard | No |
| NuGet | SemVer 2.0 (4.3+) | Optional | `-alpha.1` or `-alpha` | `+sha` display-only | No |
| crates.io | SemVer 2.0 | Required (`v`) | `-alpha.1` | Stripped | No |
| RubyGems | Ruby segments | Conventional | `.pre`, `.rc1` | No | No |
| Go modules | SemVer + path suffix | Required (`v`) | `-alpha.1` | Pseudo-version only | Major path change |
| CalVer | Date-based | Project choice | Project-defined | No | Date is version |

**What release tools must normalize:**

1. **The `v` prefix** — crates.io and Go require it in tags; PyPI versions must not include it in the version string itself.
2. **Prerelease separator** — SemVer uses `-`, PEP 440 uses no separator before `a`/`b`/`rc`, RubyGems uses `.`. Tools targeting multiple registries must translate `1.0.0-alpha.1` to `1.0.0a1` for PyPI and `1.0.0-alpha.1` for crates.io.
3. **SNAPSHOT** — Maven SNAPSHOT versions must never be published to Maven Central; release tools must strip the `-SNAPSHOT` suffix before publishing.
4. **Go major version path** — bumping from `v1` to `v2` requires updating the module path in `go.mod`, not just the version tag. Release tools for Go must handle this.
5. **CalVer with SemVer tools** — tools that require SemVer input need a custom version provider that produces a CalVer output from a date rather than a bump decision.

## Related Articles

- [Semantic Versioning and Changelog Workflows]({filename}semantic-versioning-changelog-workflows.md)
- [Version Bump Decision Rules]({filename}version-bump-decision-rules.md)
- [Version Validation in Release Pipelines]({filename}version-validation-release-pipelines.md)
- [git-cliff]({filename}git-cliff.md)
- [release-please]({filename}release-please.md)
- [cargo-release]({filename}cargo-release.md)
