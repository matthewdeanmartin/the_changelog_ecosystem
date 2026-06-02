#!/usr/bin/env bash
# versionize life-cycle driver.
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work/app (never touch host git config).
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

echo "tool under test:"
versionize --version || true

# ---- STAGE 1: no changelog --------------------------------------------------
banner "STAGE 1: v1.0.0 code committed, no changelog yet"

git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "git log:"
git log --oneline --decorate
dump_changelog

# ---- STAGE 2: changelog created for v1.0.0 ----------------------------------
banner "STAGE 2: run versionize for the first time -- creates CHANGELOG for v1.0.0"

# versionize reads from git history since the previous version tag.
# Since we already have v1.0.0 tagged, we need commits AFTER the last tag.
# Add a fix commit so versionize has something to process on top of v1.0.0,
# then let it bump to 1.0.1 and create the first CHANGELOG.
cat >> Program.cs << 'EOF'
// end of v1
EOF
git add -A
git commit -q -m "fix: remove trailing whitespace in output"

# Run versionize: it will bump 1.0.0 -> 1.0.1, write CHANGELOG, commit+tag.
# The tree must be clean before calling versionize (it checks for dirty state).
versionize
echo "git log after versionize:"
git log --oneline --decorate
dump_changelog

# ---- STAGE 3: update to v2 (even split) -------------------------------------
banner "STAGE 3: implement even split; commit v2 code"

cp $SCENARIO/versions/v2/Program.cs Program.cs
echo "program output preview:"
dotnet run --project TipCalc.csproj
git add -A
git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: versionize bumps to v2.0.0 -----------------------------------
banner "STAGE 4a: run versionize -- feat commit triggers minor bump to 2.0.0"

# versionize reads the feat: commit since the last tag (v1.0.1), bumps minor -> 2.0.0,
# updates CHANGELOG.md, auto-commits and auto-tags.
versionize
echo "git log after versionize:"
git log --oneline --decorate
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven weights) -------------------------------------
banner "STAGE 4b: implement uneven split, run versionize -- feat! triggers major bump to 3.0.0"

cp $SCENARIO/versions/v3/Program.cs Program.cs
echo "program output preview:"
dotnet run --project TipCalc.csproj
git add -A
git commit -q -m "feat!: split the bill unevenly by weight"

# feat! (breaking change) triggers major version bump: 2.0.0 -> 3.0.0.
versionize
echo "git log after versionize:"
git log --oneline --decorate
dump_changelog

# ---- dry-run demo -----------------------------------------------------------
banner "BONUS: versionize --dry-run demo (shows what would happen, no changes)"

# Add another small commit so dry-run has something to evaluate.
cat >> Program.cs << 'EOF'
// end of v3
EOF
git add -A
git commit -q -m "fix: add end-of-file comment"

versionize --dry-run || true
echo "(dry-run complete -- no files were changed)"
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE -- copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag                       > /work/out/git-tags.txt
echo "Artifacts in /work/out:"
ls -la /work/out
