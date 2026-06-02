#!/usr/bin/env bash
# conventional-changelog-cli life-cycle driver.
#
# conventional-changelog-cli generates a CHANGELOG.md from git history using
# conventional commit messages. It reads commits since the last tag and outputs
# grouped sections (feat, fix, etc.). No config file required for basic use;
# a .versionrc or package.json [standard-version] config can tune it.
#
# Commands used:
#   conventional-changelog -p angular -i CHANGELOG.md -s   # append/create
#   conventional-changelog -p angular -i CHANGELOG.md -s -r 0  # full history
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
conventional-changelog --version

# ---- STAGE 1: v1.0.0 committed and tagged -----------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; node src/index.js
dump_changelog

# ---- STAGE 2: generate CHANGELOG for v1.0.0 ---------------------------------
banner "STAGE 2: generate CHANGELOG.md from v1.0.0 history"
conventional-changelog -p angular -i CHANGELOG.md -s -r 0
git add -A && git commit -q -m "docs: add changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: v2.0.0 feature -----------------------------------------------
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_index.js src/index.js
sed -i 's/"version": "1.0.0"/"version": "2.0.0"/' package.json
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; node src/index.js

echo "--- preview unreleased (since v1.0.0) ---"
conventional-changelog -p angular -u
dump_changelog

# ---- STAGE 4a: release v2.0.0 -----------------------------------------------
banner "STAGE 4a: update CHANGELOG and tag v2.0.0"
conventional-changelog -p angular -i CHANGELOG.md -s
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_index.js src/index.js
sed -i 's/"version": "2.0.0"/"version": "3.0.0"/' package.json
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
conventional-changelog -p angular -i CHANGELOG.md -s
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
