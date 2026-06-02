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

echo "changie version:"; changie --version

# STAGE 1: v1.0.0 code, no changelog
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
echo "program output:"; bash tipcalc.sh
dump_changelog

# STAGE 2: changie init + first fragment + batch v1.0.0
banner "STAGE 2: changie init, add fragment, batch v1.0.0"
changie init
# Copy our config over the default
cp $SCENARIO/changie.yaml .changie.yaml
mkdir -p .changes/unreleased
cp $SCENARIO/fragments/v1_added.yaml .changes/unreleased/v1_feat.yaml
git add -A && git commit -q -m "docs: add changelog fragment for v1.0.0"
echo "--- changie batch v1.0.0 ---"
changie batch v1.0.0
echo "--- .changes/v1.0.0.md ---"
cat .changes/v1.0.0.md
echo "--- changie merge ---"
changie merge
git add -A && git commit -q -m "chore(release): 1.0.0"
git tag v1.0.0
dump_changelog

# STAGE 3: v2 feature fragment
banner "STAGE 3: implement even split, add fragment"
cp $SCENARIO/versions/v2_tipcalc.sh tipcalc.sh
echo "program output:"; bash tipcalc.sh
mkdir -p .changes/unreleased
cp $SCENARIO/fragments/v2_added.yaml .changes/unreleased/v2_feat.yaml
git add -A && git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# STAGE 4a: batch + merge for v2.0.0
banner "STAGE 4a: batch + merge for v2.0.0"
changie batch v2.0.0
cat .changes/v2.0.0.md
changie merge
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# STAGE 4b: v3.0.0
banner "STAGE 4b: implement uneven split, add fragment, batch + merge v3.0.0"
cp $SCENARIO/versions/v3_tipcalc.sh tipcalc.sh
echo "program output:"; bash tipcalc.sh
mkdir -p .changes/unreleased
cp $SCENARIO/fragments/v3_added.yaml .changes/unreleased/v3_feat.yaml
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
changie batch v3.0.0
changie merge
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
