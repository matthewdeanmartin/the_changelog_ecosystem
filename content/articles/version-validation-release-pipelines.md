Title: Version Validation in Release Pipelines
Date: 2026-06-01
Slug: version-validation-release-pipelines
Ecosystem: Cross
Tags: versioning, validation, ci-cd, package-publishing
Tool_Status: research
Summary: Stub article on validating version numbers before publishing packages and release notes.

## Overview

TODO: Cover CI checks that prevent duplicate versions, invalid registry versions, mismatched tags, missing changelog entries, and accidental downgrades.

## Checks

- Changelog version matches package manifest.
- Git tag matches version.
- Version is greater than the last published version.
- Registry accepts the version syntax.
- Release notes exist before publish.

## Related Tools

- [GitVersion]({filename}gitversion.md)
- [Nerdbank.GitVersioning]({filename}nerdbank-gitversioning.md)
- [release-it]({filename}release-it.md)
