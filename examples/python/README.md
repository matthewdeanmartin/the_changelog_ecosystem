# Python tool experiments

Five Python changelog tools, each driven through the tip-calculator life cycle in Docker.
Run any experiment with `make run` from its directory. Artifacts land in `out/`.

## Results (run date: 2026-06-01)

| Tool | Version | Outcome | Headline finding |
|------|---------|---------|-----------------|
| [towncrier](towncrier/) | 24.8.0 | ✅ Full success | **Reference implementation.** News-fragment workflow works end-to-end. `--draft` preview, `git rm` fragment consumption, and `--keep` all behave as documented. Copy this directory's shape for new tools. |
| [keepachangelog](keepachangelog/) | 2.0.0 | ⚠️ Partial | `keepachangelog show Unreleased` crashes with `TypeError: 'NoneType'` when `[Unreleased]` is non-empty. The `release` command works. Primarily a parser/validator library; the CLI is thin. |
| [keepachangelog-manager](keepachangelog-manager/) | 5.2.0 (fork) | ✅ Full success | Uses `--change-type added --message "..."` (not `--section`). `--override-version X.Y.Z --yes` for release. The non-fork (`keepachangelog-manager`) is unmaintained; always use the fork. |
| [scriv](scriv/) | 1.8.0 | ✅ Full success | Fragment tool with `scriv collect`. Config lives in `pyproject.toml` under `[tool.scriv]`. Must `mkdir -p changelog.d` between stages (git drops empty dirs). |
| [reno](reno/) | 4.1.0 | ✅ Full success | YAML-fragment release-notes tool from OpenStack. Must commit before tagging — reno reads git history to attribute notes to releases. `reno report` generates RST by default; Markdown requires config. |

## Recommended by use case

- **Manual Keep-a-Changelog editing with validation:** keepachangelog-manager-fork
- **News-fragment assembly (Python ecosystem default):** towncrier
- **Lightweight fragment tool:** scriv
- **OpenStack / formal release-notes workflow:** reno
- **KAC parser/library use:** keepachangelog (but work around the `show Unreleased` bug)

## Key gotchas

- **towncrier deletes consumed fragments with `git rm`.** Always commit fragments before running `towncrier build`, or the command errors on untracked files.
- **reno: commit before tagging.** reno reads git history to attribute notes to releases. If you tag before committing the note, the note ends up in `[Unreleased]`.
- **scriv: re-`mkdir -p changelog.d`** before each stage — after `scriv collect` empties the directory, git drops it and the next `scriv create` fails.
- **keepachangelog `show Unreleased` crashes** with `TypeError: 'NoneType'` when the `[Unreleased]` section has content. Use `|| true` or catch the error in scripts.
- **Always use keepachangelog-manager-fork** (`pip install keepachangelog-manager-fork`), not `keepachangelog-manager` (unmaintained).
