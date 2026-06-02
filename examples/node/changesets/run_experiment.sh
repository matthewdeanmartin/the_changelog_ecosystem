#!/usr/bin/env bash
# changesets life-cycle driver.
#
# Changesets is a file-based release intent workflow:
#   1. Contributors run `changeset add` to create a changeset file describing
#      intent (patch/minor/major + summary).
#   2. At release time, `changeset version` consumes changeset files, bumps
#      package.json versions, and writes CHANGELOG.md entries.
#   3. `changeset publish` publishes packages (skipped here).
#
# changeset add is interactive; we seed changeset files from scenario/ directly
# to simulate the contributor workflow without TTY interaction.
set -euo pipefail

exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}

SCENARIO=/work/scenario

cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "tool under test:"
changeset --version

# ---- STAGE 1: v1.0.0 committed ----------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; node src/index.js
dump_changelog

# ---- STAGE 2: initialize changesets -----------------------------------------
banner "STAGE 2: changeset init — set up .changeset/ config"
changeset init 2>&1 || echo "(init output above)"
git add -A && git commit -q -m "chore: initialize changesets"
echo "--- .changeset/config.json ---"
cat .changeset/config.json
dump_changelog

# ---- STAGE 3: add changeset for v2 feature, run version --------------------
banner "STAGE 3: add v2 changeset, implement even split"
cp $SCENARIO/versions/v2_index.js src/index.js
git add -A && git commit -q -m "feat: split the bill evenly among diners"

# Seed the changeset file (simulates `changeset add` contributor workflow)
mkdir -p .changeset
cp $SCENARIO/changeset_v2.md .changeset/even-split.md
git add -A && git commit -q -m "docs: add changeset for even split"

echo "--- changeset status ---"
changeset status 2>&1 || echo "(status above)"

echo "--- changeset version (bumps package.json + writes CHANGELOG.md) ---"
changeset version 2>&1 || echo "(version output above)"
dump_changelog

# ---- STAGE 4a: commit release -----------------------------------------------
banner "STAGE 4a: commit v2.0.0 release"
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: v3.0.0 uneven split ------------------------------------------
banner "STAGE 4b: add v3 changeset (major), version, release"
cp $SCENARIO/versions/v3_index.js src/index.js
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"

mkdir -p .changeset
cp $SCENARIO/changeset_v3.md .changeset/uneven-split.md
git add -A && git commit -q -m "docs: add changeset for uneven split"

changeset version 2>&1 || echo "(version output above)"
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- BONUS: show changeset status after release -----------------------------
banner "BONUS: changeset status after all releases"
changeset status 2>&1 || echo "(no pending changesets)"

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
