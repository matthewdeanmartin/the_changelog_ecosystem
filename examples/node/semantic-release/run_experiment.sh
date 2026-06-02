#!/usr/bin/env bash
# semantic-release life-cycle driver.
#
# semantic-release is a FULLY AUTOMATED release tool: it determines version,
# generates changelog, commits, tags, and publishes — all from CI. It is
# designed to run in CI (GitHub Actions, etc.) and requires:
#   - A git remote (or GITHUB_TOKEN / GIT_AUTHOR_NAME env vars)
#   - npm registry access (suppressed via npmPublish: false)
#
# What we CAN demonstrate locally:
#   - semantic-release --dry-run — shows what it would do without executing
#   - The .releaserc.json config structure
#   - How conventional commits drive version determination
#
# What we CANNOT demonstrate without CI:
#   - Actual release (requires remote + git auth)
#   - GitHub Release creation
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
git checkout -b main 2>/dev/null || true

cp $SCENARIO/.releaserc.json ./.releaserc.json

echo "tool under test:"
semantic-release --version

echo ""
echo "NOTE: semantic-release is a CI-native tool."
echo "      Dry-run mode shows what it would do; actual release requires a remote."

# ---- STAGE 1: v1.0.0 committed ----------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
echo "program output:"; node src/index.js
dump_changelog

# ---- STAGE 2: dry-run to see version determination --------------------------
banner "STAGE 2: semantic-release --dry-run (shows what v1 release would do)"
GIT_AUTHOR_NAME="Experiment Bot" GIT_AUTHOR_EMAIL="bot@example.invalid" \
GIT_COMMITTER_NAME="Experiment Bot" GIT_COMMITTER_EMAIL="bot@example.invalid" \
  semantic-release --dry-run --no-ci 2>&1 || echo "(dry-run output above)"
dump_changelog

# ---- STAGE 3: v2 feature committed -------------------------------------------
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_index.js src/index.js
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; node src/index.js

echo "--- semantic-release --dry-run (v2 detection) ---"
GIT_AUTHOR_NAME="Experiment Bot" GIT_AUTHOR_EMAIL="bot@example.invalid" \
GIT_COMMITTER_NAME="Experiment Bot" GIT_COMMITTER_EMAIL="bot@example.invalid" \
  semantic-release --dry-run --no-ci 2>&1 || echo "(dry-run above)"
dump_changelog

# ---- STAGE 4a: show what breaking change detection looks like ----------------
banner "STAGE 4a: implement uneven split (breaking), dry-run v3 detection"
cp $SCENARIO/versions/v3_index.js src/index.js
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"

echo "--- semantic-release --dry-run (breaking change = major bump) ---"
GIT_AUTHOR_NAME="Experiment Bot" GIT_AUTHOR_EMAIL="bot@example.invalid" \
GIT_COMMITTER_NAME="Experiment Bot" GIT_COMMITTER_EMAIL="bot@example.invalid" \
  semantic-release --dry-run --no-ci 2>&1 || echo "(dry-run above)"
dump_changelog

# ---- BONUS: show .releaserc.json config --------------------------------------
banner "BONUS: .releaserc.json config used"
cat .releaserc.json

# ---- note on what requires CI -----------------------------------------------
banner "NOTE: what requires a real CI environment"
echo "The following require a git remote, GITHUB_TOKEN, and CI:"
echo "  semantic-release          # actual release"
echo "  semantic-release --ci     # explicit CI mode"
echo ""
echo "Local-demonstrable:"
echo "  semantic-release --dry-run --no-ci  # version analysis + changelog preview"

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
