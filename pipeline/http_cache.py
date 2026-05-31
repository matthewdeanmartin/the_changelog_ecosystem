"""
Disk-backed HTTP cache for registry and GitHub API calls.

Cache files live in data/cache/<hash>.json, keyed by URL + query params.
TTL defaults to 24 hours but can be overridden per-call.
"""
import hashlib
import json
import os
import time
from pathlib import Path

import requests

CACHE_DIR = Path(__file__).parent.parent / "data" / "cache"
DEFAULT_TTL = 60 * 60 * 24  # 24 hours


def _cache_path(url: str, params: dict | None) -> Path:
    key = url + json.dumps(params or {}, sort_keys=True)
    digest = hashlib.sha256(key.encode()).hexdigest()[:16]
    return CACHE_DIR / f"{digest}.json"


def get(
    url: str,
    params: dict | None = None,
    headers: dict | None = None,
    ttl: int = DEFAULT_TTL,
    session: requests.Session | None = None,
) -> dict | list | None:
    """
    Fetch URL, returning cached JSON if fresh enough.

    Returns None on HTTP error or non-JSON response; never raises.
    """
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = _cache_path(url, params)

    if path.exists():
        try:
            cached = json.loads(path.read_text(encoding="utf-8"))
            if time.time() - cached["_ts"] < ttl:
                return cached["data"]
        except (json.JSONDecodeError, KeyError):
            pass

    requester = session or requests
    try:
        resp = requester.get(url, params=params, headers=headers, timeout=20)
        if resp.status_code == 404:
            return None
        resp.raise_for_status()
        data = resp.json()
    except Exception as exc:
        print(f"  [warn] GET {url} failed: {exc}")
        return None

    path.write_text(
        json.dumps({"_ts": time.time(), "data": data}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return data
