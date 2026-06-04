Title: Git Tag Schemas for Releases
Date: 2026-06-01
Slug: git-tag-schemas-for-releases
Ecosystem: Cross
Tags: git-tags, versioning, release-notes, validation
Tool_Status: research
Summary: Stub article comparing Git tag naming conventions used by changelog and release tools.

## Overview

A Git tag is the anchor that changelog and release tooling uses to decide what "this release" means. The name and kind of tag determine which commits a tool collects, whether it can verify provenance, and how it groups releases in a monorepo. The conventions are not interchangeable.

| Tag form | Example | When to use |
|---|---|---|
| Plain version | `1.4.0` | Single-package repos; matches the version string in the manifest exactly. Common in Python (PEP 440) projects. |
| `v`-prefixed version | `v1.4.0` | The most widespread convention; the `v` disambiguates a version tag from a branch or arbitrary ref. Default for Go modules, goreleaser, git-cliff, and GitHub's release UI. |
| Package-prefixed monorepo tag | `web-ui@2.1.0`, `core/v0.9.3` | Multiple independently versioned packages in one repository. The prefix scopes the tag so each package has its own release history. |
| Annotated tag | `git tag -a v1.4.0 -m "…"` | Carries a tagger, date, and message object. Release tooling should always create annotated (not lightweight) tags so `git describe` and changelog tools have a reliable anchor and metadata. |
| Signed tag | `git tag -s v1.4.0` | An annotated tag with a GPG/SSH signature. Used where release provenance must be verifiable — distributions, security-sensitive libraries. |
| Prerelease tag | `v2.0.0-rc.1`, `v1.5.0-beta.2` | SemVer prerelease identifiers after a hyphen. Sorts before the final release and signals an unstable channel to tools and registries. |

Two recurring decisions cut across all of these. **Prefix or not:** the `v` prefix is the safest default because it makes version tags trivially distinguishable from other refs and is what most tooling expects out of the box — but it must match what the manifest/registry expects (npm and PyPI publish the bare version, so the tag prefix is purely a VCS convention). **Lightweight or annotated:** always annotated for releases. Lightweight tags are just branch-like pointers with no object of their own; annotated tags give changelog tools a date and message to work from and make `git describe --tags` deterministic.

## Questions

- What tag forms are easiest for tools to discover?
- How do package-scoped tags work in monorepos?
- Which tag metadata belongs in annotated tag messages versus release pages?

## Related Tools

- [git-cliff]({filename}git-cliff.md)
- [git-chglog]({filename}git-chglog.md)
- [release-please]({filename}release-please.md)
