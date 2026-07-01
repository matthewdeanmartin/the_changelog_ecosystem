Here’s a solid seed list for “changelog / release notes / release-management actions in GitHub Actions Marketplace.” I’d hand this to the other LLM and tell it: **research these first before doing open-ended search**.

| Category                  | Marketplace name                                     | Action / repo ID to research                      | Why it matters                                                                                                                               |
| ------------------------- | ---------------------------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Big/common                | **Release Drafter**                                  | `release-drafter/release-drafter`                 | Drafts release notes as PRs are merged; label/category based. ([GitHub][1])                                                                  |
| Big/common                | **Release Please Action**                            | `googleapis/release-please-action`                | Conventional Commits → release PRs, changelog updates, tags/releases. ([GitHub][2])                                                          |
| Big/common                | **Release Changelog Builder**                        | `mikepenz/release-changelog-builder-action`       | Builds release notes / changelog text from GitHub data with customization. ([GitHub][3])                                                     |
| Big/common                | **Conventional Changelog Action**                    | `TriPSs/conventional-changelog-action`            | Bumps version, tags commit, generates changelog from Conventional Commits. ([GitHub][4])                                                     |
| Big/common                | **Action For Semantic Release**                      | `cycjimmy/semantic-release-action`                | Runs `semantic-release`; commonly paired with `@semantic-release/changelog`, `@semantic-release/git`, release-notes generator. ([GitHub][5]) |
| Big/common                | **Changesets Action**                                | `changesets/action`                               | Standard Changesets workflow: version packages, edit changelogs, publish. ([GitHub][6])                                                      |
| Keep a Changelog          | **Keep-a-Changelog Action**                          | likely `thomaseizinger/keep-a-changelog-action`   | Operations on Keep a Changelog + SemVer files: bump/query. ([GitHub][7])                                                                     |
| Keep a Changelog          | **Keep A Changelog - New Release**                   | research marketplace page                         | Converts `[Unreleased]` into a versioned release section, updates tag links, inserts new unreleased section. ([GitHub][8])                   |
| Keep a Changelog          | **Add Changelog Entry**                              | `claudiodekker/changelog-updater` / related       | Programmatically updates Keep a Changelog 1.0.0 formatted files. ([GitHub][9])                                                               |
| Keep a Changelog          | **Extract Release Notes**                            | research marketplace page                         | Extracts release notes from a Keep a Changelog formatted changelog. ([GitHub][10])                                                           |
| Keep a Changelog          | **Create release notes from changelog**              | research marketplace page                         | Extracts GitHub release notes from a Keep a Changelog style changelog. ([GitHub][11])                                                        |
| Keep a Changelog          | **Changelog Validator**                              | `crajapakshe/changelog-validator`                 | Validates `CHANGELOG.md` exists and follows expected Keep a Changelog format. ([GitHub][12])                                                 |
| Conventional Commits      | **Changelog from Conventional Commits**              | research marketplace page                         | Generates changelog between latest/previous tag or explicit tag range. ([GitHub][13])                                                        |
| Conventional Commits      | **Generate Changelog based on Conventional Commits** | research marketplace page                         | Parses Git history and generates human-readable changelog by commit type. ([GitHub][14])                                                     |
| Conventional Commits      | **Auto-generate CHANGELOG**                          | research marketplace page                         | Generates `CHANGELOG.md` automatically from Conventional Commits; can update branch/open PR. ([GitHub][15])                                  |
| Conventional Commits      | **Conventional commits changelog**                   | research marketplace page                         | Generates conventional changelog, supports config, recommended version bump, unreleased tag. ([GitHub][16])                                  |
| Conventional Commits      | **Conventional changelog generator**                 | `quant-eagle/conventional-changelog-generator`    | Generates changelog from conventional commit history for latest tag. ([GitHub][17])                                                          |
| Conventional Commits      | **Generic Conventional Changelog**                   | `dlavrenuek/generic-conventional-changelog`       | Generates changelog from conventional commits between two refs. ([GitHub][18])                                                               |
| Conventional Commits      | **Tag Changelog**                                    | research marketplace page                         | On SemVer tag push, creates changelog text from commits since previous tag. ([GitHub][19])                                                   |
| Conventional Commits      | **Generate changelog with git-chglog**               | `nuuday/...`                                      | Uses `git-chglog`; creates `CHANGELOG.md` from SemVer + Conventional Commits. ([GitHub][20])                                                 |
| Conventional Commits      | **Go Changelog Generator**                           | `somaz94/go-changelog-action`                     | Go-based changelog generator; parses Conventional Commits, supports unreleased section and tag patterns. ([GitHub][21])                      |
| Conventional Commits      | **rtf42-conventional-changelog-action**              | `MultiTheFranky/...`                              | Updates changelog from conventional commits since latest tag or tag range. ([GitHub][22])                                                    |
| Semantic release variants | **Semantic Release Action**                          | research marketplace page                         | Uses `semantic-release` and conventional-changelog packages to generate release notes. ([GitHub][23])                                        |
| Semantic release variants | **Semantic Release Notes Generator**                 | `Fresa/...`                                       | Wrapper around `semantic-release/release-notes-generator`. ([GitHub][24])                                                                    |
| Semantic release variants | **go-semantic-release**                              | `go-semantic-release/action`                      | Semantic release implementation with optional changelog file output. ([GitHub][25])                                                          |
| Semantic release variants | **Python Semantic Release**                          | `python-semantic-release/python-semantic-release` | Python-oriented semantic release action; versioning/changelog/release workflow. ([GitHub][26])                                               |
| Release notes only        | **Release notes generator**                          | likely `metcalfc/changelog-generator`             | Generates release notes when a milestone is closed. ([GitHub][27])                                                                           |
| Release notes only        | **release-notes-action**                             | research marketplace page                         | Generates release notes like GitHub’s release publish panel using GitHub API. ([GitHub][28])                                                 |
| Release notes only        | **metcalfc/changelog-generator**                     | `metcalfc/changelog-generator`                    | Generates release notes for GitHub Releases. ([GitHub][29])                                                                                  |
| Changesets ecosystem      | **Changesets-GH**                                    | research marketplace page                         | Runs Changesets version/publish commands; version command edits changelog and deletes changesets. ([GitHub][30])                             |
| Changesets ecosystem      | **Changeset Github Release**                         | research marketplace page                         | Creates GitHub releases from `CHANGELOG.md` generated by Changesets. ([GitHub][31])                                                          |
| Changesets ecosystem      | **ChangesetsDependencies**                           | `the-guild-org/...`                               | Automates Changesets creation based on dependency changes. ([GitHub][32])                                                                    |
| Changesets ecosystem      | **ChangesetsSnapshot**                               | research marketplace page                         | Snapshot release workflow for Changesets on PRs. ([GitHub][33])                                                                              |
| Smaller/edge              | **Changelog Updater**                                | research marketplace page                         | Inserts release notes into changelog file. ([GitHub][34])                                                                                    |
| Smaller/edge              | **Conventional Changelog Reader**                    | research marketplace page                         | Reads data from `CHANGELOG.md` files following Conventional Changelog output. ([GitHub][35])                                                 |
| Smaller/edge              | **Chalogen**                                         | `AlexxNB/...`                                     | `CHANGELOG.md` generator from commits and tags with conventional commits support. ([GitHub][36])                                             |
| Smaller/edge              | **Conventional Bump and Changelog**                  | `bsord/...`                                       | Fork/variant of Conventional Changelog Action; bump, tag, generate changelog. ([GitHub][37])                                                 |

For the handoff, I’d tell the research LLM to bucket them this way:

1. **Changelog-file managers**: Keep-a-Changelog Action, Keep A Changelog New Release, Add Changelog Entry, Extract Release Notes, Changelog Validator.
2. **Release-note generators**: Release Drafter, Release Changelog Builder, Release notes generator, release-notes-action.
3. **Conventional Commits generators**: Conventional Changelog Action, Release Please, Auto-generate CHANGELOG, Generic Conventional Changelog, Tag Changelog, Go Changelog Generator.
4. **Full release automation**: semantic-release actions, Python Semantic Release, go-semantic-release.
5. **Changesets ecosystem**: Changesets Action, Changesets-GH, Changeset Github Release, ChangesetsDependencies, ChangesetsSnapshot.

The “must research” shortlist is probably: **Release Drafter, Release Please, Release Changelog Builder, Conventional Changelog Action, Changesets Action, semantic-release-action, Keep-a-Changelog Action, Extract Release Notes, Changelog Validator, Auto-generate CHANGELOG**.

[1]: https://github.com/marketplace/actions/release-drafter?utm_source=chatgpt.com "Release Drafter · Actions · GitHub Marketplace"
[2]: https://github.com/marketplace/actions/release-please-action?utm_source=chatgpt.com "release-please-action - GitHub Marketplace"
[3]: https://github.com/marketplace/actions/release-changelog-builder?utm_source=chatgpt.com "Release Changelog Builder · Actions"
[4]: https://github.com/marketplace/actions/conventional-changelog-action?utm_source=chatgpt.com "Conventional Changelog Action - GitHub Marketplace"
[5]: https://github.com/marketplace/actions/action-for-semantic-release?utm_source=chatgpt.com "Action For Semantic Release - GitHub Marketplace"
[6]: https://github.com/marketplace/actions/changeset-action?utm_source=chatgpt.com "Changeset Action - GitHub Marketplace"
[7]: https://github.com/marketplace/actions/keep-a-changelog-action?utm_source=chatgpt.com "Keep-a-Changelog Action - GitHub Marketplace"
[8]: https://github.com/marketplace/actions/keep-a-changelog-new-release?utm_source=chatgpt.com "Keep A Changelog - New Release · Actions"
[9]: https://github.com/marketplace/actions/add-changelog-entry?utm_source=chatgpt.com "Add Changelog Entry · Actions · GitHub Marketplace"
[10]: https://github.com/marketplace/actions/extract-release-notes?utm_source=chatgpt.com "Actions · GitHub Marketplace - Extract Release Notes"
[11]: https://github.com/marketplace/actions/create-release-notes-from-changelog?utm_source=chatgpt.com "Create release notes from changelog · Actions"
[12]: https://github.com/marketplace/actions/changelog-validator?utm_source=chatgpt.com "Changelog Validator · Actions"
[13]: https://github.com/marketplace/actions/changelog-from-conventional-commits?utm_source=chatgpt.com "Changelog from Conventional Commits · Actions"
[14]: https://github.com/marketplace/actions/generate-changelog-based-on-conventional-commits?utm_source=chatgpt.com "Generate Changelog based on Conventional Commits"
[15]: https://github.com/marketplace/actions/auto-generate-changelog?utm_source=chatgpt.com "Auto-generate CHANGELOG · Actions"
[16]: https://github.com/marketplace/actions/conventional-commits-changelog?utm_source=chatgpt.com "conventional commits changelog · Actions"
[17]: https://github.com/marketplace/actions/conventional-changelog-generator?utm_source=chatgpt.com "Conventional changelog generator · Actions"
[18]: https://github.com/marketplace/actions/generic-conventional-changelog?utm_source=chatgpt.com "Generic Conventional Changelog · Actions - Marketplace"
[19]: https://github.com/marketplace/actions/tag-changelog?utm_source=chatgpt.com "Tag Changelog · Actions · GitHub Marketplace"
[20]: https://github.com/marketplace/actions/generate-changelog-with-git-chglog?utm_source=chatgpt.com "Generate changelog with git-chglog · Actions"
[21]: https://github.com/marketplace/actions/go-changelog-generator?utm_source=chatgpt.com "Go Changelog Generator · Actions"
[22]: https://github.com/marketplace/actions/rtf42-conventional-changelog-action?version=v0.0.4&utm_source=chatgpt.com "rtf42-conventional-changelog-action"
[23]: https://github.com/marketplace/actions/semantic-release-action?utm_source=chatgpt.com "Semantic Release Action - GitHub Marketplace"
[24]: https://github.com/marketplace/actions/semantic-release-notes-generator?utm_source=chatgpt.com "Semantic Release Notes Generator · Actions"
[25]: https://github.com/marketplace/actions/go-semantic-release?utm_source=chatgpt.com "go-semantic-release · Actions"
[26]: https://github.com/marketplace/actions/python-semantic-release?utm_source=chatgpt.com "Python Semantic Release · Actions · GitHub Marketplace"
[27]: https://github.com/marketplace/actions/release-notes-generator?utm_source=chatgpt.com "Release notes generator · Actions · GitHub Marketplace"
[28]: https://github.com/marketplace/actions/release-notes-action?utm_source=chatgpt.com "release-notes-action - GitHub Marketplace"
[29]: https://github.com/metcalfc/changelog-generator?utm_source=chatgpt.com "metcalfc/changelog-generator: GitHub Action to ..."
[30]: https://github.com/marketplace/actions/changesets-gh?utm_source=chatgpt.com "Changesets-GH · Actions - Marketplace"
[31]: https://github.com/marketplace/actions/changeset-github-release?utm_source=chatgpt.com "Changeset Github Release · Actions · GitHub Marketplace"
[32]: https://github.com/marketplace/actions/changesetsdependencies?utm_source=chatgpt.com "ChangesetsDependencies · Actions · GitHub Marketplace"
[33]: https://github.com/marketplace/actions/changesetssnapshot?utm_source=chatgpt.com "Actions · GitHub Marketplace - ChangesetsSnapshot"
[34]: https://github.com/marketplace/actions/changelog-updater?utm_source=chatgpt.com "Changelog Updater · Actions · GitHub Marketplace"
[35]: https://github.com/marketplace/actions/conventional-changelog-reader?utm_source=chatgpt.com "Conventional Changelog Reader · Actions"
[36]: https://github.com/marketplace/actions/chalogen?utm_source=chatgpt.com "Chalogen · Actions · GitHub Marketplace"
[37]: https://github.com/marketplace/actions/conventional-bump-and-changelog?utm_source=chatgpt.com "Conventional Bump and Changelog · Actions"
