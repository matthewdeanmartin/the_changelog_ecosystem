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
