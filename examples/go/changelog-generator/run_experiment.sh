#!/usr/bin/env bash
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
git config user.name "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "changelog-generator version:"
changelog-generator --version 2>&1 || changelog-generator version 2>&1 || true
echo "help:"
changelog-generator --help 2>&1 | head -60

# STAGE 1
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; bash tipcalc.sh
dump_changelog

# STAGE 2: generate changelog for v1.0.0
banner "STAGE 2: generate changelog for v1.0.0"
echo "--- attempting: changelog-generator (no args) ---"
changelog-generator 2>&1 || true
echo "--- attempting: changelog-generator --output CHANGELOG.md ---"
changelog-generator --output CHANGELOG.md 2>&1 || true
echo "--- attempting: changelog-generator -o CHANGELOG.md ---"
changelog-generator -o CHANGELOG.md 2>&1 || true
dump_changelog

# STAGE 3
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_tipcalc.sh tipcalc.sh
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; bash tipcalc.sh

# STAGE 4a
banner "STAGE 4a: tag v2.0.0, regenerate changelog"
git tag v2.0.0
echo "--- changelog-generator --output CHANGELOG.md ---"
changelog-generator --output CHANGELOG.md 2>&1 || changelog-generator -o CHANGELOG.md 2>&1 || changelog-generator > CHANGELOG.md 2>&1 || true
dump_changelog

# STAGE 4b
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_tipcalc.sh tipcalc.sh
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0
echo "--- changelog-generator --output CHANGELOG.md ---"
changelog-generator --output CHANGELOG.md 2>&1 || changelog-generator -o CHANGELOG.md 2>&1 || changelog-generator > CHANGELOG.md 2>&1 || true
dump_changelog

banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
