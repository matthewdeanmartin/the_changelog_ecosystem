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
import csv
import html
import re
import sys
import unicodedata
from functools import lru_cache
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from pipeline import tool_store

CONTENT_DIR = Path(__file__).parent / "content"
PAGES_DIR = CONTENT_DIR / "pages"
ARTICLES_DIR = CONTENT_DIR / "articles"
RATINGS_PATH = Path(__file__).parent / "data" / "tool_ratings.csv"

ECOSYSTEM_LABELS = {
    "python": "Python",
    "rust": "Rust",
    "go": "Go",
    "node": "npm",
    "java": "Java",
    "ruby": "Ruby",
    "dotnet": "NuGet",
    "cpp": "C++",
    "c": "C",
    "cross": "Cross-ecosystem",
    "github-action": "GitHub Actions",
    "other": "Other",
}

ECOSYSTEM_SORTORDER = list(ECOSYSTEM_LABELS.keys())
SKIPPED_ECOSYSTEM_PAGES = {"other", "cpp"}

# GitHub Actions get their own dedicated page (generate_gha_page) and must NOT
# appear in the tools.md bucket tables or the per-ecosystem pages, so the flood
# of low-effort actions cannot bury the recommended standalone tools.
GHA_ECOSYSTEM = "github-action"

GHA_CATEGORY_LABELS = {
    "changelog-file-managers": "Changelog-file managers",
    "release-note-generators": "Release-note generators",
    "conventional-commits-generators": "Conventional Commits generators",
    "full-release-automation": "Full release automation",
    "changesets-ecosystem": "Changesets ecosystem",
}

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
        return f'<a href="../reviews/{tool["review_slug"]}/">Review</a>'
    return "—"


def _slug_candidates(tool: dict) -> list[str]:
    candidates: list[str] = []
    for value in [
        tool.get("review_slug"),
        tool.get("id"),
        tool.get("name"),
        tool.get("name", "").lower().replace(" ", "-"),
        re.sub(r"[^a-z0-9-]", "-", tool.get("name", "").lower()),
    ]:
        normalized = _normalize_key(value)
        if normalized and normalized not in candidates:
            candidates.append(normalized)
    return candidates


def _normalize_key(value: str | None) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKC", str(value)).strip().lower()
    normalized = re.sub(r"[^a-z0-9]+", "-", normalized)
    return re.sub(r"-+", "-", normalized).strip("-")


def load_tool_ratings() -> dict[str, dict[str, str]]:
    if not RATINGS_PATH.exists():
        return {}

    with RATINGS_PATH.open(encoding="utf-8-sig", newline="") as handle:
        rows = csv.DictReader(handle)
        ratings: dict[str, dict[str, str]] = {}
        for raw_row in rows:
            row = {
                (key or "").strip(): (value or "").strip()
                for key, value in raw_row.items()
            }
            for alias in (
                _normalize_key(row.get("slug")),
                _normalize_key(row.get("tool_name")),
            ):
                if alias and alias not in ratings:
                    ratings[alias] = row
        return ratings


def _find_rating_row(
    tool: dict, ratings: dict[str, dict[str, str]]
) -> dict[str, str] | None:
    for slug in _slug_candidates(tool):
        row = ratings.get(slug)
        if row:
            return row
    return None


def _bucket_from_rating_row(row: dict[str, str] | None) -> str | None:
    if not row:
        return None

    recommendable = (row.get("recommendable") or "").strip().lower()
    rating = (row.get("rating") or "").strip().lower()

    if recommendable == "no":
        return "not_recommended"
    if rating.startswith("recommended"):
        return "recommended"
    if rating:
        return "situational"
    return None


@lru_cache(maxsize=None)
def _bucket_from_article(review_slug: str) -> str | None:
    if not review_slug:
        return None
    article_path = ARTICLES_DIR / f"{review_slug}.md"
    if not article_path.exists():
        return None

    text = article_path.read_text(encoding="utf-8")
    verdict_match = re.search(r"^\*\*Verdict:\s*(.+?)\*\*$", text, re.MULTILINE)
    if not verdict_match:
        return None

    verdict = verdict_match.group(1).strip().lower()
    if "avoid" in verdict or "not recommended" in verdict:
        return "not_recommended"
    if "recommended" in verdict:
        return "recommended"
    if "situational" in verdict:
        return "situational"
    return None


def _rating_bucket(tool: dict, ratings: dict[str, dict[str, str]]) -> str:
    bucket = _bucket_from_rating_row(_find_rating_row(tool, ratings))
    if bucket:
        return bucket

    article_bucket = _bucket_from_article(tool.get("review_slug") or "")
    if article_bucket:
        return article_bucket

    return "situational"


def sync_reviews(tools: list[dict]) -> tuple[list[dict], int]:
    """Read article frontmatter and update reviewed/review_slug in tools."""
    article_slugs: set[str] = set()
    for article in ARTICLES_DIR.glob("*.md"):
        text = article.read_text(encoding="utf-8")
        slug_match = re.search(r"^Slug:\s*(.+)$", text, re.MULTILINE)
        if slug_match:
            slug = slug_match.group(1).strip()
            article_slugs.add(slug)

    updated = 0
    for tool in tools:
        matched_slug = None
        for slug in _slug_candidates(tool):
            if slug in article_slugs:
                matched_slug = slug
                break

        if matched_slug:
            if tool.get("review_slug") != matched_slug or not tool.get("reviewed"):
                tool["reviewed"] = True
                tool["review_slug"] = matched_slug
                updated += 1
        elif tool.get("reviewed") or tool.get("review_slug"):
            if tool.get("reviewed") or tool.get("review_slug") is not None:
                tool["reviewed"] = False
                tool["review_slug"] = None
                updated += 1
    return tools, updated


def generate_tools_page(tools: list[dict], ratings: dict[str, dict[str, str]]) -> str:
    # GitHub Actions live on their own page; keep them out of the master table.
    tools = [t for t in tools if t.get("ecosystem") != GHA_ECOSYSTEM]

    def eco_sort(t: dict) -> int:
        eco = t.get("ecosystem", "other")
        try:
            return ECOSYSTEM_SORTORDER.index(eco)
        except ValueError:
            return 99

    sorted_tools = sorted(tools, key=lambda t: (eco_sort(t), t.get("name", "").lower()))

    def render_row(tool: dict) -> str:
        eco_label = ECOSYSTEM_LABELS.get(
            tool.get("ecosystem", ""), tool.get("ecosystem", "")
        )
        version = tool.get("latest_version") or "—"
        stars = f"{tool['stars']:,}" if tool.get("stars") is not None else "—"
        dist_link = _dist_link(tool)
        review = _review_link(tool)
        name = tool.get("name", "")
        repo = tool.get("repo")
        safe_name = html.escape(name)
        safe_repo = html.escape(repo or "", quote=True)
        name_cell = (
            f'<a href="{safe_repo}" target="_blank" rel="noopener noreferrer">{safe_name}</a>'
            if repo
            else safe_name
        )
        return (
            "        <tr>"
            f'<td class="tools-table__name">{name_cell}</td>'
            f"<td>{html.escape(eco_label)}</td>"
            f'<td class="tools-table__version">{html.escape(version)}</td>'
            f"<td>{html.escape(stars)}</td>"
            f"<td>{dist_link}</td>"
            f"<td>{review}</td>"
            "</tr>"
        )

    def render_table(bucket_tools: list[dict]) -> str:
        rows = [render_row(tool) for tool in bucket_tools]
        return "\n".join(
            [
                '<table class="tools-table">',
                "    <thead>",
                "        <tr>",
                "            <th>Tool</th>",
                "            <th>Ecosystem</th>",
                "            <th>Latest Version</th>",
                "            <th>Stars</th>",
                "            <th>Distribution</th>",
                "            <th>Review</th>",
                "        </tr>",
                "    </thead>",
                "    <tbody>",
                *rows,
                "    </tbody>",
                "</table>",
            ]
        )

    grouped_tools = {
        bucket: [
            tool for tool in sorted_tools if _rating_bucket(tool, ratings) == bucket
        ]
        for bucket in ("recommended", "situational", "not_recommended")
    }
    tables = "\n\n".join(
        f"## {heading} ({len(grouped_tools[bucket])})\n\n{render_table(grouped_tools[bucket])}"
        for bucket, heading in (
            ("recommended", "Recommended"),
            ("situational", "Situational"),
            ("not_recommended", "Not Recommended"),
        )
    )

    reviewed_count = sum(1 for t in tools if t.get("reviewed"))

    return f"""Title: All Tools
Date: 2026-05-31
Slug: tools
sortorder: 2
Summary: Full metadata table of every tracked changelog and release tool.

## Tool Inventory

{len(tools)} tools tracked &nbsp;·&nbsp; {reviewed_count} reviewed.

{tables}

## How to Add a Tool

Open an issue or PR on the [GitHub repository](https://github.com/matthewdeanmartin/the_changelog_ecosystem).

Include:
- Tool name and repository or distribution URL
- Ecosystem and distribution channel
- One-line description
"""


def generate_ecosystem_page(
    ecosystem: str, tools: list[dict], ratings: dict[str, dict[str, str]]
) -> str:
    label = ECOSYSTEM_LABELS.get(ecosystem, ecosystem)
    eco_tools = [t for t in tools if t.get("ecosystem") == ecosystem]
    if not eco_tools:
        return ""

    reviewed = [t for t in eco_tools if t.get("reviewed")]
    unreviewed = [t for t in eco_tools if not t.get("reviewed")]

    grouped_reviewed: dict[str, list[dict]] = {
        "recommended": [],
        "situational": [],
        "not_recommended": [],
    }
    missing_ratings: list[str] = []
    for tool in reviewed:
        row = _find_rating_row(tool, ratings)
        if not row and not _bucket_from_article(tool.get("review_slug") or ""):
            missing_ratings.append(tool.get("review_slug") or tool.get("name", ""))
        grouped_reviewed[_rating_bucket(tool, ratings)].append(tool)

    if missing_ratings:
        missing = ", ".join(sorted(missing_ratings))
        raise RuntimeError(
            f"Missing tool_ratings.csv rows for reviewed {ecosystem} tools: {missing}"
        )

    sections: list[str] = []
    review_sections = [
        ("recommended", "Recommended"),
        ("situational", "Situational"),
        ("not_recommended", "Not Recommended"),
    ]
    for bucket, heading in review_sections:
        bucket_tools = sorted(
            grouped_reviewed[bucket], key=lambda t: t.get("name", "").lower()
        )
        if not bucket_tools:
            continue
        sections.append(f"## {heading} ({len(bucket_tools)})")
        for t in bucket_tools:
            slug = t.get("review_slug")
            name = t.get("name", "")
            desc = t.get("description") or ""
            link = f"[{name}](../reviews/{slug}/)" if slug else name
            sections.append(f"- **{link}** — {desc}")

    if unreviewed:
        sections.append(f"\n## On the Radar ({len(unreviewed)})")
        sections.append("Tracked tools that do not have a full review article yet.")
        sections.append("")
        for t in sorted(unreviewed, key=lambda t: t.get("name", "").lower()):
            name = t.get("name", "")
            repo = t.get("repo")
            desc = t.get("description") or ""
            archived = " ⚠️ archived" if t.get("archived") else ""
            link = f"[{name}]({repo})" if repo else name
            sections.append(f"- {link}{archived} — {desc}")

    body = "\n".join(sections)

    # Sortorder: put python=10, rust=11, go=12, node=13, etc.
    sortorder = (
        ECOSYSTEM_SORTORDER.index(ecosystem) + 10
        if ecosystem in ECOSYSTEM_SORTORDER
        else 50
    )

    return f"""Title: {label} Tools
Date: 2026-05-31
Slug: {ecosystem}
sortorder: {sortorder}
Summary: Changelog and release management tools for {label}.

{body}
"""


def _gha_marketplace_link(tool: dict) -> str:
    url = tool.get("marketplace_url") or tool.get("repo")
    if url:
        return f'[Marketplace]({url})'
    return "_marketplace link needed_"


def generate_gha_page(
    tools: list[dict], ratings: dict[str, dict[str, str]]
) -> str:
    """Dedicated GitHub Actions catalog, grouped by category, split by tier.

    Tier 1: full reviews (linked). Tier 2: wrappers of a reviewed engine
    (link to that review). Tier 3: catalog line only.
    """
    gha = [t for t in tools if t.get("ecosystem") == GHA_ECOSYSTEM]
    review_slugs = {
        t.get("review_slug")
        for t in tools
        if t.get("reviewed") and t.get("review_slug")
    }

    def stars(t: dict) -> str:
        return f"{t['stars']:,}⭐" if t.get("stars") is not None else ""

    def engine_link(t: dict) -> str:
        wraps = t.get("wraps")
        if wraps and wraps in review_slugs:
            return f"wraps [{wraps}](../reviews/{wraps}/)"
        if wraps:
            return f"wraps `{wraps}`"
        return ""

    sections: list[str] = []
    for category, label in GHA_CATEGORY_LABELS.items():
        cat_tools = sorted(
            (t for t in gha if t.get("gha_category") == category),
            key=lambda t: (t.get("gha_tier", 3), t.get("name", "").lower()),
        )
        if not cat_tools:
            continue
        sections.append(f"## {label}")
        sections.append("")
        for t in cat_tools:
            name = t.get("name", "")
            desc = t.get("description") or ""
            tier = t.get("gha_tier", 3)
            market = _gha_marketplace_link(t)
            star = stars(t)
            meta = " · ".join(x for x in (star, market) if x)
            if tier == 1 and t.get("reviewed") and t.get("review_slug"):
                head = f"**[{name}](../reviews/{t['review_slug']}/)**"
                sections.append(f"- {head} — {desc} ({meta})")
            elif tier == 2:
                eng = engine_link(t)
                base = desc.rstrip(".")
                tail = f"; {eng}" if eng else ""
                sections.append(f"- **{name}** — {base}{tail} ({meta})")
            else:  # tier 3
                sections.append(f"- {name} — {desc} ({market})")
        sections.append("")

    body = "\n".join(sections)
    tier1 = sum(1 for t in gha if t.get("gha_tier") == 1)

    return f"""Title: GitHub Actions
Date: 2026-07-01
Slug: github-actions
sortorder: 8
Summary: Changelog and release-note GitHub Actions, grouped by what they do.

## About This Page

GitHub Actions are a major way changelog and release tooling gets distributed,
but most Marketplace actions are thin wrappers or single-purpose helpers. To keep
the [tool index](../tools/) focused on standalone tools worth adopting, actions
live here on their own page.

Entries are grouped by category. **{tier1} actions** have a full review; the rest
either wrap a tool reviewed elsewhere on the site (follow the link) or are listed
for completeness. Inclusion here is **not** an endorsement.

{body}
## Contributing

The catalog is generated from `data/gha_actions.toml`. Add an action there (with
its Marketplace URL and tier) and run `just gha` + `just generate-pages`.
"""


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Pelican pages from tools.json"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Print output without writing files"
    )
    args = parser.parse_args()

    tools = tool_store.load()
    print(f"Loaded {len(tools)} tools")
    ratings = load_tool_ratings()

    # Sync review status from existing articles
    tools, synced = sync_reviews(tools)
    if synced:
        print(f"Synced {synced} review entries from articles")
        if not args.dry_run:
            tool_store.save(tools)

    # Generate main tools page
    tools_content = generate_tools_page(tools, ratings)
    tools_path = PAGES_DIR / "tools.md"
    if args.dry_run:
        print(f"\n--- {tools_path} ---")
        print(tools_content[:500] + "...")
    else:
        tools_path.write_text(tools_content, encoding="utf-8")
        print(f"Wrote {tools_path}")

    # Generate the dedicated GitHub Actions page
    gha_content = generate_gha_page(tools, ratings)
    gha_path = PAGES_DIR / "github-actions.md"
    if args.dry_run:
        print(f"\n--- {gha_path} (first 300 chars) ---")
        print(gha_content[:300])
    else:
        gha_path.write_text(gha_content, encoding="utf-8")
        print(f"Wrote {gha_path}")

    # Generate per-ecosystem pages (github-action has its own page above)
    ecosystems = sorted({t.get("ecosystem", "other") for t in tools})
    for eco in ecosystems:
        if eco in SKIPPED_ECOSYSTEM_PAGES or eco == GHA_ECOSYSTEM:
            continue
        content = generate_ecosystem_page(eco, tools, ratings)
        if not content:
            continue
        path = PAGES_DIR / f"{eco}.md"
        if args.dry_run:
            print(f"\n--- {path} (first 200 chars) ---")
            print(content[:200])
        else:
            path.write_text(content, encoding="utf-8")
            print(f"Wrote {path}")

    for eco in sorted(SKIPPED_ECOSYSTEM_PAGES - {"other"}):
        path = PAGES_DIR / f"{eco}.md"
        if path.exists():
            if args.dry_run:
                print(f"Would remove {path}")
            else:
                path.unlink()
                print(f"Removed {path}")


if __name__ == "__main__":
    main()
