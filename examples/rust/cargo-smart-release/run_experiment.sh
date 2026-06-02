#!/usr/bin/env bash
# cargo-smart-release life-cycle driver.
#
# cargo-smart-release provides two key commands:
#   - `cargo changelog --write <crate>` — scaffolds changelog from git history
#   - `cargo smart-release <crate>` — simulates the release (default: dry run)
#
# Both commands operate on the *current working directory* as a Cargo workspace.
# In dry-run mode (default), nothing is published or tagged; the simulation output
# describes what would happen.
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
cargo smart-release --version 2>/dev/null || \
  cargo changelog --version 2>/dev/null || \
  echo "cargo-smart-release $(cargo install --list | grep cargo-smart-release | head -1)"

# ---- STAGE 1: v1.0.0 committed -----------------------------------------------
banner "STAGE 1: v1.0.0 code, tagged"
cargo generate-lockfile -q 2>/dev/null || true
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
dump_changelog

# ---- STAGE 2: cargo changelog scaffold ---------------------------------------
banner "STAGE 2: cargo changelog --write tipcalc"
echo "--- cargo changelog --write tipcalc ---"
echo "(Note: immediately after tagging v1.0.0, the tool reports 'no changes' since HEAD == tag)"
echo "--- attempting cargo changelog preview (no --write) ---"
cargo changelog tipcalc 2>&1 || echo "(cargo changelog preview failed — expected: no commits beyond the tag)"
dump_changelog

# ---- STAGE 3: implement v2.0.0 -----------------------------------------------
banner "STAGE 3: implement even split; add commit"
cp $SCENARIO/versions/v2_main.rs src/main.rs
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat: split the bill evenly among diners"

echo "--- cargo changelog --write tipcalc (after new commit) ---"
cargo changelog --write tipcalc --allow-dirty 2>&1 || echo "(cargo changelog failed)"
dump_changelog

# ---- STAGE 4a: smart-release dry-run for v2.0.0 ------------------------------
banner "STAGE 4a: cargo smart-release --bump minor tipcalc (dry-run)"
echo "--- cargo smart-release dry-run ---"
cargo smart-release --bump minor --allow-dirty tipcalc 2>&1 || echo "(cargo smart-release dry-run output above)"
git add -A && git commit -q -m "chore: update changelog for 2.0.0" 2>/dev/null || true
git tag v2.0.0 2>/dev/null || true
dump_changelog

# ---- STAGE 4b: v3.0.0 --------------------------------------------------------
banner "STAGE 4b: implement uneven split; cargo changelog for v3.0.0"
cp $SCENARIO/versions/v3_main.rs src/main.rs
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
cargo changelog --write tipcalc --allow-dirty 2>&1 || echo "(cargo changelog failed)"
git add -A && git commit -q -m "chore: update changelog for 3.0.0" 2>/dev/null || true
git tag v3.0.0 2>/dev/null || true
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
