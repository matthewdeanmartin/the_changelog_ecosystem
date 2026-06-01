# Maintainer Guide

## Repository Layout

`content/pages/` contains public site pages. Most ecosystem pages are generated
from the metadata files and should not be edited by hand.

`content/articles/` contains review articles. Stubs are generated, but existing
article files are preserved by the normal stub workflow so maintainers can add
real prose without losing work.

`data/tools.json` is the normalized tool metadata consumed by page generation.
Live metadata fields are refreshed by the gather workflow.

`top_prio_tools.toml` is the curated source list for important tools, patterns,
and platform features that belong on the site.

`themes/simple-pages/` contains Pelican templates and CSS.

`rtd/` contains this maintainer documentation and is rendered by Read the Docs
with MkDocs.

## Generated Files

Do not hand-edit these files:

- `content/pages/tools.md`
- `content/pages/{ecosystem}.md`
- live metadata fields in `data/tools.json`

Regenerate them instead:

```bash
just generate-pages
```

Refresh live metadata with:

```bash
just gather
```

## Local Preview

Build the public site:

```bash
just build
```

Serve it locally:

```bash
just devserver
```

Pelican serves the site at `http://localhost:8000` by default.

## Maintainer Docs Preview

Build the Read the Docs content locally:

```bash
uv run mkdocs build
```

Serve the maintainer docs locally:

```bash
uv run mkdocs serve
```
