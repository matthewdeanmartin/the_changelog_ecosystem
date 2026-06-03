Title: Conventional Commits, Trailers, and Release Notes
Date: 2026-06-02
Slug: conventional-commits-trailers-release-notes
Ecosystem: Cross
Tags: conventional-commits, git-trailers, release-notes, version-bump
Tool_Status: research
Summary: How Conventional Commits encode change type and breaking-change signals, how Git trailers carry structured metadata, and where the two overlap — including the squash-merge and merge-commit failure modes that break automated release notes.

## Overview

Two mechanisms exist for embedding structured metadata in Git commit messages: **Conventional Commits**, which is a specification for the first line, and **Git trailers**, which are RFC 822-inspired key-value pairs in the footer. They solve overlapping problems, are sometimes confused, and interact in ways that break release automation if not understood.

## Conventional Commits: Structure of the First Line

The [Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/) governs the commit subject line:

```
type(scope): subject
```

- **type** — required. `feat` or `fix` are the two types with defined semantics. Others (`chore`, `docs`, `ci`, `test`, `style`, `refactor`, `perf`, `build`) are conventional extensions from the Angular preset and carry no version-bump meaning in the core spec.
- **scope** — optional. A noun in parentheses indicating which part of the codebase changed: `feat(auth): add OAuth2 login`.
- **subject** — required. A short imperative description: what the commit does, not what it is.

A `!` immediately before the `:` signals a breaking change: `feat!:` or `feat(api)!:`. This is the compact form. The verbose form uses a footer trailer (see below). Both are equivalent per the spec; `BREAKING-CHANGE` and `BREAKING CHANGE` are also synonymous as footer tokens.

### What tools do with the type

Tools map CC types to changelog sections and version bumps:

| Type | Changelog section | Version bump |
|---|---|---|
| `feat` | Features | minor |
| `fix` | Bug Fixes | patch |
| `feat!` / `fix!` / `BREAKING CHANGE:` | Breaking Changes | major |
| `perf` | Performance (sometimes) | patch or none |
| `docs`, `chore`, `ci`, `test`, `style`, `refactor` | Hidden / omitted | none |

The hidden-by-default types are a deliberate design choice: most commits are maintenance noise that readers don't need in release notes.

### What tools do with the scope

Scope is used for two purposes depending on the tool:

- **Grouping**: release-please and git-cliff can group changelog entries by scope, producing subsections like `### auth` within Features.
- **Filtering**: some projects configure certain scopes as hidden (e.g. `deps` scope always hidden even when `feat`).

Scope is not a version-bump signal; only type and breaking-change status drive the bump.

## Git Trailers: Structured Footer Lines

Git trailers are key-value lines in the commit footer, separated from the subject/body by a blank line. The format is `Key: value` (colon + space), loosely inspired by RFC 822 email headers but not actually following that spec.

```
feat(auth): add OAuth2 login

Adds support for OAuth2 providers. The redirect flow requires a callback
URL configured in the app settings.

BREAKING CHANGE: the `auth.token` field is now a JWT; existing sessions
must be re-created.
Co-authored-by: Alice Smith <alice@example.com>
Refs: #412
Signed-off-by: Bob Jones <bob@example.com>
```

Git itself recognizes trailers via `git interpret-trailers` and `git log --format=%(trailers)`. The key must start at the beginning of a line, be followed by `: `, and appear after a blank line separating it from the commit body.

### Well-known trailers

| Trailer | Meaning | Used by release tooling? |
|---|---|---|
| `BREAKING CHANGE:` | CC-specified major bump signal | Yes — semantic-release, release-please, git-cliff |
| `BREAKING-CHANGE:` | Synonym per CC spec | Yes (same tools) |
| `Co-authored-by:` | Credits a co-author | GitHub renders this; changelog tools ignore it |
| `Signed-off-by:` | DCO sign-off | Ignored by changelog tools |
| `Refs:` / `Closes:` / `Fixes:` | Issue references | GitHub/GitLab auto-close linked issues; changelog tools may link them |
| `Reviewed-by:` | Attribution | Ignored by changelog tools |
| Custom trailers | Project-specific metadata | Depends on tool configuration |

### BREAKING CHANGE as a trailer

`BREAKING CHANGE:` is the primary place where breaking-change detail lives. When the `!` suffix form is used alone, the commit description is the only explanation of the break. When the footer form is used, the trailer value can be verbose — a multi-sentence description of the breaking behavior, affected API, and migration path.

```
refactor!: remove deprecated XML import format

BREAKING CHANGE: The `--xml` flag and associated parser have been removed.
Projects using XML input must migrate to the JSON format introduced in v2.0.
See the migration guide at docs/migration.md.
```

Both `!` and `BREAKING CHANGE:` can appear together; neither is redundant — `!` signals to tooling quickly (single regex), while the footer value carries the human-readable explanation.

### Custom trailers for release-note routing

Some projects use custom trailers to carry metadata that Conventional Commits types don't express:

```
fix(payments): correct rounding on VAT calculation

Closes: #891
Release-Note: VAT rounding now rounds half-up instead of half-down; existing
  invoices are not affected.
CVE: CVE-2025-12345
```

git-cliff can extract custom trailers into the template context. semantic-release and release-please do not parse arbitrary trailers by default; extracting them requires a plugin or post-processing step.

## Where They Overlap and Where They Conflict

### Overlap: BREAKING CHANGE is both

`BREAKING CHANGE:` is simultaneously a Git trailer (a key-value footer line) and a Conventional Commits signal. The CC spec defines it as a footer trailer specifically; there is no other place for it. This is intentional — the spec reuses the trailer format rather than inventing a new one.

### Conflict: trailers and `Signed-off-by` collisions

Some organizations use `Signed-off-by` for DCO compliance on every commit. If a commit also has a `BREAKING CHANGE:` footer, the trailers appear in the same block. Git and most tools handle this correctly, but some commit parsers that look for `BREAKING CHANGE:` only in a "clean footer" (no other trailers) may miss it. Test your parser's behavior when multiple trailers coexist.

### Conflict: existing sign-off workflows and CC adoption

Teams with a `Signed-off-by` requirement that predates CC adoption sometimes discover that their commit-message tooling (hooks, lint rules) treats `Signed-off-by` as a trailer footer and enforces that the body ends with a blank line before trailers. Adding `BREAKING CHANGE:` to the same block usually works, but the interaction should be tested explicitly.

## The Squash-Merge and Merge-Commit Failure Modes

These are the most common ways Conventional Commits-based automation breaks silently.

### Squash merge: information loss

When a PR is squash-merged, GitHub/GitLab constructs a new commit message. The default is typically the PR title as the subject and a list of commit messages as the body. Unless the maintainer explicitly edits the squash commit message:

- The carefully written `feat(auth):` subject on the PR's commits is replaced with the PR title, which may not follow CC format.
- The `BREAKING CHANGE:` footer from an inner commit is lost — it does not appear in the squash commit message automatically.
- The squash commit's type defaults to whatever the maintainer writes (or nothing), making `feat` vs `chore` a manual decision.

**Mitigation**: enforce CC format on the PR *title* (via commitlint on the PR title in GitHub Actions), not just on individual commits. When a PR is squash-merged, the PR title becomes the commit subject. Release-please and semantic-release both support this model — they look at the final merged commit, not the individual commits in the PR.

### Merge commit: the `Merge pull request #N` subject

Standard merge commits produce a subject of `Merge pull request #123 from branch/name`. This does not match `type(scope): subject` and is invisible to CC-based tooling. The meaningful commits are in the merge's parents, but tools that scan `git log --first-parent` (the default for many release tools) see only the merge commit.

**Mitigation options:**
1. Use squash merges (loses inner commit granularity but keeps a clean first-parent history).
2. Use rebase merges (each commit must follow CC format; no merge commits).
3. Configure release tools to scan all commits, not just first-parent — but this produces duplicates if a PR's commits are also present in the main branch log.

### Rebase merge: the safest path for CC

Rebase merges replay each PR commit onto the base branch with the original commit message intact. This is the most reliable model for Conventional Commits: every commit in the main-branch log has been individually authored and (if commitlint is enforced) validated before merge. The downside is that squash-loving contributors can no longer use draft commits freely.

## Editor and Template Support

Writing CC-compliant commits is easier with tooling:

- **commitlint** — lint commit messages on commit (husky pre-commit hook) or in CI on PR titles.
- **Conventional Commits VSCode extension** — guided commit message builder.
- **`git commit` templates** — a `.gitmessage` file set via `git config commit.template` pre-fills the subject format and prompts for trailers.
- **cz-git / Commitizen** — interactive CLI prompt that walks contributors through type, scope, subject, body, and breaking-change footer.

A minimal `.gitmessage` template that prompts for trailers:

```
# type(scope): subject
#
# Body (optional): explain WHY, not what
#
# Trailers (optional):
# BREAKING CHANGE: description of breaking behavior
# Refs: #issue-number
# Co-authored-by: Name <email>
```

## What Release Tools Actually Parse

A practical summary of which tools read which signals:

| Signal | semantic-release | release-please | git-cliff | conventional-changelog-cli |
|---|---|---|---|---|
| `feat:` subject | Yes | Yes | Yes | Yes |
| `fix:` subject | Yes | Yes | Yes | Yes |
| `feat!:` subject | Yes | Yes | Yes | Yes |
| `BREAKING CHANGE:` footer | Yes | Yes | Yes | Yes |
| `BREAKING-CHANGE:` footer | Yes | Yes | Yes | Yes |
| `Refs:` / `Closes:` | Via parser plugin | No | Via config | Limited |
| Custom trailers | Via plugin | No | Via `git_trailers` config | No |
| Commit body text | No | No | Via template | No |

Custom trailers in git-cliff are accessible in the Tera template as `commit.footers`, allowing arbitrary trailer values to appear in the rendered changelog.

## Summary

Conventional Commits and Git trailers are complementary. CC defines the structure of the subject line and the semantic meaning of `feat`, `fix`, and `BREAKING CHANGE`. Git trailers provide the footer key-value mechanism that CC's `BREAKING CHANGE:` footer reuses, and that projects can extend with custom keys.

The squash-merge failure mode is the most common source of silent release-note loss: a breaking change written in an inner commit's footer disappears unless the maintainer explicitly carries it into the squash commit message. Enforcing CC format on PR titles and using commitlint in CI — rather than only on individual commits — is the practical defense.

## Related Tools

- [conventional-changelog-cli]({filename}conventional-changelog-cli.md)
- [git-cliff]({filename}git-cliff.md)
- [semantic-release]({filename}semantic-release.md)
- [release-please]({filename}release-please.md)
- [commit-and-tag-version]({filename}commit-and-tag-version.md)
- [Change Taxonomies Across Tools]({filename}change-taxonomies-across-tools.md)
- [Git Trailers as Release Metadata]({filename}git-trailers-release-metadata.md)
- [Version Bump Decision Rules]({filename}version-bump-decision-rules.md)
