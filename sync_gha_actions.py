"""
Sync GitHub Actions catalog (data/gha_actions.toml) into data/tools.json.

Each action in the TOML becomes a tools.json record with:
    ecosystem   = "github-action"
    distribution = "github"        (so gather_metadata.py fills stars/version)
    gha_tier, wraps, marketplace_url, category

Upsert is keyed on the stable `id`. Existing records with a matching id are
updated in place (ecosystem migrated to github-action, gha_* fields refreshed)
without touching PROTECTED / review fields. Records not present are appended.

Usage:
    uv run python sync_gha_actions.py [--dry-run]
"""

from __future__ import annotations

import argparse
import sys
import tomllib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from pipeline import tool_store

GHA_TOML = Path(__file__).parent / "data" / "gha_actions.toml"

# Fields owned by the GHA catalog: always refreshed from the TOML on sync.
CATALOG_FIELDS = {
    "ecosystem",
    "distribution",
    "repo",
    "description",
    "gha_tier",
    "wraps",
    "marketplace_url",
    "gha_category",
}
# Never clobbered by the catalog (hand-curated / review state).
PRESERVE = tool_store.PROTECTED | {"reviewed", "review_slug"}


def load_catalog() -> list[dict]:
    data = tomllib.loads(GHA_TOML.read_text(encoding="utf-8"))
    records: list[dict] = []
    for action in data.get("actions", []):
        repo = (action.get("repo") or "").strip() or None
        records.append(
            {
                "id": action["id"],
                "name": action["name"],
                "ecosystem": "github-action",
                "distribution": "github",
                # package_id derived from repo owner/name for a stable store key.
                "package_id": _owner_repo(repo) or action["id"],
                "repo": repo,
                "description": action.get("description", ""),
                "gha_tier": int(action.get("tier", 3)),
                "wraps": (action.get("wraps") or "") or None,
                "marketplace_url": (action.get("marketplace_url") or "") or None,
                "gha_category": action.get("category", ""),
            }
        )
    return records


def _owner_repo(repo: str | None) -> str | None:
    if not repo:
        return None
    tail = repo.rstrip("/").split("github.com/", 1)
    return tail[1] if len(tail) == 2 else None


def sync(dry_run: bool) -> None:
    tools = tool_store.load()
    by_id = {t.get("id"): t for t in tools if t.get("id")}

    added = updated = 0
    for rec in load_catalog():
        existing = by_id.get(rec["id"])
        # Guard against id collisions with an unrelated already-tracked tool:
        # only migrate an existing record if it is already a github-action or
        # its repo matches. Otherwise the ids clash and we must not clobber it.
        if (
            existing is not None
            and existing.get("ecosystem") != "github-action"
            and rec.get("repo")
            and existing.get("repo")
            and existing["repo"].rstrip("/") != rec["repo"].rstrip("/")
        ):
            raise SystemExit(
                f"id collision: '{rec['id']}' already tracked as a different tool "
                f"({existing.get('repo')}). Rename the id in gha_actions.toml."
            )
        if existing is None:
            tools.append(rec)
            by_id[rec["id"]] = rec
            added += 1
            print(f"  + {rec['id']} (tier {rec['gha_tier']})")
            continue

        changed = False
        for field, val in rec.items():
            if field in PRESERVE:
                continue
            # description is PROTECTED in the store, but the catalog owns it for
            # unreviewed actions; keep an existing hand-written one if present.
            if field == "description" and existing.get("description"):
                continue
            # Only fill package_id if the existing one is a placeholder.
            if field == "package_id" and existing.get("package_id") not in (
                None,
                "",
                "marketplace/actions",
            ):
                continue
            if field in CATALOG_FIELDS or existing.get(field) is None:
                if existing.get(field) != val:
                    existing[field] = val
                    changed = True
        if changed:
            updated += 1
            print(f"  ~ {rec['id']} (migrated -> github-action)")

    print(f"\n{added} added, {updated} updated.")
    if dry_run:
        print("Dry-run: tools.json not written.")
        return
    tool_store.save(tools)
    print("Saved data/tools.json")


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync gha_actions.toml into tools.json")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing")
    args = parser.parse_args()
    sync(args.dry_run)


if __name__ == "__main__":
    main()
