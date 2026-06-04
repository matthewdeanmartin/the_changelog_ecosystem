Title: Docs Integration Boundaries
Date: 2026-06-01
Slug: docs-integration-boundaries
Ecosystem: Cross
Tags: docs, templates, markdown, release-notes
Tool_Status: research
Summary: Stub article on where changelog tooling ends and documentation tooling begins.

## Overview

Changelog tooling and documentation tooling overlap at exactly one point: both publish prose that describes what changed. They are not the same job. A changelog tool answers "what changed in this release?" from commits, fragments, or pull requests. A documentation site answers "how do I use this software?" and treats the changelog as one page among many.

The practical handoff is a file boundary. The changelog tool owns generation — it writes Markdown (or release-note text) and stops. The documentation site owns rendering — it picks up that Markdown, applies the site theme, builds navigation, and deploys. Neither side should reach across the boundary: a changelog tool that tries to manage site navigation, or a docs build that tries to parse commit history, is doing the other tool's job badly.

The cleanest handoff has three properties. First, a single canonical source: the changelog file (or the release-note body) is generated once and consumed everywhere, rather than maintained separately in the docs tree. Second, a stable path: the docs build expects the changelog at a known location (`CHANGELOG.md`, `docs/changelog.md`, or a `changelog/` directory of per-release files) so the integration does not break when the changelog tool's output moves. Third, idempotent regeneration: re-running the changelog tool produces the same file, so the docs build sees a clean diff rather than spurious churn.

## Integration Patterns

- Generate Markdown into a docs directory.
- Extract one release body for a release page.
- Include changelog fragments in Sphinx, MkDocs, Docusaurus, VitePress, or similar docs builds.
- Publish release notes through forge APIs while linking back to canonical docs.

## Boundary

This site reviews changelog and release tooling, not documentation tooling in general. Sphinx, MkDocs, Docusaurus, and VitePress are large projects with their own audiences; cataloguing their themes, plugins, and search backends would dilute the focus and duplicate documentation that already exists elsewhere.

The line we draw: a docs-related feature is in scope only when it exists to consume changelog or release-note output. That includes a docs plugin that includes changelog fragments at build time, a theme directive that renders a release-notes page, or a forge integration that publishes a release body and links back to canonical docs. It excludes the docs generator's core concerns — navigation, versioned documentation sets, API reference extraction, search — which are about the documentation as a whole, not about changes between releases.

Concretely, a tool earns a review here if removing the changelog/release-note workflow would remove the feature's reason to exist. The Towncrier Sphinx directive qualifies; the Sphinx autodoc extension does not. This keeps the catalogue centred on the handoff itself rather than expanding into a general survey of static-site generators.

## Related Articles

- [Changelog Rendering and Template Engines]({filename}changelog-rendering-template-engines.md)
- [Release Pages and Registry Surfaces]({filename}release-pages-and-registry-surfaces.md)
- [towncrier]({filename}towncrier.md)
- [scriv]({filename}scriv.md)
