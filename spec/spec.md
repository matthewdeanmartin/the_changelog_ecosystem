# The Changelog Ecosystem — Project Spec

## Overview

A Pelican-based static review site cataloguing changelog and release management tools
across all major language ecosystems. The goal: help developers find the right tool for
their project, and provide honest signal about tool quality and maintenance health.

Origin: frustration with [keepachangelog-manager](https://github.com/matthewdeanmartin/keepachangelog-manager)
getting no traction despite real effort — let's at least build the map.

---

## Phase 1 — Site Bootstrap (COMPLETE)

### Deliverables

- [x] Pelican site with `uv`-managed dependencies
- [x] Custom theme (`themes/simple-pages`) adapted from `where_is_tkinter`
- [x] Ecosystem-coloured badges in CSS
- [x] `content/pages/`: home, tools index, about
- [x] `content/articles/`: article template + first stub review (keepachangelog-manager)
- [x] `data/tools.json` — seed list of ~10 tools with schema defined
- [x] `Makefile` with `html`, `serve`, `devserver`, `build`, `publish`, `gather`, `generate-pages`
- [x] `pelicanconf.py` + `publishconf.py`
- [x] `pyproject.toml` using `uv`

### Tool JSON Schema

Each entry in `data/tools.json`:

```json
{
  "name": "string — human-readable name",
  "ecosystem": "python | rust | go | node | java | ruby | dotnet | c | cpp",
  "distribution": "pypi | crates.io | npm | maven | rubygems | nuget | github | vcpkg | conan",
  "package_id": "string — ID used to query the registry API",
  "repo": "string — GitHub/GitLab URL",
  "description": "string — one-line description",
  "latest_version": "string | null — populated by gather script",
  "last_release_date": "ISO-8601 string | null",
  "stars": "integer | null",
  "archived": "boolean | null — true if GitHub marks repo archived",
  "reviewed": "boolean",
  "review_slug": "string | null — matches article slug in content/articles/"
}
```

---

## Phase 2 — Tool Discovery & Metadata Gathering

### Goal

Populate `data/tools.json` with a comprehensive list of tools and fill in live metadata
(version, last release, stars, archived status) by querying package registries and GitHub.

### 2.1 — Expand the Tool List

**Strategy:** search each distribution channel for packages related to changelog / release management.

Search terms: `changelog`, `release-notes`, `keepachangelog`, `semantic-release`,
`conventional-commits`, `release-management`, `versioning`.

#### Per-ecosystem sources

| Ecosystem | Primary API | Secondary |
|-----------|-------------|-----------|
| Python | `https://pypi.org/search/?q=changelog` | GitHub topic `keepachangelog` |
| Rust | `https://crates.io/api/v1/crates?q=changelog` | — |
| Go | `https://pkg.go.dev/search?q=changelog` | GitHub topic |
| Node/npm | `https://registry.npmjs.org/-/v1/search?text=changelog` | — |
| Java | Maven Search API `https://search.maven.org/solrsearch/select?q=changelog` | — |
| Ruby | `https://rubygems.org/api/v1/search.json?query=changelog` | — |
| .NET | NuGet Search `https://azuresearch-usnc.nuget.org/query?q=changelog` | — |
| C/C++ | GitHub topics `changelog`, `release-notes` (no universal registry) | vcpkg, Conan |

**Deliverable:** `discover_tools.py` — queries each API, deduplicates, and appends new
tools to `data/tools.json` with `reviewed: false` and null metadata fields.

### 2.2 — Metadata Gathering

**Deliverable:** `gather_metadata.py` — for every tool in `data/tools.json`, fills in:

- `latest_version` — from registry API
- `last_release_date` — from registry API or GitHub Releases API
- `stars` — from GitHub API (`GET /repos/{owner}/{repo}`)
- `archived` — from GitHub API (`repository.archived`)

**Rate limiting:** use `requests` with appropriate delays; cache responses in
`data/cache/` (keyed by URL + date) to avoid re-fetching on every run.

**GitHub token:** read from `GITHUB_TOKEN` env var if present (raises rate limit from
60 to 5000 req/hr).

### 2.3 — Generated Tools Page

**Deliverable:** `generate_pages.py` — reads `data/tools.json` and rewrites
`content/pages/tools.md` with a live-data table sorted by ecosystem then name.
Marks archived tools with a ⚠️ badge. Links to the review article if `reviewed: true`.

---

## Phase 3 — Systematic Reviews

### Goal

Write a review article for every tool in `data/tools.json` that passes a minimum bar
(not archived, has had a release in the past 2 years, has >10 stars or is notable).

### 3.1 — Review Template

Each review is a Pelican article in `content/articles/{slug}.md`.

**Required frontmatter fields:**

```
Title: {tool name}
Date: {review date YYYY-MM-DD}
Slug: {slug matching tools.json review_slug}
Ecosystem: {ecosystem}
Tool_URL: {distribution channel URL}
Tool_Version: {version tested}
Tool_Status: active | archived | unmaintained
Summary: {one-sentence description}
```

**Required sections:**

1. Overview — what problem does it solve?
2. Installation — how to get it
3. What It Does — core features
4. Configuration — complexity and flexibility
5. Output Quality — what the changelog actually looks like
6. Ecosystem Fit — does it feel native?
7. Maintenance Status — GitHub signals
8. Verdict — recommended / situational / avoid

### 3.2 — Review Queue

Priority order for reviews:

**Tier 1 — High-impact, widely used**
- [ ] git-cliff (Rust) — most starred changelog generator
- [ ] semantic-release (Node) — gold standard for automated releases
- [ ] goreleaser (Go) — dominant Go release tool
- [ ] towncrier (Python) — used by major projects (pip, pytest)
- [ ] release-it (Node) — popular generic release tool
- [ ] conventional-changelog-cli (Node)

**Tier 2 — Ecosystem natives**
- [ ] changie (Go)
- [ ] cargo-release (Rust)
- [ ] python-semantic-release (Python)
- [ ] bump2version / bumpversion (Python)
- [ ] tbump (Python)
- [ ] scriv (Python)
- [ ] shipable (Ruby / various)
- [ ] github-changelog-generator (Ruby)
- [ ] GitVersion (.NET)
- [ ] versionize (.NET)
- [ ] jreleaser (Java)

**Tier 3 — Niche / investigate**
- Tools surfaced by Phase 2 discovery

### 3.3 — Review Infrastructure

Once 5+ reviews exist, add:

- A **Comparison** page (`content/pages/comparison.md`) with a feature matrix
- **Ecosystem sub-pages** (`content/pages/python.md`, `nodejs.md`, etc.)  
  listing all tools for that ecosystem with mini-summaries
- A **Verdicts** page summarising all Recommended / Situational / Avoid ratings

### 3.4 — Automation Hooks

`generate_pages.py` should also:

- Update `reviewed: true` and `review_slug` in `tools.json` when an article exists
- Regenerate ecosystem sub-pages from the article frontmatter data
- Flag tools in `tools.json` where `archived: true` and `reviewed: true`
  so the review can be annotated with an archival notice

---

## Technical Notes

### Dependencies

| Package | Purpose |
|---------|---------|
| `pelican` | Static site generator |
| `markdown` | Pelican Markdown support |
| `requests` | Registry / GitHub API calls |
| `tomli` | Parse pyproject.toml in gather scripts |

All managed by `uv`. Run `uv sync` before any `make` target.

### Directory Layout

```
the_changelog_ecosystem/
├── content/
│   ├── pages/          # Static info pages (home, tools, about, ecosystem pages)
│   └── articles/       # Review articles (one per tool)
├── data/
│   ├── tools.json      # Master tool list + metadata
│   └── cache/          # HTTP response cache (gitignored)
├── themes/
│   └── simple-pages/   # Custom Pelican theme
│       ├── templates/
│       └── static/css/
├── spec/
│   └── spec.md         # This file
├── output/             # Generated site (gitignored)
├── pelicanconf.py
├── publishconf.py
├── Makefile
└── pyproject.toml
```

### `.gitignore` additions needed

```
output/
data/cache/
__pycache__/
.venv/
*.pyc
uv.lock   # optional — include if you want reproducible installs
```
