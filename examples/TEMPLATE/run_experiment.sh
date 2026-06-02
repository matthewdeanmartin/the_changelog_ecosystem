#!/usr/bin/env bash
# TEMPLATE life-cycle driver. Copy and fill in the per-tool commands marked TODO.
# See examples/python/towncrier/run_experiment.sh for a complete worked example.
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work (never touch host git config).
#   - Walk 4 stages: no changelog -> created -> updated -> bump+release (x2).
#   - After each stage print a banner and dump the current CHANGELOG.
#   - Copy final artifacts + full transcript into /work/out.
#   - Exit non-zero if a required tool command fails.
#
# LESSONS BAKED IN (learned from the towncrier reference run):
#   1. scenario/ is baked at /work/scenario (sibling of the app). After `cd /work/app`
#      it is NOT relative — reference it via $SCENARIO (absolute).
#   2. Some tools delete consumed fragments with `git rm`. COMMIT new fragments/changes
#      BEFORE running the tool's build, or it errors mid-run on untracked files.
#   3. A tool that empties its fragment dir leaves it gone (git drops empty dirs); run
#      `mkdir -p <dir>` again before the next stage, or ship a .gitkeep.
#   4. Keep the working tree clean — the app/ has a .gitignore for __pycache__ so the
#      tool's `check`/diff inspection isn't polluted by build artifacts.
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}

# scenario/ lives at /work/scenario; reference it absolutely (we cd into the app repo).
SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false
echo "tool under test:"
# TODO: print the installed version, e.g.  towncrier --version
# REPLACE_ME --version

# ---- STAGE 1: no changelog --------------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; python -m tipcalc
dump_changelog

# ---- STAGE 2: changelog created ---------------------------------------------
banner "STAGE 2: create the first changelog for v1.0.0"
# TODO: initialize the tool and generate/assemble the first changelog. e.g.:
#   cat $SCENARIO/<tool>_config.toml >> pyproject.toml
#   mkdir -p newsfragments && cp $SCENARIO/fragments/v1/*.md newsfragments/
#   git add -A && git commit -q -m "docs: add news fragment for 1.0.0"   # commit BEFORE build (lesson 2)
#   <tool> build --version 1.0.0
git add -A && git commit -q -m "docs: add changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: changelog updated (toward v2.0.0) -----------------------------
banner "STAGE 3: implement even split, record the change"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc
# TODO: add the tool's change entry/fragment for the even-split feature.
#   mkdir -p newsfragments && cp $SCENARIO/fragments/v2/*.md newsfragments/   # (lesson 3)
git add -A && git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: version bump + release v2.0.0 --------------------------------
banner "STAGE 4a: assemble + release v2.0.0"
# TODO: run the tool's build/assemble to fold the change into CHANGELOG for 2.0.0.
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: second loop -> v3.0.0 (uneven split) ------------------------
banner "STAGE 4b: implement uneven split, assemble + release v3.0.0"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc
# TODO: add change entry/fragment (mkdir -p first), commit, then assemble for 3.0.0.
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
