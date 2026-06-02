#!/usr/bin/env bash
# com.diffplug.spotless-changelog life-cycle driver.
#
# Contract:
#   - Build an ISOLATED git repo in /work/app (never touch host git).
#   - Walk through staged changelog + version scenarios.
#   - After each stage print a banner and dump the current CHANGELOG.md.
#   - Copy final artifacts + full transcript into /work/out.
#   - Exit non-zero only if a required tool command fails unexpectedly.
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

# Prepend a new [Unreleased] section at the top of the existing changelog
# (after the preamble lines, just before the first ## [ line).
# Replaces the empty ## [Unreleased] that changelogBump leaves behind if present.
prepend_unreleased() {
  local heading="$1"   # e.g. "### Added\n- Some feature"
  # Remove any existing empty ## [Unreleased] block that changelogBump leaves
  # (it leaves an empty ## [Unreleased] placeholder).
  # Then insert a fresh one with content before the first versioned section.
  awk -v content="$heading" '
BEGIN { removed_empty=0; inserted=0 }
# Skip an empty [Unreleased] block (line is "## [Unreleased]" followed by blank/version)
/^## \[Unreleased\]$/ && !removed_empty {
  removed_empty=1
  # Peek: just swallow this line; next non-blank line will tell us if it had content
  next
}
/^## \[/ && removed_empty && !inserted {
  # Insert our new unreleased block, then emit the versioned line
  print "## [Unreleased]\n"
  print content "\n"
  inserted=1
}
{ print }
' CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md
}

SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "Plugin under test: com.diffplug.spotless-changelog 3.1.2"
echo "Gradle: $(gradle --version 2>/dev/null | grep '^Gradle' | head -1)"
echo "Java:   $(java -version 2>&1 | head -1)"

# ---- Discover available changelog tasks -------------------------------------
banner "TASK DISCOVERY: gradle tasks --all | grep -i changelog"
gradle --no-daemon tasks --all 2>&1 | grep -i changelog || echo "(no changelog tasks found — plugin may not be loaded)"

# ---- STAGE 1: commit v1 code, no changelog ----------------------------------
banner "STAGE 1: v1 code committed, no CHANGELOG.md yet"
git add -A
git commit -q -m "feat: compute tip for a single bill"
echo "--- compiling and running v1 ---"
gradle --no-daemon --quiet compileJava
java -cp build/classes/java/main tipcalc.Main
dump_changelog

# ---- STAGE 2: copy seed changelog, validate, bump to first version ----------
banner "STAGE 2: add CHANGELOG.md, changelogCheck, changelogBump"
cp "$SCENARIO/CHANGELOG_seed.md" CHANGELOG.md
git add CHANGELOG.md
git commit -q -m "docs: initialize CHANGELOG.md with [Unreleased] for v1"
dump_changelog

echo "--- running: gradle changelogCheck (validate KAC structure) ---"
gradle --no-daemon changelogCheck
echo "(changelogCheck passed)"

echo "--- running: gradle changelogPrint (show computed next version) ---"
gradle --no-daemon changelogPrint

echo "--- running: gradle changelogBump (move [Unreleased] -> computed version, stamp date) ---"
gradle --no-daemon changelogBump
echo "(changelogBump done)"
dump_changelog

git add CHANGELOG.md
git commit -q -m "chore(release): changelog bump stage 2"
# Read computed version from the bumped CHANGELOG.md
STAGE2_VER=$(grep -m1 '^## \[[0-9]' CHANGELOG.md | sed 's/## \[\([^]]*\)\].*/\1/')
echo "Computed version: $STAGE2_VER"
git tag "v${STAGE2_VER}"
echo "Tagged v${STAGE2_VER}"
echo "--- git log so far ---"
git log --oneline --decorate

# ---- STAGE 3: v2 feature, add new [Unreleased] section ----------------------
banner "STAGE 3: implement even split, add [Unreleased] with ### Added"
cp "$SCENARIO/versions/v2/Main.java" src/main/java/tipcalc/Main.java

# After changelogBump, the file has an empty ## [Unreleased] at the top.
# We inject content into that placeholder.
# Strategy: replace the empty placeholder with a real one.
python3 - <<'PYEOF'
import re

with open("CHANGELOG.md", "r") as f:
    content = f.read()

new_unreleased = """## [Unreleased]

### Added
- Split the bill evenly among 4 diners

"""

# Replace empty [Unreleased] block (## [Unreleased] followed immediately by blank line then another ##)
content = re.sub(r'## \[Unreleased\]\n\n(?=## \[)', new_unreleased, content, count=1)

with open("CHANGELOG.md", "w") as f:
    f.write(content)

print("Injected new [Unreleased] section")
PYEOF

git add -A
git commit -q -m "feat: split bill evenly among diners"
echo "--- compiling and running v2 ---"
gradle --no-daemon --quiet compileJava
java -cp build/classes/java/main tipcalc.Main
dump_changelog

# ---- STAGE 4a: changelogBump (minor bump for Added) -------------------------
banner "STAGE 4a: changelogCheck + changelogBump (Added -> minor bump)"
echo "--- running: gradle changelogCheck ---"
gradle --no-daemon changelogCheck
echo "(changelogCheck passed)"

echo "--- running: gradle changelogPrint ---"
gradle --no-daemon changelogPrint

echo "--- running: gradle changelogBump ---"
gradle --no-daemon changelogBump
echo "(changelogBump done)"
dump_changelog

git add CHANGELOG.md
git commit -q -m "chore(release): changelog bump stage 4a"
STAGE4A_VER=$(grep -m1 '^## \[[0-9]' CHANGELOG.md | sed 's/## \[\([^]]*\)\].*/\1/')
echo "Computed version: $STAGE4A_VER"
git tag "v${STAGE4A_VER}"
echo "Tagged v${STAGE4A_VER}"
echo "--- git log so far ---"
git log --oneline --decorate

# ---- STAGE 4b: v3 breaking change -> major bump ----------------------------
banner "STAGE 4b: uneven split with **BREAKING** marker -> major bump"
cp "$SCENARIO/versions/v3/Main.java" src/main/java/tipcalc/Main.java

python3 - <<'PYEOF'
import re

with open("CHANGELOG.md", "r") as f:
    content = f.read()

new_unreleased = """## [Unreleased]

### Changed
- **BREAKING** Split API now accepts per-person weights instead of equal split

### Added
- Weighted bill split (Ada:3, Linus:2, Grace:3, Dennis:2)

"""

content = re.sub(r'## \[Unreleased\]\n\n(?=## \[)', new_unreleased, content, count=1)

with open("CHANGELOG.md", "w") as f:
    f.write(content)

print("Injected breaking-change [Unreleased] section")
PYEOF

git add -A
git commit -q -m "feat!: weighted bill split by person"
echo "--- compiling and running v3 ---"
gradle --no-daemon --quiet compileJava
java -cp build/classes/java/main tipcalc.Main
dump_changelog

echo "--- running: gradle changelogCheck ---"
gradle --no-daemon changelogCheck
echo "(changelogCheck passed)"

echo "--- running: gradle changelogPrint (should show major bump due to **BREAKING**) ---"
gradle --no-daemon changelogPrint

echo "--- running: gradle changelogBump ---"
gradle --no-daemon changelogBump
echo "(changelogBump done)"
dump_changelog

git add CHANGELOG.md
git commit -q -m "chore(release): changelog bump stage 4b"
STAGE4B_VER=$(grep -m1 '^## \[[0-9]' CHANGELOG.md | sed 's/## \[\([^]]*\)\].*/\1/')
echo "Computed version: $STAGE4B_VER"
git tag "v${STAGE4B_VER}"
echo "Tagged v${STAGE4B_VER}"

# ---- STAGE 5: changelogPush (expected to fail — no remote) ------------------
banner "STAGE 5: changelogPush (expected to fail — no remote configured)"
echo "--- running: gradle changelogPush ---"
# changelogPush tries to commit, tag, and push; it will fail on no remote
gradle --no-daemon changelogPush 2>&1 || echo "(changelogPush failed — no remote configured; this is expected in a CI/local experiment)"

# ---- Final git log ----------------------------------------------------------
banner "DONE — final git log"
git log --oneline --decorate

# ---- artifacts --------------------------------------------------------------
banner "Copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"
ls -la /work/out
