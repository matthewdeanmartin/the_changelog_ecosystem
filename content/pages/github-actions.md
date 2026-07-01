Title: GitHub Actions
Date: 2026-07-01
Slug: github-actions
sortorder: 8
Summary: Changelog and release-note GitHub Actions, grouped by what they do.

## About This Page

GitHub Actions are a major way changelog and release tooling gets distributed,
but most Marketplace actions are thin wrappers or single-purpose helpers. To keep
the [tool index](../tools/) focused on standalone tools worth adopting, actions
live here on their own page.

Entries are grouped by category. **6 actions** have a full review; the rest
either wrap a tool reviewed elsewhere on the site (follow the link) or are listed
for completeness. Inclusion here is **not** an endorsement.

## Changelog-file managers

- Add Changelog Entry — Programmatically updates a Keep a Changelog 1.0.0 formatted file. ([Marketplace](https://github.com/marketplace/actions/add-changelog-entry))
- Changelog Updater — Inserts release notes into a changelog file. ([Marketplace](https://github.com/marketplace/actions/changelog-updater))
- Changelog Validator — Validates that CHANGELOG.md exists and follows Keep a Changelog format. ([Marketplace](https://github.com/marketplace/actions/changelog-validator))
- Conventional Changelog Reader — Reads data from CHANGELOG.md files following Conventional Changelog output. ([Marketplace](https://github.com/marketplace/actions/conventional-changelog-reader))
- Create release notes from changelog — GitHub Action that extracts release notes from CHANGELOG.md, optionally combines a static header, and writes RELEASE.md. ([Marketplace](https://github.com/marketplace/actions/create-release-notes-from-changelog))
- Extract Release Notes — Extracts release notes from a Keep a Changelog formatted changelog. ([Marketplace](https://github.com/marketplace/actions/extract-release-notes))
- Keep A Changelog - New Release — Promotes [Unreleased] to a versioned section, updates tag links, inserts a new Unreleased. ([Marketplace](https://github.com/marketplace/actions/keep-a-changelog-new-release))
- Keep-a-Changelog Action — Bump/query operations on Keep a Changelog + SemVer files. ([Marketplace](https://github.com/marketplace/actions/keep-a-changelog-action))

## Release-note generators

- **[Release Changelog Builder](../reviews/release-changelog-builder-action/)** — Builds highly customizable release notes / changelog text from GitHub PR and commit data. (861⭐ · [Marketplace](https://github.com/marketplace/actions/release-changelog-builder))
- **[Release Drafter](../reviews/release-drafter/)** — GitHub Action that keeps a draft release updated as PRs merge, grouping release notes by labels and rules. (3,879⭐ · [Marketplace](https://github.com/marketplace/actions/release-drafter))
- **Semantic Release Notes Generator** — Thin wrapper around semantic-release/release-notes-generator; wraps [semantic-release-release-notes-generator](../reviews/semantic-release-release-notes-generator/) ([Marketplace](https://github.com/marketplace/actions/semantic-release-notes-generator))
- Release notes generator (milestone) — Generates release notes when a milestone is closed. ([Marketplace](https://github.com/marketplace/actions/release-notes-generator))
- release-notes-action — Generates release notes like GitHub's release publish panel using the GitHub API. ([Marketplace](https://github.com/marketplace/actions/release-notes-action))

## Conventional Commits generators

- **[Conventional Changelog Action](../reviews/conventional-changelog-action/)** — Bumps version, tags the commit, and generates a changelog from Conventional Commits. (339⭐ · [Marketplace](https://github.com/marketplace/actions/conventional-changelog-action))
- **[release-please](../reviews/release-please/)** — Google release automation that parses Conventional Commits, opens release PRs, updates changelogs, bumps versions, and creates GitHub releases. (2,415⭐ · [Marketplace](https://github.com/marketplace/actions/release-please-action))
- **Generate changelog with git-chglog** — Uses git-chglog to create CHANGELOG.md from SemVer tags and Conventional Commits; wraps [git-chglog](../reviews/git-chglog/) (4⭐ · [Marketplace](https://github.com/marketplace/actions/generate-changelog-with-git-chglog))
- Auto-generate CHANGELOG — Generates CHANGELOG.md from Conventional Commits; can update a branch or open a PR. ([Marketplace](https://github.com/marketplace/actions/auto-generate-changelog))
- Chalogen — CHANGELOG.md generator from commits and tags with Conventional Commits support. ([Marketplace](https://github.com/marketplace/actions/chalogen))
- Changelog from Conventional Commits — Generates changelog between the latest/previous tag or an explicit tag range. ([Marketplace](https://github.com/marketplace/actions/changelog-from-conventional-commits))
- Conventional Bump and Changelog — Fork/variant of Conventional Changelog Action: bump, tag, and generate changelog. ([Marketplace](https://github.com/marketplace/actions/conventional-bump-and-changelog))
- Conventional changelog generator — Generates a changelog from conventional commit history for the latest tag. ([Marketplace](https://github.com/marketplace/actions/conventional-changelog-generator))
- Generic Conventional Changelog — Generates a changelog from conventional commits between two refs. ([Marketplace](https://github.com/marketplace/actions/generic-conventional-changelog))
- Go Changelog Generator — Go-based changelog generator; parses Conventional Commits, supports an unreleased section. ([Marketplace](https://github.com/marketplace/actions/go-changelog-generator))
- rtf42-conventional-changelog-action — Updates a changelog from conventional commits since the latest tag or a tag range. ([Marketplace](https://github.com/marketplace/actions/rtf42-conventional-changelog-action))
- Tag Changelog — On a SemVer tag push, creates changelog text from commits since the previous tag. ([Marketplace](https://github.com/marketplace/actions/tag-changelog))

## Full release automation

- **[Action For Semantic Release](../reviews/semantic-release-action/)** — Runs semantic-release in a workflow; the common entry point for the semantic-release engine. (693⭐ · [Marketplace](https://github.com/marketplace/actions/action-for-semantic-release))
- **go-semantic-release** — Go implementation of semantic-release with optional changelog file output; wraps [semantic-release](../reviews/semantic-release/) (44⭐ · [Marketplace](https://github.com/marketplace/actions/go-semantic-release))
- **Python Semantic Release** — Python-oriented semantic-release: versioning, changelog, and release workflow; wraps [semantic-release](../reviews/semantic-release/) (1,039⭐ · [Marketplace](https://github.com/marketplace/actions/python-semantic-release))

## Changesets ecosystem

- **[Changesets Action](../reviews/changesets-action/)** — Standard Changesets workflow: version packages, edit changelogs, and publish. (1,040⭐ · [Marketplace](https://github.com/marketplace/actions/changeset-action))
- **Changeset Github Release** — Creates GitHub releases from the CHANGELOG.md generated by Changesets; wraps [changesets-changelog-github](../reviews/changesets-changelog-github/) ([Marketplace](https://github.com/marketplace/actions/changeset-github-release))
- **ChangesetsDependencies** — Automates Changeset creation based on dependency changes; wraps [changesets](../reviews/changesets/) (27⭐ · [Marketplace](https://github.com/marketplace/actions/changesetsdependencies))
- Changesets-GH — Runs Changesets version/publish; the version command edits changelogs and deletes changesets. ([Marketplace](https://github.com/marketplace/actions/changesets-gh))
- ChangesetsSnapshot — Snapshot release workflow for Changesets on PRs. ([Marketplace](https://github.com/marketplace/actions/changesetssnapshot))

## Contributing

The catalog is generated from `data/gha_actions.toml`. Add an action there (with
its Marketplace URL and tier) and run `just gha` + `just generate-pages`.
