Title: Release Surfaces
Date: 2026-06-01
Slug: release-surfaces
sortorder: 9
Summary: Package registries, source forges, and release-page-like places where changelog text is published.

## Purpose

Release notes rarely live in only one place. A project may publish the same release body to a source forge, a package registry, a documentation site, and a container or operating-system package channel.

This section tracks the release-page-like surfaces that changelog tooling needs to target or at least respect.

## Core Articles

- [Release Pages and Registry Surfaces]({filename}../articles/release-pages-and-registry-surfaces.md)
- [GitHub Automatically Generated Release Notes]({filename}../articles/github-automatically-generated-release-notes.md)
- [GitLab Changelogs]({filename}../articles/gitlab-changelogs.md)
- [glab release]({filename}../articles/glab-release.md)

## Surfaces To Include

- Source forges: GitHub Releases, GitLab Releases, Gitea Releases, Forgejo/Codeberg Releases, Bitbucket Downloads, SourceHut project pages, Azure DevOps releases/wiki pages, SourceForge files/news, Launchpad milestones/releases, Savannah releases, Pagure releases, Fossil releases.
- Package registries: npm, PyPI, crates.io, RubyGems, NuGet, Maven Central, Packagist, Hackage, Hex, CPAN, Docker Hub, OCI registries, Homebrew, Chocolatey, Scoop, winget.
- Distribution pages: language-specific docs pages, generated release announcements, and project websites that mirror the canonical changelog.
