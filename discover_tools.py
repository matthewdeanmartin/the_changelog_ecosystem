"""
Phase 2.1 — discover changelog/release tools from package registries.

Queries PyPI, crates.io, npm, Maven Central, RubyGems, NuGet, and GitHub topics,
then merges new entries into data/tools.json (never overwrites existing data).

Usage:
    uv run python discover_tools.py [--dry-run]
"""
from __future__ import annotations

import argparse
import os
import sys
import time

import requests

sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))
from pipeline import http_cache, tool_store

SEARCH_TERMS = [
    "changelog",
    "release-notes",
    "keepachangelog",
    "conventional-commits",
    "release-management",
    "semantic-release",
]

# GitHub topics to search
GITHUB_TOPICS = [
    "changelog",
    "keepachangelog",
    "release-notes",
    "conventional-commits",
    "semantic-release",
    "changelog-generator",
]


def _session() -> requests.Session:
    s = requests.Session()
    token = os.environ.get("GITHUB_TOKEN", "")
    if token:
        s.headers["Authorization"] = f"Bearer {token}"
    s.headers["User-Agent"] = "the-changelog-ecosystem/1.0 (https://github.com/matthewdeanmartin)"
    return s


# ── Per-registry discovery ─────────────────────────────────────────────────────

def discover_pypi(session: requests.Session) -> list[dict]:
    found = []
    for term in SEARCH_TERMS:
        data = http_cache.get(
            "https://pypi.org/search/",
            params={"q": term, "format": "application/json"},
            session=session,
        )
        if not data or "results" not in data:
            # PyPI JSON search isn't public; fall back to simple search scrape via XML
            continue
        for pkg in data.get("results", []):
            found.append(_pypi_entry(pkg["name"], pkg.get("description", "")))
    # PyPI doesn't have a clean JSON search API; use the XML feed approach
    for term in SEARCH_TERMS:
        data = http_cache.get(
            "https://pypi.org/search/",
            params={"q": term, "o": "", "c": ""},
            headers={"Accept": "application/json"},
            session=session,
        )
        # Also try XMLRPC (returns list of package names)
        try:
            import xmlrpc.client
            client = xmlrpc.client.ServerProxy("https://pypi.org/pypi")
            hits = client.search({"name": term, "summary": term}, "or")
            for h in hits[:30]:
                found.append(_pypi_entry(h["name"], h.get("summary", "")))
        except Exception:
            pass
        time.sleep(0.5)
    return _dedup(found)


def _pypi_entry(name: str, description: str) -> dict:
    return {
        "name": name,
        "ecosystem": "python",
        "distribution": "pypi",
        "package_id": name,
        "repo": None,
        "description": description[:120] if description else "",
        "latest_version": None,
        "last_release_date": None,
        "stars": None,
        "archived": None,
        "reviewed": False,
        "review_slug": None,
    }


def discover_crates(session: requests.Session) -> list[dict]:
    found = []
    for term in SEARCH_TERMS:
        data = http_cache.get(
            "https://crates.io/api/v1/crates",
            params={"q": term, "per_page": 25},
            session=session,
        )
        if not data:
            continue
        for c in data.get("crates", []):
            found.append({
                "name": c["id"],
                "ecosystem": "rust",
                "distribution": "crates.io",
                "package_id": c["id"],
                "repo": c.get("repository") or None,
                "description": (c.get("description") or "")[:120],
                "latest_version": c.get("newest_version"),
                "last_release_date": c.get("updated_at", "")[:10] or None,
                "stars": None,
                "archived": None,
                "reviewed": False,
                "review_slug": None,
            })
        time.sleep(1)  # crates.io rate limit: 1 req/s
    return _dedup(found)


def discover_npm(session: requests.Session) -> list[dict]:
    found = []
    for term in SEARCH_TERMS:
        data = http_cache.get(
            "https://registry.npmjs.org/-/v1/search",
            params={"text": term, "size": 25},
            session=session,
        )
        if not data:
            continue
        for obj in data.get("objects", []):
            pkg = obj.get("package", {})
            links = pkg.get("links", {})
            found.append({
                "name": pkg.get("name", ""),
                "ecosystem": "node",
                "distribution": "npm",
                "package_id": pkg.get("name", ""),
                "repo": links.get("repository") or links.get("homepage") or None,
                "description": (pkg.get("description") or "")[:120],
                "latest_version": pkg.get("version"),
                "last_release_date": (pkg.get("date") or "")[:10] or None,
                "stars": None,
                "archived": None,
                "reviewed": False,
                "review_slug": None,
            })
        time.sleep(0.3)
    return _dedup(found)


def discover_rubygems(session: requests.Session) -> list[dict]:
    found = []
    for term in SEARCH_TERMS:
        data = http_cache.get(
            "https://rubygems.org/api/v1/search.json",
            params={"query": term},
            session=session,
        )
        if not data:
            continue
        for gem in data[:25]:
            found.append({
                "name": gem.get("name", ""),
                "ecosystem": "ruby",
                "distribution": "rubygems",
                "package_id": gem.get("name", ""),
                "repo": gem.get("source_code_uri") or gem.get("homepage_uri") or None,
                "description": (gem.get("info") or "")[:120],
                "latest_version": gem.get("version"),
                "last_release_date": (gem.get("version_created_at") or "")[:10] or None,
                "stars": None,
                "archived": None,
                "reviewed": False,
                "review_slug": None,
            })
        time.sleep(0.3)
    return _dedup(found)


def discover_nuget(session: requests.Session) -> list[dict]:
    found = []
    for term in SEARCH_TERMS:
        data = http_cache.get(
            "https://azuresearch-usnc.nuget.org/query",
            params={"q": term, "take": 20, "prerelease": "false"},
            session=session,
        )
        if not data:
            continue
        for pkg in data.get("data", []):
            found.append({
                "name": pkg.get("id", ""),
                "ecosystem": "dotnet",
                "distribution": "nuget",
                "package_id": pkg.get("id", ""),
                "repo": pkg.get("projectUrl") or None,
                "description": (pkg.get("description") or "")[:120],
                "latest_version": pkg.get("version"),
                "last_release_date": None,
                "stars": None,
                "archived": None,
                "reviewed": False,
                "review_slug": None,
            })
        time.sleep(0.3)
    return _dedup(found)


def discover_maven(session: requests.Session) -> list[dict]:
    found = []
    for term in SEARCH_TERMS:
        data = http_cache.get(
            "https://search.maven.org/solrsearch/select",
            params={"q": term, "rows": 20, "wt": "json"},
            session=session,
        )
        if not data:
            continue
        for doc in data.get("response", {}).get("docs", []):
            ga = doc.get("id", "")
            found.append({
                "name": ga,
                "ecosystem": "java",
                "distribution": "maven",
                "package_id": ga,
                "repo": None,
                "description": "",
                "latest_version": doc.get("latestVersion"),
                "last_release_date": None,
                "stars": None,
                "archived": None,
                "reviewed": False,
                "review_slug": None,
            })
        time.sleep(0.3)
    return _dedup(found)


def discover_github_topics(session: requests.Session) -> list[dict]:
    """Search GitHub topics for changelog-related tools."""
    found = []
    for topic in GITHUB_TOPICS:
        data = http_cache.get(
            "https://api.github.com/search/repositories",
            params={
                "q": f"topic:{topic} is:public archived:false",
                "sort": "stars",
                "per_page": 30,
            },
            headers={"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"},
            session=session,
        )
        if not data:
            continue
        for repo in data.get("items", []):
            lang = (repo.get("language") or "").lower()
            ecosystem = _lang_to_ecosystem(lang)
            found.append({
                "name": repo["full_name"].split("/")[-1],
                "ecosystem": ecosystem,
                "distribution": "github",
                "package_id": repo["full_name"],
                "repo": repo["html_url"],
                "description": (repo.get("description") or "")[:120],
                "latest_version": None,
                "last_release_date": None,
                "stars": repo.get("stargazers_count"),
                "archived": repo.get("archived", False),
                "reviewed": False,
                "review_slug": None,
            })
        time.sleep(0.5)
    return _dedup(found)


def _lang_to_ecosystem(lang: str) -> str:
    mapping = {
        "python": "python",
        "rust": "rust",
        "go": "go",
        "javascript": "node",
        "typescript": "node",
        "ruby": "ruby",
        "java": "java",
        "kotlin": "java",
        "c#": "dotnet",
        "f#": "dotnet",
        "c++": "cpp",
        "c": "c",
        "shell": "other",
    }
    return mapping.get(lang, "other")


def _dedup(tools: list[dict]) -> list[dict]:
    seen: set[str] = set()
    out = []
    for t in tools:
        k = f"{t['distribution']}:{t['package_id']}"
        if k not in seen and t["name"]:
            seen.add(k)
            out.append(t)
    return out


# ── Main ───────────────────────────────────────────────────────────────────────

DISCOVERERS = [
    ("PyPI", discover_pypi),
    ("crates.io", discover_crates),
    ("npm", discover_npm),
    ("RubyGems", discover_rubygems),
    ("NuGet", discover_nuget),
    ("Maven Central", discover_maven),
    ("GitHub topics", discover_github_topics),
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Discover changelog/release tools from registries")
    parser.add_argument("--dry-run", action="store_true", help="Print what would be added without writing")
    parser.add_argument("--source", help="Run only this source (e.g. npm, pypi, crates.io)")
    args = parser.parse_args()

    session = _session()
    existing = tool_store.load()
    print(f"Loaded {len(existing)} existing tools from tools.json")

    all_found: list[dict] = []
    for name, fn in DISCOVERERS:
        if args.source and args.source.lower() not in name.lower():
            continue
        print(f"Querying {name}...")
        try:
            results = fn(session)
            print(f"  Found {len(results)} candidates")
            all_found.extend(results)
        except Exception as exc:
            print(f"  [error] {name}: {exc}")

    merged, added, updated = tool_store.merge(existing, all_found)
    print(f"\nResult: {added} new tools, {updated} updated entries")

    if args.dry_run:
        print("Dry-run — not writing to tools.json")
        new_only = [t for t in merged if not any(
            e["distribution"] == t["distribution"] and e["package_id"] == t["package_id"]
            for e in existing
        )]
        for t in new_only[:40]:
            print(f"  + {t['ecosystem']:8} {t['distribution']:12} {t['name']}")
        return

    tool_store.save(merged)
    print(f"Saved {len(merged)} tools to data/tools.json")


if __name__ == "__main__":
    main()
