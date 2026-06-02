#!/usr/bin/env bash
# release-it life-cycle driver.
#
# release-it is a generic release automation tool. With the
# @release-it/conventional-changelog plugin, it:
#   - generates/updates CHANGELOG.md from conventional commits
#   - bumps version in package.json (semver, auto-detected from commits)
#   - commits, tags, and optionally pushes/publishes
#
# We run with --no-npm.publish=false and git.push=false (in .release-it.json)
# so nothing actually publishes. We use --ci to suppress interactive prompts.
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

# Copy .release-it.json config
cp $SCENARIO/.release-it.json ./.release-it.json

echo "tool under test:"
release-it --version

# ---- STAGE 1: v1.0.0 committed and tagged -----------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; node src/index.js
dump_changelog

# ---- STAGE 2: generate initial CHANGELOG ------------------------------------
banner "STAGE 2: generate CHANGELOG.md for v1.0.0 (dry-run preview)"
echo "--- release-it dry-run to see what it would do ---"
release-it --ci --dry-run 2>&1 || echo "(dry-run above)"
dump_changelog

# ---- STAGE 3: v2.0.0 feature -----------------------------------------------
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_index.js src/index.js
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; node src/index.js

# ---- STAGE 4a: release v2.0.0 -----------------------------------------------
banner "STAGE 4a: release-it --ci releases v2.0.0"
release-it --ci 2>&1 || echo "(release-it output above)"
dump_changelog

# ---- STAGE 4b: v3.0.0 -------------------------------------------------------
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_index.js src/index.js
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
release-it --ci 2>&1 || echo "(release-it output above)"
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
