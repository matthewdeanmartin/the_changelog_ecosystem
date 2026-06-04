# Agent Notes — The Changelog Ecosystem

## Environment

- **Python runtime: `uv`.**  All Python must run via `uv run <cmd>` or `uv sync`.
  Do not use bare `python`, `python3`, or `pip` — they will use the wrong environment.
- **Task runner: `just`.**  Run `just` to see all recipes.

## File safety

Some files are **fully generated** and must never be hand-edited:

- `content/pages/tools.md` — rebuilt by `just generate-pages`
- `content/pages/{ecosystem}.md` — rebuilt by `just generate-pages`
- `data/tools.json` (live metadata fields) — updated by `just gather`

Stubs in `content/articles/*.md` are **never overwritten** by `just stubs` (they skip
existing files). Use `just stubs-force` only when you intentionally want to reset a stub.

## Tool ratings

`data/tool_ratings.csv` is the machine-readable index of every reviewed tool:
`tool_name, slug, rating, recommendable, verdict_summary`. It is the fastest way to
answer "is this tool safe to recommend?" without re-reading each article's Verdict.

- `recommendable` is `yes` / `no` / `unknown`. `no` = an Avoid, deprecated,
  unmaintained, legacy-only, or internal-only verdict.
- When you write or change a review's verdict, update this row in the same change.
- **A `recommendable: no` tool stays in its ecosystem tool list and `tools.md`, but must
  not be linked or named from any overview / "see also" / recommender surface** —
  `decision-chart.md`, `decision-helper.md`, topic pages
  (`markup-template-docs-integration.md`, `release-surfaces.md`, …), or
  "Core/Related Articles" lists. Don't point readers at a dead project as an example to
  adopt. Full rule: `CONTRIBUTING.md` → "Recommendable tools and overview pages".

## Workflow

```
uv sync                     # install deps
just gather                 # refresh metadata
just generate-pages         # rebuild tools/ecosystem pages
just stubs                  # create any missing stub articles
just build                  # pelican HTML build
just devserver              # local preview
```

See `CONTRIBUTING.md` for the full contributing workflow.

## Commit messages

Never add `Co-Authored-By` or any LLM attribution trailer to commit messages.
LLMs cannot take responsibility for code, so they should not appear as co-authors.
Write commit messages in keepachangelog style: `Added:`, `Changed:`, `Fixed:`, `Removed:`.
