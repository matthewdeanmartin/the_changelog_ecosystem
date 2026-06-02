#!/usr/bin/env bash
# nerdbank-gitversioning (nbgv) life-cycle driver.
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work/app (never touch host git config).
#   - Walk life-cycle stages showing how nbgv computes versions from commit height.
#   - After each stage print a banner and show the current nbgv version output.
#   - Copy final artifacts + full transcript into /work/out.
#   - Exit non-zero if a required tool command fails.
#
# NOTE: nbgv is version INFRASTRUCTURE, not a changelog writer.
#   - It does NOT generate CHANGELOG.md.
#   - Versions are derived from version.json + git commit height (commits since last
#     version increment), not from commit message conventions.
#   - "Commit height" increments automatically with each commit; to bump the major/minor
#     you edit version.json (or use `nbgv set-version`).
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_version() {
  echo "----- nbgv get-version -----"
  nbgv get-version 2>/dev/null || echo "(nbgv get-version failed — not yet in a git repo?)"
  echo "----------------------------"
}
dump_version_json() {
  echo "----- nbgv get-version -f json -----"
  nbgv get-version -f json 2>/dev/null || echo "(nbgv get-version -f json failed)"
  echo "------------------------------------"
}

# $SCENARIO/ is baked at /work/scenario (sibling of the app), so reference it by
# absolute path: we `cd` into the app repo and must not assume scenario is relative.
SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
banner "SETUP: initialising isolated git repo in /work/app"
cd /work/app
git init -q
git checkout -b main
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "nbgv version:"
nbgv --version

# ---- STAGE 1: v1 code + version.json, first commit -------------------------
banner "STAGE 1: v1 code committed — nbgv shows commit-height-based version"
# Drop version.json from scenario into the repo root.
cp "$SCENARIO/version.json" version.json
git add -A
git commit -q -m "feat: compute tip for a single bill"

echo ""
echo "NOTE: nbgv derives version as <major>.<minor>.<commitHeight>"
echo "      where commitHeight = number of commits since last version.json change."
echo "      On the first commit the height is typically 1."
echo ""
dump_version
dump_version_json

# ---- STAGE 2: v2 code committed, height increases --------------------------
banner "STAGE 2: v2 code committed — commit height increases"
cp "$SCENARIO/versions/v2/Program.cs" Program.cs
git add -A
git commit -q -m "feat: split the bill evenly among diners"

echo ""
echo "NOTE: We are still on version.json '1.0', so the minor stays 0."
echo "      The third segment (commit height) increments."
echo ""
dump_version
dump_version_json

# ---- STAGE 3: prepare-release — cuts release branch, bumps version.json ---
banner "STAGE 3: nbgv prepare-release — creates release branch, bumps version.json for next dev"
echo ""
echo "NOTE: prepare-release creates a 'v1.0' release branch from the current HEAD"
echo "      and increments version.json to '1.1' on the current (main) branch."
echo "      This is how nbgv manages the release/development split."
echo ""
# prepare-release exits 0 on success; it modifies version.json and may create a branch.
nbgv prepare-release

echo ""
echo "--- version.json after prepare-release ---"
cat version.json
echo "------------------------------------------"

# prepare-release already commits the version.json change on main, so we only
# need to commit if there are uncommitted changes.
if ! git diff --cached --quiet || ! git diff --quiet; then
  git add -A
  git commit -q -m "chore: bump version to 1.1 after prepare-release"
fi

dump_version

# ---- STAGE 4: v3 code on main (now tracking 1.1) ---------------------------
banner "STAGE 4: v3 code committed on main — now showing 1.1.x"
cp "$SCENARIO/versions/v3/Program.cs" Program.cs
git add -A
git commit -q -m "feat!: split the bill unevenly by weight"

echo ""
echo "NOTE: After prepare-release bumped version.json to '1.1',"
echo "      new commits on main are now stamped 1.1.<height>."
echo ""
dump_version
dump_version_json

# ---- STAGE 5: manually set version to 2.0 to demonstrate set-version -------
banner "STAGE 5: nbgv set-version 2.0 — demonstrate manual version bump"
nbgv set-version 2.0
echo ""
echo "--- version.json after set-version 2.0 ---"
cat version.json
echo "-------------------------------------------"
git add -A
git commit -q -m "chore: bump to 2.0 for breaking change release"

dump_version
dump_version_json

# ---- git log ----------------------------------------------------------------
banner "GIT LOG"
git log --oneline --decorate

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
# nbgv does not write CHANGELOG.md; capture the version JSON output as the artifact.
nbgv get-version -f json > /work/out/version_info.json
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt 2>/dev/null || true
cat version.json > /work/out/version.json

echo "Artifacts in /work/out:"
ls -la /work/out
