Title: All Tools
Date: 2026-05-31
Slug: tools
sortorder: 2
Summary: Full metadata table of every changelog and release tool on our radar.

## Tool Inventory

This table is generated from `data/tools.json`. It tracks every tool we know about,
its current status, and links to its distribution channel.

*Data is updated manually via `make gather` which queries package registries and GitHub.*

| Tool | Ecosystem | Latest Version | Last Release | Stars | Archived? | Distribution |
|------|-----------|---------------|--------------|-------|-----------|-------------|
| keepachangelog-manager | Python | — | — | — | — | [PyPI](https://pypi.org/project/keepachangelog-manager/) |
| git-cliff | Rust | — | — | — | — | [crates.io](https://crates.io/crates/git-cliff) |
| semantic-release | Node | — | — | — | — | [npm](https://www.npmjs.com/package/semantic-release) |
| standard-version | Node | — | — | — | — | [npm](https://www.npmjs.com/package/standard-version) |
| release-it | Node | — | — | — | — | [npm](https://www.npmjs.com/package/release-it) |
| towncrier | Python | — | — | — | — | [PyPI](https://pypi.org/project/towncrier/) |
| changie | Go | — | — | — | — | [GitHub](https://github.com/miniscruff/changie) |
| goreleaser | Go | — | — | — | — | [GitHub](https://github.com/goreleaser/goreleaser) |

*Run `make gather` to populate live metadata. This table will be auto-generated once Phase 2 is complete.*

## How to Add a Tool

If you know of a tool that should be here, open an issue or PR on the
[GitHub repository](https://github.com/matthewdeanmartin/the_changelog_ecosystem).

Include:
- Tool name and repository URL
- Distribution channel (PyPI, npm, crates.io, etc.)
- Brief description of what it does
