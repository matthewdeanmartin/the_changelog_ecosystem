#!/usr/bin/env bash
# standard-version life-cycle driver.
#
# standard-version is UNMAINTAINED (last release 2022). This experiment
# documents what it does, whether it still works on Node 20, and confirms
# the "use commit-and-tag-version instead" recommendation.
#
# standard-version --first-release  — tag first release without bumping version
# standard-version                  — bump version, generate changelog, commit, tag
# standard-version --dry-run        — preview
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
standard-version --version

echo ""
echo "NOTE: standard-version is UNMAINTAINED since 2022."
echo "      The recommended replacement is commit-and-tag-version."

# ---- STAGE 1: v1.0.0 committed and tagged -----------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
echo "program output:"; node src/index.js
dump_changelog

# ---- STAGE 2: first release (tag v1.0.0, create CHANGELOG) -----------------
banner "STAGE 2: standard-version --first-release"
standard-version --first-release --no-verify 2>&1 || \
  standard-version --first-release 2>&1 || \
  echo "(first-release failed — see above)"
dump_changelog

# ---- STAGE 3: v2.0.0 feature -----------------------------------------------
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_index.js src/index.js
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; node src/index.js

echo "--- standard-version --dry-run ---"
standard-version --dry-run 2>&1 || echo "(dry-run above)"
dump_changelog

# ---- STAGE 4a: release v2.0.0 -----------------------------------------------
banner "STAGE 4a: standard-version releases v2.0.0"
standard-version --no-verify 2>&1 || standard-version 2>&1 || echo "(failed)"
dump_changelog

# ---- STAGE 4b: v3.0.0 -------------------------------------------------------
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_index.js src/index.js
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
standard-version --no-verify 2>&1 || standard-version 2>&1 || echo "(failed)"
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
