#!/usr/bin/env bash
# org.jetbrains.changelog life-cycle driver.
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work/app (never touch host git).
#   - Walk 4 stages: no changelog -> created -> updated -> bump+release (x2).
#   - After each stage print a banner and dump the current CHANGELOG.md.
#   - Copy final artifacts + full transcript into /work/out.
#   - Exit non-zero if a required tool command fails.
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then
    echo "----- CHANGELOG.md -----"
    cat CHANGELOG.md
    echo "------------------------"
  else
    echo "(no CHANGELOG.md yet)"
  fi
}

# $SCENARIO/ is baked at /work/scenario (sibling of the app), so reference it by
# absolute path: we `cd` into the app repo and must not assume scenario is relative.
SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "Plugin under test: org.jetbrains.changelog 2.5.0"
echo "Gradle: $(gradle --version 2>/dev/null | grep '^Gradle' | head -1)"
echo "Java: $(java -version 2>&1 | head -1)"

# ---- STAGE 1: v1.0.0 code, no changelog ------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
echo "--- compiling and running v1 ---"
gradle --no-daemon --quiet compileJava
java -cp build/classes/java/main tipcalc.Main
dump_changelog

# ---- STAGE 2: create changelog, patch for v1.0.0 ----------------------------
banner "STAGE 2: initialize changelog and patchChangelog for v1.0.0"
cp "$SCENARIO/CHANGELOG_v1.md" CHANGELOG.md
git add CHANGELOG.md
git commit -q -m "docs: initialize changelog with [Unreleased] for v1.0.0"
dump_changelog

echo "--- running: gradle getChangelog (extract [Unreleased] section) ---"
gradle --no-daemon getChangelog || echo "(getChangelog exited non-zero — informational)"

echo "--- running: gradle patchChangelog (moves [Unreleased] -> [1.0.0]) ---"
gradle --no-daemon patchChangelog
dump_changelog

git add CHANGELOG.md
git commit -q -m "chore(release): 1.0.0"
git tag v1.0.0
echo "Tagged v1.0.0"

# ---- STAGE 3: v2 feature, update [Unreleased] --------------------------------
banner "STAGE 3: implement even split, add [Unreleased] for 2.0.0"
cp "$SCENARIO/versions/v2/Main.java" src/main/java/tipcalc/Main.java

# Update version in build.gradle.kts using sed
sed -i 's/version = "1.0.0"/version = "2.0.0"/' build.gradle.kts

# Insert [Unreleased] section at the top of the changelog (after the header line)
# We use awk to insert before the first ## [ line
awk '
/^## \[/ && !inserted {
  print "## [Unreleased]\n\n### Added\n- Split the bill evenly among 4 diners\n"
  inserted = 1
}
{ print }
' CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md

git add -A
git commit -q -m "feat: split the bill evenly among diners"
echo "--- compiling and running v2 ---"
gradle --no-daemon --quiet compileJava
java -cp build/classes/java/main tipcalc.Main
dump_changelog

# ---- STAGE 4a: patchChangelog for v2.0.0 ------------------------------------
banner "STAGE 4a: patchChangelog and release v2.0.0"
echo "--- running: gradle patchChangelog (moves [Unreleased] -> [2.0.0]) ---"
gradle --no-daemon patchChangelog
dump_changelog

git add CHANGELOG.md
git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
echo "Tagged v2.0.0"

# ---- STAGE 4b: v3 feature, patchChangelog for v3.0.0 ------------------------
banner "STAGE 4b: implement uneven split, patchChangelog and release v3.0.0"
cp "$SCENARIO/versions/v3/Main.java" src/main/java/tipcalc/Main.java

# Update version to 3.0.0
sed -i 's/version = "2.0.0"/version = "3.0.0"/' build.gradle.kts

# Insert [Unreleased] section at the top again
awk '
/^## \[/ && !inserted {
  print "## [Unreleased]\n\n### Added\n- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2)\n"
  inserted = 1
}
{ print }
' CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md

git add -A
git commit -q -m "feat!: split the bill unevenly by weight"
echo "--- compiling and running v3 ---"
gradle --no-daemon --quiet compileJava
java -cp build/classes/java/main tipcalc.Main
dump_changelog

echo "--- running: gradle patchChangelog (moves [Unreleased] -> [3.0.0]) ---"
gradle --no-daemon patchChangelog
dump_changelog

git add CHANGELOG.md
git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
echo "Tagged v3.0.0"

# ---- STAGE 5: demonstrate getChangelog for a specific version ----------------
banner "STAGE 5: getChangelog for specific versions"
echo "--- getChangelog for current version (3.0.0) ---"
gradle --no-daemon getChangelog || echo "(getChangelog exited non-zero)"

# Show the final git log
banner "DONE — git log"
git log --oneline --decorate

# ---- artifacts --------------------------------------------------------------
banner "Copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"
ls -la /work/out
