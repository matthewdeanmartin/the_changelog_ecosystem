#!/usr/bin/env bash
# keepachangelog life-cycle driver.
#
# keepachangelog is a manual-edit workflow: humans write CHANGELOG.md in Keep a
# Changelog format; the tool provides a parser library and a CLI for releasing
# (promoting [Unreleased] to a versioned section) and extracting release bodies.
#
# Life cycle:
#   Stage 1 — v1.0.0 code committed, no changelog yet.
#   Stage 2 — Seed CHANGELOG.md (with v1.0.0 section), run `keepachangelog show`.
#   Stage 3 — Add v2.0.0 entry under [Unreleased]; preview with `keepachangelog show`.
#   Stage 4a — Release v2.0.0 via `keepachangelog release`; tag.
#   Stage 4b — Add v3.0.0 entry, release, tag.
set -euo pipefail

exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}

SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false
echo "tool under test:"
keepachangelog --version 2>/dev/null || python -c "import keepachangelog; print('keepachangelog', keepachangelog.__version__)"

# ---- STAGE 1: no changelog --------------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; python -m tipcalc
dump_changelog

# ---- STAGE 2: changelog created (seed the v1.0.0 changelog) ----------------
banner "STAGE 2: seed CHANGELOG.md for v1.0.0 and show release body"
cp $SCENARIO/CHANGELOG_seed.md CHANGELOG.md
echo "--- keepachangelog show 1.0.0 ---"
keepachangelog show 1.0.0
git add -A && git commit -q -m "docs: add changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: add v2.0.0 entry to [Unreleased] -------------------------
banner "STAGE 3: implement even split, add entry to [Unreleased]"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

# Manually add the new feature under [Unreleased].
python3 - <<'PYEOF'
import re, pathlib

path = pathlib.Path("CHANGELOG.md")
text = path.read_text()

new_entry = """\
## [Unreleased]

### Added

- Split the bill evenly among a fixed number of diners.

"""
text = text.replace("## [Unreleased]\n", new_entry, 1)
path.write_text(text)
PYEOF

echo "--- keepachangelog show unreleased (note: crashes on empty Unreleased, finding) ---"
keepachangelog show Unreleased CHANGELOG.md 2>&1 || echo "(show Unreleased failed — see NOTES.md for bug details)"
git add -A && git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: release v2.0.0 -----------------------------------------------
banner "STAGE 4a: release v2.0.0 via keepachangelog release"
# keepachangelog release promotes [Unreleased] -> [2.0.0] - <date>
# The release command takes the version as the only positional arg; file is positional first.
keepachangelog release 2.0.0
echo "--- keepachangelog show 2.0.0 ---"
keepachangelog show 2.0.0
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

python3 - <<'PYEOF'
import re, pathlib

path = pathlib.Path("CHANGELOG.md")
text = path.read_text()

new_entry = """\
## [Unreleased]

### Added

- Split the bill unevenly using per-person weights; output now lists each diner's share.

"""
text = text.replace("## [Unreleased]\n\n## [2.0.0]", new_entry + "## [2.0.0]", 1)
path.write_text(text)
PYEOF

git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
keepachangelog release 3.0.0
echo "--- keepachangelog show 3.0.0 ---"
keepachangelog show 3.0.0
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- demonstrate library usage (Python API) ----------------------------------
banner "BONUS: library API — to_dict and from_dict"
python3 - <<'PYEOF'
import keepachangelog, json

data = keepachangelog.to_dict("CHANGELOG.md")
print("Versions found:", list(data.keys()))
print("v3.0.0 sections:", list(data.get("3.0.0", {}).keys()))
# Round-trip: regenerate Markdown from the dict
md = keepachangelog.from_dict(data)
print("Round-trip Markdown length:", len(md), "chars")
PYEOF

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
