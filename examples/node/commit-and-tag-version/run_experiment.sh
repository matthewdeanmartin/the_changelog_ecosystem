#!/usr/bin/env bash
# commit-and-tag-version life-cycle driver.
#
# commit-and-tag-version is the actively maintained fork of standard-version.
# It bumps version in package.json, generates/updates CHANGELOG.md from
# conventional commits, commits the result, and creates a git tag.
#
# commit-and-tag-version --first-release   # tag v1.0.0 without bumping
# commit-and-tag-version                   # bump + changelog + commit + tag
# commit-and-tag-version --dry-run         # preview what would happen
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
commit-and-tag-version --version

# ---- STAGE 1: v1.0.0 committed ----------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
echo "program output:"; node src/index.js
dump_changelog

# ---- STAGE 2: first release -------------------------------------------------
banner "STAGE 2: commit-and-tag-version --first-release"
commit-and-tag-version --first-release --no-verify 2>&1
dump_changelog

# ---- STAGE 3: v2 feature ----------------------------------------------------
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_index.js src/index.js
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; node src/index.js

echo "--- dry-run preview ---"
commit-and-tag-version --dry-run 2>&1
dump_changelog

# ---- STAGE 4a: release v2.0.0 -----------------------------------------------
banner "STAGE 4a: commit-and-tag-version releases v2.0.0"
commit-and-tag-version --no-verify 2>&1
dump_changelog

# ---- STAGE 4b: v3.0.0 (breaking) --------------------------------------------
banner "STAGE 4b: implement uneven split (breaking), release v3.0.0"
cp $SCENARIO/versions/v3_index.js src/index.js
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
commit-and-tag-version --no-verify 2>&1
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
