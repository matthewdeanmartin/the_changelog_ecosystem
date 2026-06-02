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

echo "git-chglog version:"; git-chglog --version

# STAGE 1
banner "STAGE 1: v1.0.0 code, NO changelog"
mkdir -p .chglog
cp $SCENARIO/config.yml .chglog/config.yml
cp $SCENARIO/CHANGELOG.tpl.md .chglog/CHANGELOG.tpl.md
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; bash tipcalc.sh
dump_changelog

# STAGE 2: generate changelog for v1.0.0
banner "STAGE 2: git-chglog for v1.0.0"
git-chglog --output CHANGELOG.md v1.0.0
git add -A && git commit -q -m "docs: add changelog"
dump_changelog

# STAGE 3: v2 feature
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_tipcalc.sh tipcalc.sh
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; bash tipcalc.sh
dump_changelog

# STAGE 4a: tag + regenerate
banner "STAGE 4a: tag v2.0.0, regenerate changelog"
git tag v2.0.0
git-chglog --output CHANGELOG.md
git add -A && git commit -q -m "chore(release): 2.0.0"
dump_changelog

# STAGE 4b: v3.0.0
banner "STAGE 4b: implement uneven split, breaking change"
cp $SCENARIO/versions/v3_tipcalc.sh tipcalc.sh
git add -A && git commit -q -m "feat!: split the bill unevenly by weight

BREAKING CHANGE: output format changes — per-person amounts replace single total line"
git tag v3.0.0
git-chglog --output CHANGELOG.md
git add -A && git commit -q -m "chore(release): 3.0.0"
dump_changelog

banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
