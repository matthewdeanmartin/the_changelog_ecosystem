# The Changelog Ecosystem Maintainer Docs

This documentation is for people maintaining The Changelog Ecosystem site: adding
tools, refreshing metadata, reviewing generated pages, running quality gates, and
publishing the Pelican site to GitHub Pages.

The public site is built from:

- `data/tools.json` for tool metadata.
- `top_prio_tools.toml` for curated tool definitions and priorities.
- `content/articles/*.md` for hand-written reviews and generated review stubs.
- `generate_pages.py` for generated ecosystem and index pages.
- `themes/simple-pages/` for Pelican templates and styling.

The maintainer docs live in `rtd/` and are published separately through Read the
Docs using MkDocs.

## Quick Commands

```bash
uv sync
just gather
just generate-pages
just stubs
just build
just quality
```

Use `just` with no arguments to list available recipes.
