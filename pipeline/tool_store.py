"""
Read/write helpers for data/tools.json.

Merge strategy: existing entries are updated field-by-field; only null fields
are overwritten by incoming data, except for fields explicitly passed as
force_fields. This preserves hand-edited values (e.g. reviewed, review_slug,
description).
"""
import json
from pathlib import Path

TOOLS_PATH = Path(__file__).parent.parent / "data" / "tools.json"

# Fields that are never overwritten by automated gather (always hand-curated)
PROTECTED = {"reviewed", "review_slug", "description"}


def load() -> list[dict]:
    if not TOOLS_PATH.exists():
        return []
    return json.loads(TOOLS_PATH.read_text(encoding="utf-8"))


def save(tools: list[dict]) -> None:
    tools_sorted = sorted(tools, key=lambda t: (t.get("ecosystem", ""), t.get("name", "")))
    TOOLS_PATH.write_text(
        json.dumps(tools_sorted, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _key(tool: dict) -> str:
    return f"{tool.get('distribution', '')}:{tool.get('package_id', tool.get('name', ''))}"


def merge(existing: list[dict], incoming: list[dict], force_fields: set[str] | None = None) -> tuple[list[dict], int, int]:
    """
    Merge incoming tools into existing list.

    - New tools are appended.
    - Existing tools have only null fields updated (plus force_fields).
    - Protected fields are never touched by automated data.

    Returns (merged_list, added_count, updated_count).
    """
    force_fields = force_fields or set()
    index = {_key(t): i for i, t in enumerate(existing)}
    result = list(existing)
    added = updated = 0

    for inc in incoming:
        k = _key(inc)
        if k not in index:
            result.append(inc)
            added += 1
        else:
            i = index[k]
            changed = False
            for field, val in inc.items():
                if field in PROTECTED:
                    continue
                if field in force_fields or result[i].get(field) is None:
                    if result[i].get(field) != val:
                        result[i][field] = val
                        changed = True
            if changed:
                updated += 1

    return result, added, updated
