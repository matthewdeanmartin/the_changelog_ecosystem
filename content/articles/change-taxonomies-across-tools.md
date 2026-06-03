Title: Change Taxonomies Across Tools
Date: 2026-06-02
Slug: change-taxonomies-across-tools
Ecosystem: Cross
Tags: change-classification, conventional-commits, keep-a-changelog, fragments
Tool_Status: research
Summary: How changelog and release tools classify changes — a comparison of Keep a Changelog sections, Conventional Commit types, Towncrier fragment names, Reno note sections, GitHub label categories, and release-please sections.

## Overview

Every changelog tool must answer the same question: what *kind* of change is this? The answers differ substantially across tools, and the differences matter because they determine what version bump is implied, which audience reads which section, and whether a CI gate can check for completeness.

This article maps the standard taxonomies side by side, identifies gaps and overlaps, and recommends a minimal starting taxonomy for projects that want automation without burdening contributors.

## The Core Taxonomies

### Keep a Changelog

[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) defines six change types, ordered by user impact:

| Section | Intended meaning |
|---|---|
| `Added` | New features available to users |
| `Changed` | Changes in existing behavior |
| `Deprecated` | Features to be removed in a future release |
| `Removed` | Features that were deprecated and are now gone |
| `Fixed` | Bug fixes |
| `Security` | Vulnerability disclosures and patches |

These sections are user-facing by design. They say nothing about tests, CI, build scripts, or internal refactors — those changes are simply omitted from the changelog.

### Conventional Commits

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) uses a `type(scope): subject` prefix on each commit message. The specification mandates only `feat` and `fix`; the Angular-derived extension adds:

| Type | Meaning | Appears in changelog? |
|---|---|---|
| `feat` | New feature | Yes — minor bump |
| `fix` | Bug fix | Yes — patch bump |
| `perf` | Performance improvement | Sometimes |
| `refactor` | Code change, no feature or fix | Rarely |
| `docs` | Documentation only | Rarely |
| `style` | Formatting, whitespace | No |
| `test` | Adding or updating tests | No |
| `build` | Build system or dependencies | No |
| `ci` | CI configuration | No |
| `chore` | Catch-all for maintenance tasks | No |

Breaking changes are signaled by appending `!` to the type (e.g. `feat!:`) or by including a `BREAKING CHANGE:` footer trailer. They imply a major version bump regardless of type.

The key insight: Conventional Commits separates *developer-intent classification* (all those types) from *user-visible classification* (only `feat`, `fix`, and breaking changes end up in release notes by default in tools like release-please and git-cliff).

### Towncrier Fragment Types

[Towncrier](https://towncrier.readthedocs.io/en/stable/configuration.html) uses filename suffixes as the fragment type. The defaults are:

| Suffix | Section heading | Notes |
|---|---|---|
| `.feature` | Features | User-visible addition |
| `.bugfix` | Bug Fixes | User-visible fix |
| `.doc` | Improved Documentation | |
| `.removal` | Deprecations and Removals | |
| `.misc` | Misc | No content shown by default |

Custom types are first-class: teams add `[[tool.towncrier.type]]` blocks to define project-specific categories. The file-naming convention (`123.feature`, `456.bugfix`) couples the fragment to an issue number, which Towncrier renders as a link.

### Reno Note Sections

[Reno](https://docs.openstack.org/reno/latest/user/usage.html) uses YAML keys within each note file. The defaults are:

| Key | Section heading | Audience |
|---|---|---|
| `prelude` | (combined preamble) | Release announcement prose |
| `features` | New Features | Users |
| `issues` | Known Issues | Users / operators |
| `upgrade` | Upgrade Notes | Operators / admins |
| `deprecations` | Deprecations | Users / library consumers |
| `critical` | Critical Issues | Operators |
| `security` | Security Issues | All |
| `fixes` | Bug Fixes | Users |
| `other` | Other Notes | Catch-all |

Reno is unique in having `upgrade`, `issues`, and `prelude` — sections that reflect OpenStack's operations-heavy audience. A single note file can contain multiple sections, so one contributor YAML file can simultaneously document a user-facing feature and the upgrade steps it requires.

### GitHub Auto-Generated Release Notes

GitHub's `.github/release.yml` groups merged pull requests by label into categories. There is no standard taxonomy; teams define their own. A common starting point from the GitHub docs:

| Category title | Labels | Notes |
|---|---|---|
| Breaking Changes | `breaking-change`, `semver-major` | Major bump signal |
| Features | `enhancement`, `semver-minor` | New capability |
| Fixes | `bug` | Bug fix |
| Dependencies | `dependencies` | Often Dependabot PRs |
| Other Changes | `*` | Catch-all |

The label approach means the taxonomy lives in the repository's label configuration, not in a spec or tool default. Teams that don't maintain labels consistently get everything in "Other Changes."

### release-please Categories

[release-please](https://github.com/googleapis/release-please) maps Conventional Commit types to changelog sections:

| Changelog section | Commit types |
|---|---|
| `Features` | `feat` |
| `Bug Fixes` | `fix` |
| `Breaking Changes` | `feat!`, `fix!`, `refactor!`, `BREAKING CHANGE:` footer |
| *(hidden by default)* | `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` |

By default, only `feat` and `fix` commits (and breaking variants) produce changelog entries. The rest are silently omitted unless the project enables `include-component-in-tag` or customizes the changelog configuration.

### Changie Kinds

[Changie](https://changie.dev/) ships a Keep a Changelog-aligned default set of "kinds":

| Kind | Auto version bump |
|---|---|
| `Added` | minor |
| `Changed` | minor |
| `Deprecated` | minor |
| `Removed` | major |
| `Fixed` | patch |
| `Security` | patch |

Kinds map directly to KAC sections. The `auto` field on each kind drives version bumping — the highest bump across all unreleased fragments wins. Custom kinds are fully supported.

### Scriv Categories

[Scriv](https://github.com/nedbat/scriv) uses Markdown (or RST) heading names within fragment files as categories. The default configured list is:

```
Added, Changed, Deprecated, Removed, Fixed, Security
```

This is the KAC set verbatim. Scriv copies the heading level and name from the fragment directly into the changelog — it is essentially a KAC pass-through for the category system.

## Comparison Table

The table below maps each taxonomy's terms onto a common set of semantic slots. A dash (—) means the taxonomy has no dedicated term for that slot; it would fall to a catch-all or be omitted.

| Semantic meaning | KAC | Conv. Commits | Towncrier | Reno | GitHub labels | release-please | Changie |
|---|---|---|---|---|---|---|---|
| New user feature | Added | `feat` | `.feature` | `features` | `enhancement` | Features | Added |
| Bug fix | Fixed | `fix` | `.bugfix` | `fixes` | `bug` | Bug Fixes | Fixed |
| Breaking change | Removed / Changed | `!` suffix or `BREAKING CHANGE:` | *(custom)* | `upgrade` | `breaking-change` | Breaking Changes | Removed |
| Deprecation notice | Deprecated | — | `.removal` | `deprecations` | — | — | Deprecated |
| Security fix | Security | — | *(custom)* | `security` | — | — | Security |
| Behavior change | Changed | `refactor` | *(custom)* | — | — | — | Changed |
| Performance | — | `perf` | *(custom)* | — | — | — | — |
| Documentation | — | `docs` | `.doc` | — | `documentation` | — | — |
| Upgrade / migration | — | — | *(custom)* | `upgrade` | — | — | — |
| Known issues | — | — | — | `issues` | — | — | — |
| Build / CI / chore | — | `build`, `ci`, `chore` | `.misc` | `other` | — | — | — |

Key observations:

1. **KAC, Changie, and Scriv converge** on the same six human-visible sections. They disagree only on heading level and formatting details.
2. **Conventional Commits has the richest developer taxonomy** but the narrowest default changelog taxonomy — most types are intentionally hidden from release notes.
3. **Reno has the most operator-oriented taxonomy** with `upgrade`, `issues`, `critical`, and `prelude` as dedicated sections absent from every other system.
4. **Breaking changes are handled inconsistently.** KAC uses `Removed` or `Changed`; Conventional Commits uses a footer or `!` suffix; Changie encodes it in the `Removed` kind; GitHub and release-please give it a dedicated section.
5. **Security has consistent support** across KAC-derived tools and Reno, but is absent from the default Conventional Commits changelog output.

## Why the Gaps Exist

The taxonomies reflect different mental models of who the changelog is for:

- **KAC, Changie, Scriv** are written for *users of a library or application* — people upgrading a dependency or reading release notes to understand what changed.
- **Conventional Commits / release-please** are written for *developers on a team* — commit messages are the source of truth, and most commit types are maintenance noise that readers don't need.
- **Reno** is written for *operators and platform teams* — upgrades have operational consequences, and the audience needs explicit migration guidance.
- **GitHub auto-notes** are written for *project contributors and followers* — PR titles and labels are the source material, so the taxonomy is whatever the team's label discipline produces.

## Decision Rule: A Minimal Default Taxonomy

For a project starting fresh that wants automation without forcing contributors to learn a large category system, the following five categories cover the most common cases:

| Category | Meaning | Version bump |
|---|---|---|
| `Added` | New feature or behavior | minor |
| `Fixed` | Bug fix | patch |
| `Changed` | Behavior change or improvement | minor |
| `Security` | Vulnerability fix | patch |
| `Removed` | Breaking removal or API change | major |

This is the KAC set minus `Deprecated`. Adding `Deprecated` back is worthwhile once the project has a deprecation policy; without one, it accumulates stale entries.

**Avoid** adding `Chores`, `Docs`, `Tests`, or `Internal` categories to a user-facing changelog. They add noise for the wrong audience. If the team needs an audit trail for those changes, a separate release-engineering log or the git log itself is more appropriate.

**For Conventional Commits projects**, accept that only `feat`, `fix`, and breaking changes drive the public changelog. Configure git-cliff, semantic-release, or release-please with an explicit section mapping so that `security`-type commits (often written as `fix(security):` with a `CVE` note) surface correctly rather than silently merging into generic bug fixes.

**For fragment-based tools** (Towncrier, Reno, Changie, Scriv), start with the defaults and only add custom categories when the team consistently has content that fits nowhere else. Custom categories that are rarely used become noise in the changelog and confusion for contributors.

## Related Articles

- [Keep a Changelog]({filename}keepachangelog.md)
- [towncrier]({filename}towncrier.md)
- [reno]({filename}reno.md)
- [changie]({filename}changie.md)
- [scriv]({filename}scriv.md)
- [release-please]({filename}release-please.md)
- [GitHub Automatically Generated Release Notes]({filename}github-automatically-generated-release-notes.md)
- [Conventional Commits, Trailers, and Release Notes]({filename}conventional-commits-trailers-release-notes.md)
- [Version Bump Decision Rules]({filename}version-bump-decision-rules.md)
