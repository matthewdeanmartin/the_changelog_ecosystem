Title: GNU, Gnits, and Historical Change Logs
Date: 2026-06-01
Slug: gnu-gnits-historical-change-logs
Ecosystem: Cross
Tags: gnu, gnits, change-classification, changelog-history
Tool_Status: research
Summary: Stub article on GNU/Gnits-style change logs and their relationship to modern changelog categories.

## Overview

The GNU `ChangeLog` is the ancestor of the modern changelog, and it is a different artifact from what most projects ship today. The GNU Coding Standards define it as a *development log*: a reverse-chronological record where every entry is dated, attributed to an author, and describes changes at the level of files and functions. A canonical entry reads:

```
2026-06-01  Jane Hacker  <jane@example.org>

	* src/parse.c (parse_header): Handle empty input without
	crashing.  Reported by R. Reporter.
	* src/parse.h: Declare parse_header.
```

The audience is other maintainers. The entry answers "which functions changed and why," not "what does this mean for someone upgrading." This is the opposite end of the spectrum from a Keep a Changelog release note, which is grouped by version and written for users.

The **Gnits standard** (the "GNU Nits" conventions, enforced by `automake --gnits`) layers packaging and documentation expectations on top of this. A Gnits-compliant release is expected to ship a standard set of files in the tarball — `NEWS`, `ChangeLog`, `README`, `INSTALL`, `AUTHORS`, `COPYING` — and to keep them distinct. Critically, Gnits separates the two logs:

- **`ChangeLog`** is the file-level development history described above.
- **`NEWS`** is the user-facing summary, grouped by release, listing notable changes in plain language.

That split is the historical root of today's two-document model: a fine-grained machine/maintainer log versus a coarse human-facing release summary. Modern tooling collapsed `ChangeLog` into the git history (where per-file detail lives natively) and promoted `NEWS` into what we now just call the changelog. Understanding the GNU/Gnits origin explains why "the changelog" still carries two conflicting expectations — exhaustive record versus curated summary.

## Contrast Points

- File/function-level development logs versus user-facing release summaries.
- Date-and-author entries versus version-grouped entries.
- Maintenance history versus upgrade guidance.

## Modern Relevance

The GNU `ChangeLog` format is mostly historical, but it has not disappeared, and several situations still require it:

- **GNU and GNU-adjacent projects.** Packages that target inclusion in GNU, or that follow the GNU Coding Standards by policy (glibc, GCC, coreutils, Emacs, and much of the surrounding ecosystem), still maintain a `ChangeLog` and a separate `NEWS`. Contributions to these projects are expected to include a properly formatted ChangeLog entry; some accept the entry in the commit message and generate the file with `git log` formatting tools (`gitlog-to-changelog`).
- **Distribution and packaging expectations.** Downstream packagers (Debian's own `debian/changelog` has a related but distinct format; RPM's `%changelog`) sometimes read or mirror the upstream `ChangeLog`/`NEWS`. A tarball that ships these files in the expected place keeps automated packaging tooling happy.
- **Generated archives.** Many GNU-style projects no longer hand-write `ChangeLog`; they generate it from version control at release time. The file in the tarball is then a build artifact, not a source file — which is why `ChangeLog` often appears in `.gitignore` for these projects and is reconstructed by the release `Makefile`.
- **Reproducibility and provenance.** Where a tarball must be self-describing (no network, no git checkout), the embedded `ChangeLog`/`NEWS` pair is the offline record of what the release contains.

For a new, non-GNU project there is no reason to adopt the file-and-function `ChangeLog` style — git already records that detail far better than a hand-maintained file can. The lasting lesson is the `ChangeLog`/`NEWS` split: keep the exhaustive record in version control and curate a separate, user-facing summary for each release. Modern changelog tools encode exactly that division of labour.

## Related Articles

- [Changelog File Schemas]({filename}changelog-file-schemas.md)
- [Change Taxonomies Across Tools]({filename}change-taxonomies-across-tools.md)
- [keepachangelog]({filename}keepachangelog.md)
