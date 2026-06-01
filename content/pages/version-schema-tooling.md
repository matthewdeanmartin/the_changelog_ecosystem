Title: Version Schemas
Date: 2026-06-01
Slug: version-schema-tooling
sortorder: 7
Summary: Version formats, validation, bump decisions, and release automation tools.

## Purpose

Versioning is separate from changelog writing, but every serious release workflow eventually joins them. This section covers version schemas, validation rules, bump decisions, and tools that coordinate version numbers with changelog entries and release artifacts.

## Core Articles

- [Semantic Versioning and Changelog Workflows]({filename}../articles/semantic-versioning-changelog-workflows.md)
- [Version Schema Survey]({filename}../articles/version-schema-survey.md)
- [Version Bump Decision Rules]({filename}../articles/version-bump-decision-rules.md)
- [Version Validation in Release Pipelines]({filename}../articles/version-validation-release-pipelines.md)
- [semantic-release]({filename}../articles/semantic-release.md)
- [release-please]({filename}../articles/release-please.md)
- [GitVersion]({filename}../articles/gitversion.md)
- [Nerdbank.GitVersioning]({filename}../articles/nerdbank-gitversioning.md)

## Systems To Compare

- SemVer and variants used by npm, Cargo, Go modules, NuGet, Maven, RubyGems, and PyPI.
- Calendar versions and date-based release trains.
- Monorepo versioning: fixed, independent, and package-grouped.
- Automated bumping from commits, fragments, labels, milestones, or manual release plans.
