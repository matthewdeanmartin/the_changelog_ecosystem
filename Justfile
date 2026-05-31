# The Changelog Ecosystem — task runner
# Run `just` to see available recipes.
# All Python tasks use `uv run` so no venv activation needed.

set dotenv-load := true   # load .env if present (for GITHUB_TOKEN)
set shell := ["bash", "-euc"]

# ── Default ────────────────────────────────────────────────────────────────────

[private]
default:
    @just --list

# ── Dependency management ──────────────────────────────────────────────────────

# Install / sync Python dependencies
sync:
    uv sync

# ── Data pipeline ──────────────────────────────────────────────────────────────

# Discover new tools from all registries (incremental — never loses existing data)
discover:
    uv run python discover_tools.py

# Discover from a single source (e.g. just discover-source npm)
discover-source source:
    uv run python discover_tools.py --source {{source}}

# Preview what discover would add without writing
discover-dry-run:
    uv run python discover_tools.py --dry-run

# Fetch live metadata (version, date, stars, archived) for all tools
gather:
    uv run python gather_metadata.py

# Re-fetch metadata even if already populated
gather-force:
    uv run python gather_metadata.py --force

# Gather metadata for a single tool (e.g. just gather-one git-cliff)
gather-one name:
    uv run python gather_metadata.py --name {{name}}

# Gather metadata for a single ecosystem (e.g. just gather-eco python)
gather-eco ecosystem:
    uv run python gather_metadata.py --ecosystem {{ecosystem}}

# Preview what gather would update without writing
gather-dry-run:
    uv run python gather_metadata.py --dry-run

# Full pipeline: discover new tools, then gather metadata for all
pipeline: discover gather

# ── Page generation ────────────────────────────────────────────────────────────

# Regenerate all Pelican content pages from data/tools.json
generate-pages:
    uv run python generate_pages.py

# Preview page generation without writing
generate-pages-dry-run:
    uv run python generate_pages.py --dry-run

# ── Site build ─────────────────────────────────────────────────────────────────

# Build the Pelican site
html:
    uv run pelican content -o output -s pelicanconf.py

# Full build: generate pages then build HTML
build: generate-pages html

# Remove generated output
clean:
    rm -rf output/

# Serve with live reload (Ctrl-C to stop)
serve:
    uv run pelican --listen content -o output -s pelicanconf.py

# Serve and auto-regenerate on content changes
devserver:
    uv run pelican --listen --autoreload content -o output -s pelicanconf.py

# Generate production HTML
publish:
    uv run pelican content -o output -s publishconf.py

# ── Full end-to-end ────────────────────────────────────────────────────────────

# Discover + gather + generate pages + build HTML (full pipeline)
all: pipeline generate-pages html
