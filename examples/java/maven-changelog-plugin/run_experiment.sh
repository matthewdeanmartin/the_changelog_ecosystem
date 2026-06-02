#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }

dump_changelog() {
  if [ -f target/site/changelog.html ]; then
    echo "----- changelog.html (text excerpt) -----"
    head -100 target/site/changelog.html | sed 's/<[^>]*>//g' | grep -v '^$' | head -30
    echo "------------------------"
  elif [ -f CHANGELOG.md ]; then
    echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------"
  else
    echo "(no changelog output yet)"
  fi
}

dump_site_reports() {
  echo "--- Reports in target/site/ ---"
  if [ -d target/site ]; then
    ls -1 target/site/*.html 2>/dev/null || echo "(no HTML files)"
  else
    echo "(target/site/ does not exist)"
  fi
}

SCENARIO=/work/scenario
cd /work/app

git init -q
git config user.name "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "Plugin: maven-changelog-plugin 2.3"
mvn --version

# ---- STAGE 1: v1.0.0 code, git init -----------------------------------------
banner "STAGE 1: v1.0.0 code, initial commit, tag v1.0.0"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "Git log after stage 1:"
git log --oneline --decorate
dump_changelog

# ---- STAGE 2: run changelog:changelog after v1 only -------------------------
banner "STAGE 2: mvn changelog:changelog (1 commit)"
echo "Running: mvn --batch-mode changelog:changelog"
mvn --batch-mode changelog:changelog 2>&1 || true
dump_changelog
dump_site_reports

# ---- STAGE 3: v2 commit ------------------------------------------------------
banner "STAGE 3: implement even split — v2 commit"
cp $SCENARIO/versions/v2/Main.java src/main/java/tipcalc/Main.java
sed -i 's|<version>1\.0\.0</version>|<version>2.0.0</version>|' pom.xml
git add -A
git commit -q -m "feat: split the bill evenly among diners"
git tag v2.0.0
echo "Git log after stage 3:"
git log --oneline --decorate

# ---- STAGE 4a: changelog after v2 -------------------------------------------
banner "STAGE 4a: mvn changelog:changelog (2 commits)"
echo "Running: mvn --batch-mode changelog:changelog"
mvn --batch-mode changelog:changelog 2>&1 || true
dump_changelog
dump_site_reports

# ---- STAGE 4b: v3 commit, dev-activity report -------------------------------
banner "STAGE 4b: implement uneven split — v3 commit + dev-activity"
cp $SCENARIO/versions/v3/Main.java src/main/java/tipcalc/Main.java
sed -i 's|<version>2\.0\.0</version>|<version>3.0.0</version>|' pom.xml
git add -A
git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0
echo "Git log after stage 4b:"
git log --oneline --decorate

echo ""
echo "Running: mvn --batch-mode changelog:changelog"
mvn --batch-mode changelog:changelog 2>&1 || true
dump_changelog
dump_site_reports

echo ""
echo "Running: mvn --batch-mode changelog:dev-activity"
mvn --batch-mode changelog:dev-activity 2>&1 || true

echo ""
echo "--- dev-activity.html (text excerpt) ---"
if [ -f target/site/dev-activity.html ]; then
  head -100 target/site/dev-activity.html | sed 's/<[^>]*>//g' | grep -v '^$' | head -30
else
  echo "(no dev-activity.html)"
fi

# ---- STAGE 5: attempt full site generation ----------------------------------
banner "STAGE 5: mvn site (full site generation with all reports)"
echo "Running: mvn --batch-mode site 2>&1"
mvn --batch-mode site 2>&1 || true
dump_changelog
dump_site_reports

# ---- artifacts ---------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f target/site/changelog.html /work/out/changelog.html 2>/dev/null || true
cp -f target/site/dev-activity.html /work/out/dev-activity.html 2>/dev/null || true
cp -f target/site/file-activity.html /work/out/file-activity.html 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
