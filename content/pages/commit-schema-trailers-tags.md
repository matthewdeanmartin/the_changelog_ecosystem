Title: Commit Message Schemas
Date: 2026-06-01
Slug: commit-schema-trailers-tags
sortorder: 5
Summary: Commit message conventions, Git trailers, Git tag naming, and release-note extraction.

## Purpose

This section covers the commit-side inputs that changelog tools consume: Conventional Commits, Git trailers, Gitmoji, annotated tags, tag naming, and project-specific release markers.

The central question is practical: what information can a tool reliably infer from commit history, and where does that inference become too lossy for a good changelog?

## Core Articles

- [Conventional Commits, Trailers, and Release Notes]({filename}../articles/conventional-commits-trailers-release-notes.md)
- [Gitmoji and Emoji Commit Taxonomies]({filename}../articles/gitmoji-emoji-commit-taxonomies.md)
- [Git Trailers for Release Metadata]({filename}../articles/git-trailers-release-metadata.md)
- [Git Tag Schemas for Releases]({filename}../articles/git-tag-schemas-for-releases.md)
- [conventional-changelog]({filename}../articles/conventional-changelog.md)
- [git-cliff]({filename}../articles/git-cliff.md)

## Questions To Answer

- Which conventions are human-friendly enough for everyday commits?
- Which conventions survive squash merges, merge commits, and generated dependency bumps?
- Which metadata belongs in a commit subject, a body footer, a tag, or a release workflow?
