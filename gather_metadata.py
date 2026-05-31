"""
Phase 2.2 — gather live metadata for every tool in data/tools.json.

For each tool, fills in:
  latest_version, last_release_date, stars, archived

Pulls from:
  - PyPI JSON API
  - crates.io API
  - npm registry
  - RubyGems API
  - NuGet API
  - Maven Central
  - GitHub Releases / repository API (for stars, archived, and tools with distribution=github)

Incremental: only fetches tools where metadata fields are null unless --force is passed.

Usage:
    uv run python gather_metadata.py [--force] [--ecosystem python] [--name git-cliff]
"""
from __future__ import annotations

import argparse
import os
import sys
import time

import requests

sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))
from pipeline import http_cache, tool_store

GH_API = "https://api.github.com"


def _session() -> requests.Session:
    s = requests.Session()
    token = os.environ.get("GITHUB_TOKEN", "")
    if token:
        s.headers["Authorization"] = f"Bearer {token}"
    s.headers["User-Agent"] = "the-changelog-ecosystem/1.0 (https://github.com/matthewdeanmartin)"
    return s


def _needs_refresh(tool: dict, force: bool) -> bool:
    if force:
        return True
    return any(
        tool.get(f) is None
        for f in ("latest_version", "last_release_date", "stars", "archived")
    )


# ── Registry fetchers ──────────────────────────────────────────────────────────

def fetch_pypi(tool: dict, session: requests.Session) -> dict:
    data = http_cache.get(
        f"https://pypi.org/pypi/{tool['package_id']}/json",
        session=session,
    )
    if not data:
        return {}
    info = data.get("info", {})
    releases = data.get("releases", {})
    # Find most recent release date across all files
    dates = []
    for files in releases.values():
        for f in files:
            if f.get("upload_time"):
                dates.append(f["upload_time"][:10])
    last_date = max(dates) if dates else None
    return {
        "latest_version": info.get("version"),
        "last_release_date": last_date,
        "repo": _coerce_repo(info.get("project_urls", {}).get("Source")
                             or info.get("project_urls", {}).get("Repository")
                             or info.get("home_page")
                             or tool.get("repo")),
    }


def fetch_crates(tool: dict, session: requests.Session) -> dict:
    data = http_cache.get(
        f"https://crates.io/api/v1/crates/{tool['package_id']}",
        session=session,
    )
    if not data:
        return {}
    c = data.get("crate", {})
    return {
        "latest_version": c.get("newest_version") or c.get("max_version"),
        "last_release_date": (c.get("updated_at") or "")[:10] or None,
        "repo": _coerce_repo(c.get("repository") or tool.get("repo")),
    }


def fetch_npm(tool: dict, session: requests.Session) -> dict:
    data = http_cache.get(
        f"https://registry.npmjs.org/{tool['package_id']}",
        session=session,
    )
    if not data:
        return {}
    dist_tags = data.get("dist-tags", {})
    latest = dist_tags.get("latest")
    time_data = data.get("time", {})
    last_date = (time_data.get(latest) or "")[:10] or None
    repo_info = data.get("repository", {})
    repo_url = repo_info.get("url", "") if isinstance(repo_info, dict) else ""
    repo_url = repo_url.replace("git+", "").replace(".git", "").replace("git://", "https://")
    return {
        "latest_version": latest,
        "last_release_date": last_date,
        "repo": _coerce_repo(repo_url or tool.get("repo")),
    }


def fetch_rubygems(tool: dict, session: requests.Session) -> dict:
    data = http_cache.get(
        f"https://rubygems.org/api/v1/gems/{tool['package_id']}.json",
        session=session,
    )
    if not data:
        return {}
    return {
        "latest_version": data.get("version"),
        "last_release_date": (data.get("version_created_at") or "")[:10] or None,
        "repo": _coerce_repo(
            data.get("source_code_uri") or data.get("homepage_uri") or tool.get("repo")
        ),
    }


def fetch_nuget(tool: dict, session: requests.Session) -> dict:
    # Get registration index to find latest version and date
    data = http_cache.get(
        f"https://api.nuget.org/v3/registration5-gz-semver2/{tool['package_id'].lower()}/index.json",
        session=session,
    )
    if not data:
        return {}
    items = data.get("items", [])
    if not items:
        return {}
    last_page = items[-1]
    # Inline items or need to fetch page
    page_items = last_page.get("items") or []
    if not page_items:
        page_data = http_cache.get(last_page.get("@id", ""), session=session)
        page_items = (page_data or {}).get("items", [])
    if not page_items:
        return {}
    last = page_items[-1]
    catalog = last.get("catalogEntry", {})
    return {
        "latest_version": catalog.get("version"),
        "last_release_date": (catalog.get("published") or "")[:10] or None,
        "repo": _coerce_repo(catalog.get("projectUrl") or tool.get("repo")),
    }


def fetch_maven(tool: dict, session: requests.Session) -> dict:
    # package_id is groupId:artifactId
    parts = tool["package_id"].split(":")
    if len(parts) != 2:
        return {}
    g, a = parts
    data = http_cache.get(
        "https://search.maven.org/solrsearch/select",
        params={"q": f"g:{g} AND a:{a}", "rows": 1, "wt": "json"},
        session=session,
    )
    if not data:
        return {}
    docs = data.get("response", {}).get("docs", [])
    if not docs:
        return {}
    doc = docs[0]
    ts = doc.get("timestamp")
    date = None
    if ts:
        import datetime
        date = datetime.datetime.fromtimestamp(ts / 1000, tz=datetime.timezone.utc).strftime("%Y-%m-%d")
    return {
        "latest_version": doc.get("latestVersion"),
        "last_release_date": date,
    }


def fetch_github(tool: dict, session: requests.Session) -> dict:
    """Fetch stars, archived, and latest release date from GitHub."""
    repo_url = tool.get("repo") or ""
    owner_repo = _extract_owner_repo(repo_url)
    if not owner_repo:
        return {}

    repo_data = http_cache.get(
        f"{GH_API}/repos/{owner_repo}",
        headers={"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"},
        session=session,
    )
    if not repo_data:
        return {}

    result: dict = {
        "stars": repo_data.get("stargazers_count"),
        "archived": repo_data.get("archived", False),
    }

    # For github-distribution tools, also get latest release version/date
    if tool.get("distribution") == "github" or tool.get("latest_version") is None:
        release_data = http_cache.get(
            f"{GH_API}/repos/{owner_repo}/releases/latest",
            headers={"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"},
            session=session,
        )
        if release_data and release_data.get("tag_name"):
            result["latest_version"] = release_data["tag_name"].lstrip("v")
            result["last_release_date"] = (release_data.get("published_at") or "")[:10] or None

    return result


def _extract_owner_repo(url: str) -> str | None:
    if not url:
        return None
    url = url.rstrip("/")
    for prefix in ("https://github.com/", "http://github.com/", "github.com/"):
        if url.startswith(prefix):
            path = url[len(prefix):]
            parts = path.split("/")
            if len(parts) >= 2:
                return f"{parts[0]}/{parts[1]}"
    return None


def _coerce_repo(url: str | None) -> str | None:
    if not url:
        return None
    url = url.strip()
    if url.startswith("git+"):
        url = url[4:]
    if url.endswith(".git"):
        url = url[:-4]
    return url or None


FETCHERS: dict[str, callable] = {
    "pypi": fetch_pypi,
    "crates.io": fetch_crates,
    "npm": fetch_npm,
    "rubygems": fetch_rubygems,
    "nuget": fetch_nuget,
    "maven": fetch_maven,
    "github": fetch_github,
}


# ── Main ───────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Gather metadata for tools in tools.json")
    parser.add_argument("--force", action="store_true", help="Re-fetch even if data already present")
    parser.add_argument("--ecosystem", help="Only process this ecosystem (e.g. python)")
    parser.add_argument("--name", help="Only process this tool name")
    parser.add_argument("--dry-run", action="store_true", help="Print fetched data without saving")
    args = parser.parse_args()

    session = _session()
    tools = tool_store.load()
    print(f"Loaded {len(tools)} tools")

    updated_count = 0
    for i, tool in enumerate(tools):
        if args.ecosystem and tool.get("ecosystem") != args.ecosystem:
            continue
        if args.name and tool.get("name") != args.name:
            continue
        if not _needs_refresh(tool, args.force):
            continue

        dist = tool.get("distribution", "")
        print(f"  [{i+1}/{len(tools)}] {tool['name']} ({dist})")

        updates: dict = {}

        # Registry-specific metadata
        fetcher = FETCHERS.get(dist)
        if fetcher:
            try:
                reg_data = fetcher(tool, session)
                updates.update(reg_data)
                time.sleep(0.4)
            except Exception as exc:
                print(f"    [warn] registry fetch failed: {exc}")

        # GitHub metadata (stars, archived) for any tool with a github repo
        if tool.get("repo") and "github.com" in (tool.get("repo") or ""):
            try:
                gh_data = fetch_github(tool, session)
                # Only fill stars/archived from GitHub if not already set
                for field in ("stars", "archived", "latest_version", "last_release_date"):
                    if field in gh_data and tool.get(field) is None:
                        updates[field] = gh_data[field]
                time.sleep(0.3)
            except Exception as exc:
                print(f"    [warn] GitHub fetch failed: {exc}")

        if updates:
            if args.dry_run:
                print(f"    would update: {updates}")
            else:
                for field, val in updates.items():
                    if field not in tool_store.PROTECTED:
                        if args.force or tools[i].get(field) is None:
                            tools[i][field] = val
                updated_count += 1

    if not args.dry_run:
        tool_store.save(tools)
        print(f"\nUpdated {updated_count} tools. Saved to data/tools.json")
    else:
        print(f"\nDry-run complete. Would update {updated_count} tools.")


if __name__ == "__main__":
    main()
