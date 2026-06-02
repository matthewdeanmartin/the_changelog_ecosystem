#!/usr/bin/env bash
# keepachangelog-manager-fork life-cycle driver.
#
# keepachangelog-manager-fork (PyPI: keepachangelog-manager-fork) is a CLI for
# managing Keep a Changelog format files. The CLI is `changelogmanager`.
#
# Life cycle:
#   Stage 1 — v1.0.0 code committed, no changelog yet.
#   Stage 2 — `changelogmanager create` initializes CHANGELOG.md; add entry for v1.0.0;
#              validate; release 1.0.0.
#   Stage 3 — Add the v2.0.0 feature entry via `changelogmanager add`.
#   Stage 4a — `changelogmanager release 2.0.0`; tag.
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
changelogmanager --version 2>/dev/null || python -c "import keepachangelog_manager; print('keepachangelog-manager-fork', keepachangelog_manager.__version__)" 2>/dev/null || echo "version not directly queryable"

# ---- STAGE 1: no changelog --------------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; python -m tipcalc
dump_changelog

# ---- STAGE 2: create + seed changelog for v1.0.0 ----------------------------
banner "STAGE 2: create CHANGELOG.md and release v1.0.0"
# Create a fresh changelog skeleton.
changelogmanager create
echo "--- after create ---"
dump_changelog

# Add the v1.0.0 feature entry to [Unreleased].
changelogmanager add --change-type added --message "Compute the tip and total for a single restaurant bill."

echo "--- after add ---"
dump_changelog

# Validate the format.
echo "--- changelogmanager validate ---"
changelogmanager validate || true

# Promote [Unreleased] to a versioned release.
changelogmanager release --override-version 1.0.0 --yes

git add -A && git commit -q -m "docs: add changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: add v2.0.0 entry -----------------------------------------------
banner "STAGE 3: implement even split, add entry to [Unreleased]"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

changelogmanager add --change-type added --message "Split the bill evenly among a fixed number of diners."
git add -A && git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: release v2.0.0 -----------------------------------------------
banner "STAGE 4a: release v2.0.0 via changelogmanager"
changelogmanager release --override-version 2.0.0 --yes
echo "--- changelogmanager validate (post-release) ---"
changelogmanager validate || true
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

changelogmanager add --change-type added --message "Split the bill unevenly using per-person weights; output now lists each diner's share."
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
changelogmanager release --override-version 3.0.0 --yes
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
