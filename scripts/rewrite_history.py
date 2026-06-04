#!/usr/bin/env python3
"""
Rewrite git history via git-filter-repo:
  1. Strip all Co-Authored-By / Co-authored-by trailers from commit messages.
  2. Rephrase every commit subject in keepachangelog style
     (Added / Changed / Fixed / Removed / …).

Run from the repo root:
    python scripts/rewrite_history.py

git-filter-repo must be on PATH.

IMPORTANT: git-filter-repo requires a "clean clone" — i.e. no remote named
'origin' (or you must pass --force).  See the note at the bottom of this
script for how to satisfy that requirement.
"""

import re
import subprocess
import sys

# ---------------------------------------------------------------------------
# Commit-message map  (original subject  →  new full message)
# ---------------------------------------------------------------------------
# Rules:
#   Added:   new files, features, content
#   Changed: edits to existing files, restructuring, config tweaks
#   Fixed:   bug fixes, broken-build corrections
#   Removed: deletions
# ---------------------------------------------------------------------------

COMMIT_MAP: dict[str, str] = {
    # oldest → newest
    "Initial commit": "Added: initial project skeleton",

    "Bootstrap Pelican site for The Changelog Ecosystem": (
        "Added: bootstrap Pelican site for The Changelog Ecosystem"
    ),

    "Phase 2: data pipeline with incremental gather and Justfile": (
        "Added: data pipeline with incremental gather and Justfile\n\n"
        "- pipeline/http_cache.py: disk-backed HTTP cache (24h TTL, keyed by URL+params)\n"
        "- pipeline/tool_store.py: merge strategy that never overwrites hand-curated fields\n"
        "- discover_tools.py: queries PyPI, crates.io, npm, RubyGems, NuGet, Maven, GitHub topics\n"
        "- gather_metadata.py: fills version/date/stars/archived from registries + GitHub API\n"
        "- generate_pages.py: writes tools.md + per-ecosystem pages from live data\n"
        "- Justfile: discover, gather, generate-pages, build, serve, devserver, pipeline, all\n"
        "- data/tools.json: live metadata now populated for all 10 seed tools"
    ),

    "Cross-check tools.json against top_prio_tools.toml; import all 42 missing tools": (
        "Added: import 42 missing tools from top_prio_tools.toml into tools.json\n\n"
        "- Imported all 42 tools from top_prio_tools.toml into data/tools.json (52 total)\n"
        "- Added _toml_status, _toml_priority, _toml_source_type, _toml_url fields\n"
        "- Fixed scoped npm package IDs and fetch_npm URL encoding\n"
        "- Fixed bad repo URLs from TOML import\n"
        "- Gathered live metadata for all new tools\n"
        "- Generated per-ecosystem pages for cpp, cross, dotnet, go, java, node, python, ruby, rust"
    ),

    "Phase 3: generate 50 review stubs for all tools": (
        "Added: generate review stubs for all 50 tools\n\n"
        "- generate_review_stubs.py: creates content/articles/{slug}.md per unreviewed tool\n"
        "- Backfilled _toml_capabilities into tools.json from top_prio_tools.toml\n"
        "- All 51 articles now build cleanly (51 articles + 12 pages)\n"
        "- Justfile: added stubs, stubs-must, stubs-force recipes\n"
        "- generate_pages.py synced reviewed:true for 48 tools"
    ),

    "Fix truncated descriptions: remove all [:120] caps, restore full text from TOML": (
        "Fixed: remove [:120] truncation caps and restore full descriptions from TOML\n\n"
        "- Removed [:120] truncation from discover_tools.py (5 sites) and generate_review_stubs.py\n"
        "- Restored full descriptions for 11 tools in tools.json from top_prio_tools.toml\n"
        "- Patched Summary frontmatter in 11 existing article stubs\n"
        "- Regenerated all ecosystem pages with full descriptions"
    ),

    "starting to fill in deets": "Changed: begin filling in article details",

    # second identical subject — git-filter-repo callback receives the full message,
    # so both map to the same new text; that is fine.
    "node, etc": "Added: content for Node and related ecosystem articles",

    "first draft everywhere": "Added: first draft content across all article stubs",

    "ready to publish draft 1": "Changed: polish articles to draft-1 publish-ready state",

    "looking at examples to get data for reviews": (
        "Added: example projects used as data sources for tool reviews"
    ),

    "npm, rust examples": "Added: npm and Rust example projects for tool reviews",

    "java examples": "Added: Java example projects for tool reviews",

    "dotnet examples, go examples": "Added: .NET and Go example projects for tool reviews",

    "fix style, add decision tool": (
        "Fixed: CSS style issues; added decision-tool article"
    ),

    "filling in planned articles": "Added: content for planned articles",

    "move v2's out of content so it builds": (
        "Fixed: move v2 drafts out of content directory so site builds"
    ),

    "don't html validate complex page": (
        "Changed: skip HTML validation for complex generated page"
    ),

    "skip validation that relies on chrome installation": (
        "Changed: skip browser-dependent validation steps in CI"
    ),

    "attempt to fix relative links": "Fixed: relative link paths in generated pages",
}

# ---------------------------------------------------------------------------
# Trailer-stripping regex
# ---------------------------------------------------------------------------
COAUTHOR_RE = re.compile(
    r"\n?^Co-[Aa]uthored?-[Bb]y:.*$",
    re.MULTILINE,
)


def build_callback_script() -> str:
    """Return a Python snippet suitable for git-filter-repo --commit-callback."""

    # Embed the map as a literal dict inside the callback string.
    map_lines = ["COMMIT_MAP = {\n"]
    for k, v in COMMIT_MAP.items():
        # repr() gives us safe Python string literals.
        map_lines.append(f"    {repr(k)}: {repr(v)},\n")
    map_lines.append("}\n")
    map_str = "".join(map_lines)

    callback = (
        "import re\n"
        "COAUTHOR_RE = re.compile(\n"
        r'    r"\n?^Co-[Aa]uthored?-[Bb]y:.*$",' "\n"
        "    re.MULTILINE,\n"
        ")\n"
        + map_str
        + """
original = commit.message.decode("utf-8", errors="replace")

# 1. Strip Co-Authored-By trailers
cleaned = COAUTHOR_RE.sub("", original)

# 2. Remap subject if it's in our map
subject_line = cleaned.split("\\n", 1)[0].strip()
if subject_line in COMMIT_MAP:
    rest = cleaned.split("\\n", 1)[1] if "\\n" in cleaned else ""
    # Use the canonical new message; if new message already has a body, keep it;
    # otherwise append any existing body that wasn't the co-author trailer.
    new_msg = COMMIT_MAP[subject_line]
    # If the new mapping already contains a body, use it as-is.
    if "\\n" not in new_msg:
        # No body in map — append whatever was left after stripping trailers.
        body_after_strip = rest.strip()
        if body_after_strip:
            new_msg = new_msg + "\\n\\n" + body_after_strip
    cleaned = new_msg

# 3. Ensure message ends with a single newline
cleaned = cleaned.rstrip() + "\\n"

commit.message = cleaned.encode("utf-8")
"""
    )
    return callback


def check_prerequisites() -> None:
    result = subprocess.run(
        ["git-filter-repo", "--version"], capture_output=True, text=True
    )
    if result.returncode != 0:
        print("ERROR: git-filter-repo not found on PATH.", file=sys.stderr)
        sys.exit(1)

    # Check for clean-clone requirement: git-filter-repo refuses to run when
    # a remote named 'origin' exists unless --force is passed.
    remotes = subprocess.run(
        ["git", "remote"], capture_output=True, text=True
    ).stdout.strip().splitlines()
    if "origin" in remotes:
        print(
            "\nWARNING: This repo has a remote named 'origin'.\n"
            "git-filter-repo requires either:\n"
            "  (a) a fresh clone with no remotes, OR\n"
            "  (b) the --force flag (which this script will add automatically).\n"
            "Proceeding with --force.\n"
        )
        return True  # signal caller to add --force
    return False


def main() -> None:
    needs_force = check_prerequisites()

    callback_code = build_callback_script()

    cmd = ["git-filter-repo", "--commit-callback", callback_code]
    if needs_force:
        cmd.append("--force")

    print("Running git-filter-repo …")
    print("Command:", " ".join(cmd[:3]), "<callback>", *cmd[3:])
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("\nERROR: git-filter-repo failed.", file=sys.stderr)
        sys.exit(result.returncode)

    print("\nDone. New history:")
    subprocess.run(["git", "log", "--oneline"])


if __name__ == "__main__":
    main()
