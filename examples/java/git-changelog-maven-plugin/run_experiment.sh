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

echo "Plugin: git-changelog-maven-plugin 2.2.11"
mvn --version

# ---- STAGE 1: v1.0.0 code, no changelog ------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
dump_changelog

# ---- STAGE 2: generate changelog from git history ---------------------------
banner "STAGE 2: generate changelog from git history"
mvn --batch-mode generate-resources 2>&1
dump_changelog

# ---- STAGE 3: implement even split ------------------------------------------
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2/Main.java src/main/java/tipcalc/Main.java
sed -i 's|<version>1\.0\.0</version>|<version>2.0.0</version>|' pom.xml
git add -A
git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: tag v2.0.0, regenerate changelog ----------------------------
banner "STAGE 4a: tag v2.0.0, regenerate changelog"
git tag v2.0.0
mvn --batch-mode generate-resources 2>&1
dump_changelog

# ---- STAGE 4b: implement uneven split, tag v3.0.0 --------------------------
banner "STAGE 4b: implement uneven split, tag v3.0.0"
cp $SCENARIO/versions/v3/Main.java src/main/java/tipcalc/Main.java
sed -i 's|<version>2\.0\.0</version>|<version>3.0.0</version>|' pom.xml
git add -A
git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0
mvn --batch-mode generate-resources 2>&1
dump_changelog

# ---- artifacts ---------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
