#!/usr/bin/env bash
# towncrier life-cycle driver (reference implementation).
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work (never touch host git config).
#   - Walk 4 stages: no changelog -> created -> updated -> bump+release (x2).
#   - After each stage print a banner and dump the current CHANGELOG.
#   - Copy final artifacts + full transcript into /work/out.
#   - Exit non-zero if a required tool command fails.
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}
show_fragments() {
  echo "newsfragments/:"; ls -1 newsfragments 2>/dev/null || echo "  (none)"
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
towncrier --version

# ---- STAGE 1: no changelog --------------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; python -m tipcalc
dump_changelog

# ---- STAGE 2: changelog created ---------------------------------------------
banner "STAGE 2: configure towncrier + build the first changelog for v1.0.0"
# Append the towncrier config to pyproject.toml.
cat $SCENARIO/towncrier_config.toml >> pyproject.toml
# Drop the v1 news fragment into the fragments dir towncrier reads.
mkdir -p newsfragments
cp $SCENARIO/fragments/v1/*.md newsfragments/
show_fragments
# FINDING: towncrier removes consumed fragments via `git rm`, so fragments must be
# committed (git-tracked) BEFORE `towncrier build`, or build prints a noisy
# "fatal: No pathspec was given" while still writing the newsfile. Commit first.
git add -A && git commit -q -m "docs: add news fragment for 1.0.0 feature"
# Build: towncrier consumes the fragments and writes CHANGELOG.md for 1.0.0.
# --yes confirms fragment deletion non-interactively; --date pins a deterministic date.
towncrier build --yes --version 1.0.0 --date 2026-01-01
show_fragments
git add -A && git commit -q -m "docs: add changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: changelog updated (toward v2.0.0) -----------------------------
banner "STAGE 3: implement even split, add a news fragment (no build yet)"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc
mkdir -p newsfragments   # towncrier emptied it on the previous build; git drops empty dirs
cp $SCENARIO/fragments/v2/*.md newsfragments/
show_fragments
# 'towncrier build --draft' previews the next release notes WITHOUT consuming fragments.
echo "--- draft preview of pending 2.0.0 notes ---"
towncrier build --draft --version 2.0.0
git add -A && git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: version bump + release v2.0.0 --------------------------------
banner "STAGE 4a: build + release v2.0.0"
towncrier build --yes --version 2.0.0 --date 2026-02-01
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: second loop -> v3.0.0 (uneven split) ------------------------
banner "STAGE 4b: implement uneven split, build + release v3.0.0"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc
mkdir -p newsfragments   # recreate after the previous build emptied it
cp $SCENARIO/fragments/v3/*.md newsfragments/
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
show_fragments
# Demonstrate the CI gate: 'towncrier check' verifies a fragment exists vs a base ref.
echo "--- towncrier check (CI gate) against v2.0.0 ---"
towncrier check --compare-with v2.0.0 || echo "(check returned non-zero — informational)"
towncrier build --yes --version 3.0.0 --date 2026-03-01
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
