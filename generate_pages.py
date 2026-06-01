"""
Phase 2.3 / 3.4 — generate Pelican content pages from data/tools.json.

Rewrites:
  - content/pages/tools.md           — full tools table sorted by ecosystem
  - content/pages/{ecosystem}.md     — per-ecosystem pages

Also syncs reviewed/review_slug in tools.json from existing article frontmatter.

Usage:
    uv run python generate_pages.py [--dry-run]
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from pipeline import tool_store

CONTENT_DIR = Path(__file__).parent / "content"
PAGES_DIR = CONTENT_DIR / "pages"
ARTICLES_DIR = CONTENT_DIR / "articles"

ECOSYSTEM_LABELS = {
    "python": "Python",
    "rust": "Rust",
    "go": "Go",
    "node": "Node / npm",
    "java": "Java",
    "ruby": "Ruby",
    "dotnet": ".NET / NuGet",
    "cpp": "C++",
    "c": "C",
    "other": "Other",
}

ECOSYSTEM_SORTORDER = list(ECOSYSTEM_LABELS.keys())

DIST_URLS = {
    "pypi": "https://pypi.org/project/{id}/",
    "crates.io": "https://crates.io/crates/{id}",
    "npm": "https://www.npmjs.com/package/{id}",
    "rubygems": "https://rubygems.org/gems/{id}",
    "nuget": "https://www.nuget.org/packages/{id}/",
    "maven": "https://search.maven.org/artifact/{id}",
    "github": "https://github.com/{id}",
}


def _dist_link(tool: dict) -> str:
    dist = tool.get("distribution", "")
    pkg_id = tool.get("package_id", tool.get("name", ""))
    template = DIST_URLS.get(dist)
    if template:
        url = template.format(id=pkg_id)
        return f'<a href="{url}" target="_blank" rel="noopener noreferrer">{dist}</a>'
    return dist


def _status(tool: dict) -> str:
    if tool.get("archived"):
        return "⚠️ archived"
    return "✅ active"


def _review_link(tool: dict) -> str:
    if tool.get("reviewed") and tool.get("review_slug"):
        return f"[Review](/reviews/{tool['review_slug']}/)"
    return "—"


def sync_reviews(tools: list[dict]) -> tuple[list[dict], int]:
    """Read article frontmatter and update reviewed/review_slug in tools."""
    slug_map: dict[str, str] = {}  # package_id -> slug
    for article in ARTICLES_DIR.glob("*.md"):
        text = article.read_text(encoding="utf-8")
        slug_match = re.search(r"^Slug:\s*(.+)$", text, re.MULTILINE)
        if slug_match:
            slug = slug_match.group(1).strip()
            slug_map[slug] = slug

    updated = 0
    for tool in tools:
        slug = tool.get("review_slug") or tool.get("name", "").lower().replace(" ", "-")
        if (ARTICLES_DIR / f"{slug}.md").exists():
            if not tool.get("reviewed"):
                tool["reviewed"] = True
                tool["review_slug"] = slug
                updated += 1
        elif tool.get("name"):
            # Also check by name match
            safe = re.sub(r"[^a-z0-9-]", "-", tool["name"].lower())
            if (ARTICLES_DIR / f"{safe}.md").exists() and not tool.get("reviewed"):
                tool["reviewed"] = True
                tool["review_slug"] = safe
                updated += 1
    return tools, updated


def generate_tools_page(tools: list[dict]) -> str:
    def eco_sort(t: dict) -> int:
        eco = t.get("ecosystem", "other")
        try:
            return ECOSYSTEM_SORTORDER.index(eco)
        except ValueError:
            return 99

    sorted_tools = sorted(tools, key=lambda t: (eco_sort(t), t.get("name", "").lower()))

    rows = []
    for t in sorted_tools:
        eco_label = ECOSYSTEM_LABELS.get(t.get("ecosystem", ""), t.get("ecosystem", ""))
        version = t.get("latest_version") or "—"
        date = t.get("last_release_date") or "—"
        stars = f"{t['stars']:,}" if t.get("stars") is not None else "—"
        status = _status(t)
        dist_link = _dist_link(t)
        review = _review_link(t)
        name = t.get("name", "")
        repo = t.get("repo")
        name_cell = f'<a href="{repo}" target="_blank" rel="noopener noreferrer">{name}</a>' if repo else name
        rows.append(f"| {name_cell} | {eco_label} | {version} | {date} | {stars} | {status} | {dist_link} | {review} |")

    table = "\n".join([
        "| Tool | Ecosystem | Latest Version | Last Release | Stars | Status | Distribution | Review |",
        "|------|-----------|---------------|--------------|-------|--------|-------------|--------|",
    ] + rows)

    reviewed_count = sum(1 for t in tools if t.get("reviewed"))

    return f"""Title: All Tools
Date: 2026-05-31
Slug: tools
sortorder: 2
Summary: Full metadata table of every changelog and release tool on our radar.

## Tool Inventory

{len(tools)} tools tracked &nbsp;·&nbsp; {reviewed_count} reviewed.
Data refreshed via `just gather`. Run `just generate-pages` to rebuild this page.

{table}

## How to Add a Tool

Open an issue or PR on the [GitHub repository](https://github.com/matthewdeanmartin/the_changelog_ecosystem).

Include:
- Tool name and repository or distribution URL
- Ecosystem and distribution channel
- One-line description
"""


def generate_ecosystem_page(ecosystem: str, tools: list[dict]) -> str:
    label = ECOSYSTEM_LABELS.get(ecosystem, ecosystem)
    eco_tools = [t for t in tools if t.get("ecosystem") == ecosystem]
    if not eco_tools:
        return ""

    reviewed = [t for t in eco_tools if t.get("reviewed")]
    unreviewed = [t for t in eco_tools if not t.get("reviewed")]

    sections = [f"## Reviewed ({len(reviewed)})"]
    for t in sorted(reviewed, key=lambda t: t.get("name", "").lower()):
        slug = t.get("review_slug")
        name = t.get("name", "")
        desc = t.get("description") or ""
        link = f"[{name}](/reviews/{slug}/)" if slug else name
        sections.append(f"- **{link}** — {desc}")

    sections.append(f"\n## On the Radar ({len(unreviewed)})")
    for t in sorted(unreviewed, key=lambda t: t.get("name", "").lower()):
        name = t.get("name", "")
        repo = t.get("repo")
        desc = t.get("description") or ""
        archived = " ⚠️ archived" if t.get("archived") else ""
        link = f"[{name}]({repo})" if repo else name
        sections.append(f"- {link}{archived} — {desc}")

    body = "\n".join(sections)

    # Sortorder: put python=10, rust=11, go=12, node=13, etc.
    sortorder = ECOSYSTEM_SORTORDER.index(ecosystem) + 10 if ecosystem in ECOSYSTEM_SORTORDER else 50

    return f"""Title: {label} Tools
Date: 2026-05-31
Slug: {ecosystem}
sortorder: {sortorder}
Summary: Changelog and release management tools for {label}.

{body}
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Pelican pages from tools.json")
    parser.add_argument("--dry-run", action="store_true", help="Print output without writing files")
    args = parser.parse_args()

    tools = tool_store.load()
    print(f"Loaded {len(tools)} tools")

    # Sync review status from existing articles
    tools, synced = sync_reviews(tools)
    if synced:
        print(f"Synced {synced} review entries from articles")
        if not args.dry_run:
            tool_store.save(tools)

    # Generate main tools page
    tools_content = generate_tools_page(tools)
    tools_path = PAGES_DIR / "tools.md"
    if args.dry_run:
        print(f"\n--- {tools_path} ---")
        print(tools_content[:500] + "...")
    else:
        tools_path.write_text(tools_content, encoding="utf-8")
        print(f"Wrote {tools_path}")

    # Generate per-ecosystem pages
    ecosystems = sorted({t.get("ecosystem", "other") for t in tools})
    for eco in ecosystems:
        if eco == "other":
            continue
        content = generate_ecosystem_page(eco, tools)
        if not content:
            continue
        path = PAGES_DIR / f"{eco}.md"
        if args.dry_run:
            print(f"\n--- {path} (first 200 chars) ---")
            print(content[:200])
        else:
            path.write_text(content, encoding="utf-8")
            print(f"Wrote {path}")


if __name__ == "__main__":
    main()
