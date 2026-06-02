#!/usr/bin/env bash
# release-plz life-cycle driver.
#
# release-plz is a CI-oriented tool: its primary workflow opens GitHub/GitLab
# release PRs and publishes crates. The commands we can run locally without
# credentials are:
#   - `release-plz update` — bumps versions and updates CHANGELOG.md locally
#   - `release-plz changelog` — generates changelog text for a package
#
# We simulate the local part of the workflow: run `release-plz update` to see
# what it writes, then manually tag to advance the scenario.
#
# NOTE: `release-plz release-pr` and `release-plz release` require GitHub
# tokens and a GitHub remote — those are out of scope for a local experiment.
set -euo pipefail

exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}

SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "tool under test:"
release-plz --version

# Copy release-plz.toml and cliff.toml into the app.
cp $SCENARIO/release-plz.toml ./release-plz.toml
cp $SCENARIO/cliff.toml ./cliff.toml

# Need a Cargo.lock for release-plz to work.
cargo generate-lockfile -q 2>/dev/null || true

# ---- STAGE 1: v1.0.0 committed and tagged ------------------------------------
banner "STAGE 1: v1.0.0 code, tagged — baseline for release-plz"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
dump_changelog

# ---- STAGE 2: release-plz changelog command ----------------------------------
banner "STAGE 2: release-plz changelog — show changelog for current crate"
echo "--- release-plz changelog ---"
release-plz changelog 2>&1 || echo "(release-plz changelog output above)"
dump_changelog

# ---- STAGE 3: implement v2.0.0, run release-plz update ----------------------
banner "STAGE 3: implement even split; run release-plz update"
cp $SCENARIO/versions/v2_main.rs src/main.rs
git add -A && git commit -q -m "feat: split the bill evenly among diners"

echo "--- release-plz update (bumps version + generates CHANGELOG.md) ---"
release-plz update 2>&1 || echo "(release-plz update output above)"
dump_changelog

# ---- STAGE 4a: tag v2.0.0 ---------------------------------------------------
banner "STAGE 4a: commit + tag v2.0.0"
# release-plz update modified Cargo.toml and CHANGELOG.md; commit and tag.
git add -A && git commit -q -m "chore(release): 2.0.0" 2>/dev/null || git add -A
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split; release-plz update for v3.0.0"
cp $SCENARIO/versions/v3_main.rs src/main.rs
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
echo "--- release-plz update for v3.0.0 ---"
release-plz update 2>&1 || echo "(release-plz update output above)"
git add -A && git commit -q -m "chore(release): 3.0.0" 2>/dev/null || git add -A
git tag v3.0.0
dump_changelog

# ---- bonus: show what release-pr would create --------------------------------
banner "BONUS: release-plz commands that need GitHub (not runnable locally)"
echo "Commands that require GitHub token and remote (shown for reference):"
echo "  release-plz release-pr  # opens a release PR on GitHub"
echo "  release-plz release      # publishes crates after PR merge"
echo ""
echo "Local-only commands demonstrated above:"
echo "  release-plz update       # bumps Cargo.toml version + updates CHANGELOG.md"
echo "  release-plz changelog    # generates/shows changelog text"

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
