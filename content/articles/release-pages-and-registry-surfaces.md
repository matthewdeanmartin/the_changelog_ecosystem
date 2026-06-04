Title: Release Pages and Registry Surfaces
Date: 2026-06-01
Slug: release-pages-and-registry-surfaces
Ecosystem: Cross
Tags: release-pages, package-registries, github, gitlab, gitea, forgejo
Tool_Status: research
Summary: Stub article surveying places where changelog and release-note text is published.

## Overview

Changelog and release-note text gets published to many different surfaces, and they are not equivalent. Some surfaces have a first-class "release" object with a title, a tagged version, an editable body, and an API — these are the natural targets for automated release notes. Others only display whatever metadata the package manifest carries, or render a README, with no dedicated place for per-release prose. Knowing which is which determines where a release tool can push notes and where it can only hope a human copies them.

Four broad categories of surface, roughly in order of release-note support:

| Surface category | Release-note support | Typical source of the text |
|---|---|---|
| Source forges (GitHub, GitLab, Gitea, …) | Strong — dedicated Release object, editable body, API | Generated release notes or changelog excerpt |
| Package registries (npm, PyPI, crates.io, …) | Mixed — some show per-version notes, most show manifest + README | Manifest metadata; sometimes a linked changelog |
| Container/OCI registries (Docker Hub, GHCR, …) | Weak — tags and image metadata, occasional description | Image labels; repo description |
| OS / distribution channels (Homebrew, winget, apt, …) | Varies — packaging-format changelog, not upstream prose | Packager-maintained changelog entry |

The distinction that matters most: a **release surface** (a forge Release, a GitLab Release) has somewhere to *put* a paragraph of notes and an API to put it there. A **metadata surface** (most registries) only reflects what is already in the manifest or README, so the best a release tool can do is ensure the manifest links back to a canonical changelog. The sections below enumerate the surfaces; the closing section sorts them by which expose a release-note API.

## Source Forges

- GitHub Releases.
- GitLab Releases.
- Gitea Releases.
- Forgejo and Codeberg Releases.
- Bitbucket Downloads.
- SourceHut project pages and announcement workflows.
- Azure DevOps releases, wiki pages, and pipeline artifacts.
- SourceForge files and project news.
- Launchpad milestones and releases.
- Savannah releases.
- Pagure releases.
- Fossil project releases.

## Package And Distribution Surfaces

- npm, PyPI, crates.io, RubyGems, NuGet, Maven Central, Packagist, Hackage, Hex, CPAN.
- Docker Hub and OCI registries.
- Homebrew, Chocolatey, Scoop, winget, and OS package channels.

## Tooling Question

The practical question for any release tool is: *can I push a release-note body here programmatically, or can I only publish a package and hope the notes show up?* The surfaces sort into three groups.

**Surfaces with a dedicated release-note API** — a release tool can create a release object and set its body directly:

- GitHub Releases (REST/GraphQL; `gh release create`, used by goreleaser, release-please, changelogithub, and many others).
- GitLab Releases (Releases API; `glab release`, `release-cli`).
- Gitea and Forgejo/Codeberg Releases (Gitea-compatible Releases API).
- Azure DevOps releases (REST API), with wiki pages as a secondary target.
- Launchpad milestone/release records and SourceForge project news both expose APIs, though less commonly automated.

**Surfaces that show per-version notes but draw them from the package, not a release API** — the tool sets the text by putting it in the manifest or an accompanying file, and the registry renders it:

- Some registries surface a changelog or per-version description when the manifest points to one (e.g. crates.io and Hex render a linked changelog; NuGet shows release notes from the `<PackageReleaseNotes>` manifest field).
- The text is published as a side effect of publishing the package; there is no separate "edit the release body" call.

**Metadata-and-README-only surfaces** — no per-release prose slot at all; they display the manifest and the README:

- npm, PyPI, RubyGems, Packagist, CPAN, Maven Central (page shows the README/POM metadata; per-version notes rely on a linked changelog).
- Docker Hub and OCI registries (tags, digests, and image labels; the repository description is the only free-text field).
- Homebrew, Chocolatey, Scoop, winget, and OS package channels (any "changelog" is the *packaging* changelog maintained by the packager, distinct from upstream release notes).

The takeaway for release automation: target the forge Release object as the canonical, machine-writable home for release notes, populate the relevant manifest field where the registry supports one (NuGet, npm `homepage`/repository links, etc.), and treat README/metadata surfaces as link targets back to the canonical notes rather than as places to publish prose. The closer a surface is to "just the package manifest," the less a release tool can do beyond making sure the manifest points home.

## Related Articles

- [Docs Integration Boundaries]({filename}docs-integration-boundaries.md)
- [GitHub Automatically Generated Release Notes]({filename}github-automatically-generated-release-notes.md)
- [GitLab Changelogs]({filename}gitlab-changelogs.md)
- [Change Taxonomies Across Tools]({filename}change-taxonomies-across-tools.md)
