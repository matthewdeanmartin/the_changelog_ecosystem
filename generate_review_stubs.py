"""
Phase 3 — generate stub review articles for all unreviewed tools.

Creates content/articles/{slug}.md for every tool in data/tools.json
that doesn't already have a review. Stubs are structured with all required
sections and machine-filled metadata; prose sections are marked TODO for
human/LLM review pass.

Usage:
    uv run python generate_review_stubs.py [--dry-run] [--priority must]
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from pipeline import tool_store

ARTICLES_DIR = Path(__file__).parent / "content" / "articles"

DIST_URLS = {
    "pypi": "https://pypi.org/project/{id}/",
    "crates.io": "https://crates.io/crates/{id}",
    "npm": "https://www.npmjs.com/package/{id}",
    "rubygems": "https://rubygems.org/gems/{id}",
    "nuget": "https://www.nuget.org/packages/{id}/",
    "maven": "https://search.maven.org/artifact/{id}",
    "github": "https://github.com/{id}",
    "gradle": "https://plugins.gradle.org/plugin/{id}",
    "gitlab": "https://gitlab.com/{id}",
}

INSTALL_SNIPPETS: dict[str, str] = {
    "pypi": "```bash\npip install {id}\n# or with uv:\nuv add {id}\n```",
    "crates.io": "```bash\ncargo install {id}\n```",
    "npm": "```bash\nnpm install --save-dev {id}\n# or globally:\nnpm install -g {id}\n```",
    "rubygems": "```bash\ngem install {id}\n```",
    "nuget": "```bash\ndotnet tool install -g {id}\n```",
    "gradle": "Add to `build.gradle.kts`:\n```kotlin\nplugins {{\n    id(\"{id}\")\n}}\n```",
    "github": "```bash\n# See {repo} for installation options\n# (binary releases, Homebrew, package managers)\n```",
    "maven": "Add to `pom.xml`:\n```xml\n<plugin>\n  <groupId>TODO</groupId>\n  <artifactId>{name}</artifactId>\n</plugin>\n```",
    "platform": "_Platform feature — no installation required._",
    "github-action": "Add to `.github/workflows/release.yml`:\n```yaml\n- uses: {id}@v1\n```",
    "other": "_TODO: describe installation_",
}

STATUS_NOTES: dict = {
    "deprecated": "> **Note:** This tool is deprecated. See the Maintenance Status section for migration guidance.",
    "legacy": "> **Note:** This tool is considered legacy. The community has largely moved on; see Maintenance Status.",
}


def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def dist_url(tool: dict) -> str:
    dist = tool.get("distribution", "")
    pkg_id = tool.get("package_id", "")
    tmpl = DIST_URLS.get(dist)
    if tmpl:
        return tmpl.format(id=pkg_id)
    return tool.get("_toml_url") or tool.get("repo") or ""


def install_snippet(tool: dict) -> str:
    dist = tool.get("distribution", "other")
    tmpl = INSTALL_SNIPPETS.get(dist, INSTALL_SNIPPETS["other"])
    return tmpl.format(
        id=tool.get("package_id", ""),
        name=tool.get("name", ""),
        repo=tool.get("repo", ""),
    )


def stars_line(tool: dict) -> str:
    s = tool.get("stars")
    if s is None:
        return "_Stars: N/A (platform feature or no GitHub repo)_"
    return f"GitHub stars: **{s:,}**"


def maintenance_section(tool: dict) -> str:
    status = tool.get("_toml_status", "")
    last = tool.get("last_release_date") or "unknown"
    version = tool.get("latest_version") or "unknown"
    archived = tool.get("archived", False)
    stars = tool.get("stars")

    lines = [f"- Latest version: **{version}**", f"- Last release: **{last}**"]
    if stars is not None:
        lines.append(f"- {stars_line(tool)}")
    if archived:
        lines.append("- **Repository is archived** — no new development expected.")
    elif status == "deprecated":
        lines.append("- Project is **deprecated** by its maintainers.")
    elif status == "legacy":
        lines.append("- Project is in **legacy/maintenance mode** — no active feature development.")
    elif last != "unknown" and last[:4] < "2023":
        lines.append("- Last release was over 2 years ago — check if still maintained.")
    else:
        lines.append("- Appears actively maintained.")

    repo = tool.get("repo")
    if repo:
        lines.append(f'- Repository: <a href="{repo}" target="_blank" rel="noopener noreferrer">{repo}</a>')

    return "\n".join(lines)


def capability_bullets(tool: dict) -> str:
    caps = tool.get("_toml_capabilities") or []
    if not caps:
        return "_TODO: describe core features_"
    labels = {
        "autocreate-from-commits": "Generates changelog/release notes from git commit history",
        "autocreate-from-tags": "Generates changelog from git tags",
        "autocreate-from-github": "Generates changelog from GitHub issues and PRs",
        "autocreate-from-prs": "Generates release notes from merged pull requests",
        "fragment-assembly": "Assembles changelog from individual news/change fragment files",
        "version-bump": "Automates version bumping (semver)",
        "changelog-file": "Writes and updates a `CHANGELOG.md` file",
        "release-notes": "Generates release notes for GitHub/GitLab releases",
        "github-release": "Creates or updates GitHub Releases",
        "gitlab-release": "Creates or updates GitLab Releases",
        "keep-a-changelog": "Implements or targets the Keep a Changelog format",
        "conventional-commits": "Parses Conventional Commits message format",
        "custom-templates": "Supports custom output templates",
        "validate": "Validates existing changelog files against a spec",
        "backfill": "Can generate changelog from existing history / backfill old releases",
        "monorepo": "Supports monorepo / multi-package workflows",
        "plugins": "Extensible via plugins",
        "package-publish": "Publishes packages to a registry (npm, crates.io, PyPI, NuGet, etc.)",
        "draft-release": "Creates draft releases for manual review before publishing",
        "milestones": "Integrates with GitHub/GitLab milestones",
        "ci-integration": "Designed for use in CI/CD pipelines",
    }
    bullets = []
    for cap in caps:
        label = labels.get(cap, cap.replace("-", " ").capitalize())
        bullets.append(f"- {label}")
    return "\n".join(bullets) if bullets else "_TODO: describe core features_"


CAP_TAG_LABELS: dict[str, str] = {
    "autocreate-from-commits": "conventional-commits",
    "autocreate-from-tags": "git-tags",
    "autocreate-from-github": "github-integration",
    "autocreate-from-prs": "github-integration",
    "fragment-assembly": "news-fragments",
    "version-bump": "semantic-versioning",
    "changelog-file": "keep-a-changelog",
    "release-notes": "release-notes",
    "github-release": "github-integration",
    "gitlab-release": "gitlab-integration",
    "keep-a-changelog": "keep-a-changelog",
    "conventional-commits": "conventional-commits",
    "custom-templates": "custom-templates",
    "validate": "validation",
    "backfill": "backfill",
    "monorepo": "monorepo",
    "plugins": "extensible",
    "package-publish": "package-publishing",
    "draft-release": "draft-releases",
    "milestones": "milestones",
    "ci-integration": "ci-cd",
}


def tags_line(tool: dict) -> str:
    caps = tool.get("_toml_capabilities") or []
    tags = {CAP_TAG_LABELS[c] for c in caps if c in CAP_TAG_LABELS}
    eco = tool.get("ecosystem", "")
    if eco:
        tags.add(eco.lower())
    source_type = tool.get("_toml_source_type", "")
    if source_type:
        tags.add(source_type.replace("_", "-"))
    return ", ".join(sorted(tags))


def render_stub(tool: dict) -> str:
    name = tool.get("name", "")
    slug = tool.get("review_slug") or slugify(name)
    ecosystem = tool.get("ecosystem", "").capitalize()
    version = tool.get("latest_version") or "unknown"
    toml_status = tool.get("_toml_status", "active")
    status_map = {"deprecated": "archived", "legacy": "unmaintained", "mature": "unmaintained"}
    article_status = status_map.get(toml_status, "active")
    archived = tool.get("archived", False)
    if archived:
        article_status = "archived"

    tool_url = dist_url(tool)
    description = tool.get("description") or "_TODO: one-sentence description_"

    status_banner = STATUS_NOTES.get(toml_status, "")

    caps_text = capability_bullets(tool)
    install_text = install_snippet(tool)
    maintenance_text = maintenance_section(tool)

    tags = tags_line(tool)

    return f"""Title: {name}
Date: 2026-05-31
Slug: {slug}
Ecosystem: {ecosystem}
Tags: {tags}
Tool_URL: {tool_url}
Tool_Version: {version}
Tool_Status: {article_status}
Summary: {description}

{status_banner}

## Overview

<!-- TODO: 2-3 sentences. What problem does this solve? Who is the target user?
     What distinguishes it from similar tools? -->

`{name}` is a {source_type.replace("-", " ")} tool for managing changelogs and releases.

{description}

## Installation

{install_text}

## What It Does

{caps_text}

<!-- TODO: expand each bullet with a concrete example or detail -->

## Configuration

<!-- TODO: describe config file format, required vs optional settings,
     how complex is first-run setup? Show a minimal config example. -->

_TODO: describe configuration approach_

## Output Quality

<!-- TODO: show a sample snippet of generated output. What does the
     changelog/release notes actually look like? Is it human-readable? -->

_TODO: paste a sample output snippet here_

## Ecosystem Fit

<!-- TODO: does it feel native to the {ecosystem} ecosystem?
     Does it integrate with standard build tools ({ecosystem} package managers,
     CI conventions, etc.)? -->

_TODO: assess ecosystem integration_

## Maintenance Status

{maintenance_text}

<!-- TODO: check open issue count, PR responsiveness, release cadence -->

## Verdict

<!-- TODO: choose one: Recommended / Situational / Avoid
     One paragraph justifying the verdict. -->

**Verdict: _TODO_**

_TODO: verdict justification_
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate review stub articles for all unreviewed tools")
    parser.add_argument("--dry-run", action="store_true", help="Print output without writing files")
    parser.add_argument("--priority", help="Only generate for this priority (must/important/secondary)")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing articles")
    args = parser.parse_args()

    tools = tool_store.load()
    ARTICLES_DIR.mkdir(parents=True, exist_ok=True)

    written = skipped = existing_count = 0
    for tool in sorted(tools, key=lambda t: (
        {"must": 0, "important": 1, "secondary": 2}.get(t.get("_toml_priority", ""), 3),
        t.get("name", ""),
    )):
        if args.priority and tool.get("_toml_priority") != args.priority:
            continue

        slug = tool.get("review_slug") or slugify(tool.get("name", ""))
        path = ARTICLES_DIR / f"{slug}.md"

        if path.exists() and not args.overwrite:
            existing_count += 1
            continue

        content = render_stub(tool)

        if args.dry_run:
            print(f"\n--- {path.name} ---")
            print(content[:400])
            print("...")
            skipped += 1
        else:
            path.write_text(content, encoding="utf-8")
            written += 1
            print(f"  wrote {path.name}")

    if not args.dry_run:
        print(f"\nWrote {written} stubs, skipped {existing_count} existing articles")
    else:
        print(f"\nDry-run: would write {skipped} stubs, {existing_count} already exist")


if __name__ == "__main__":
    main()
