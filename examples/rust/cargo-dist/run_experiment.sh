#!/usr/bin/env bash
# cargo-dist life-cycle driver.
#
# cargo-dist is a release DISTRIBUTION tool, not a changelog generator.
# It focuses on: generating CI workflows, building platform artifacts,
# creating installers, and publishing to GitHub Releases.
#
# What we can demonstrate locally (without CI/GitHub):
#   - cargo-dist init — adds dist config to Cargo.toml, generates CI workflows
#   - cargo-dist plan — shows what would be built for a release
#   - cargo-dist generate — regenerates CI workflow files
#   - cargo-dist manifest — shows the dist manifest JSON
#
# What we CANNOT demonstrate locally:
#   - cargo-dist build — cross-compiles for all targets (requires CI environment)
#   - cargo-dist upload — uploads to GitHub Releases (requires token)
#
# The changelog story: cargo-dist defers to a companion tool (git-cliff, Release Drafter,
# or a hand-written changelog). This experiment shows that boundary clearly.
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
cargo-dist --version

# ---- STAGE 1: v1.0.0 code, no dist config -----------------------------------
banner "STAGE 1: v1.0.0 code, NO dist config"
cargo generate-lockfile -q 2>/dev/null || true
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
dump_changelog

# ---- STAGE 2: cargo-dist init -----------------------------------------------
banner "STAGE 2: cargo-dist init — add dist config and CI workflows"
echo "--- cargo-dist init (non-interactive with defaults) ---"
# Init with --yes to accept defaults non-interactively.
cargo-dist init --yes 2>&1 || cargo-dist init 2>&1 || echo "(init failed — see below)"
echo ""
echo "--- Cargo.toml [workspace.metadata.dist] section ---"
grep -A 20 'metadata.dist' Cargo.toml || echo "(no dist metadata added)"
echo ""
if [ -d .github ]; then
  echo "--- Generated CI workflow files ---"
  find .github -name "*.yml" | head -5
else
  echo "(no .github/ generated)"
fi
git add -A && git commit -q -m "chore: add cargo-dist config"
dump_changelog

# ---- STAGE 3: show dist plan for current tags --------------------------------
banner "STAGE 3: cargo-dist plan — shows what would be built"
echo "--- cargo-dist plan ---"
cargo-dist plan 2>&1 || echo "(cargo-dist plan output above)"
dump_changelog

# ---- STAGE 4a: update to v2.0.0 and show plan --------------------------------
banner "STAGE 4a: v2.0.0 — show dist plan for even-split release"
cp $SCENARIO/versions/v2_main.rs src/main.rs
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat: split the bill evenly among diners"
git tag v2.0.0
echo "--- cargo-dist plan for v2.0.0 ---"
cargo-dist plan 2>&1 || true
dump_changelog

# ---- STAGE 4b: v3.0.0 --------------------------------------------------------
banner "STAGE 4b: v3.0.0 — uneven split, show manifest"
cp $SCENARIO/versions/v3_main.rs src/main.rs
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0
echo "--- cargo-dist manifest (JSON) ---"
cargo-dist manifest 2>&1 | head -50 || true
dump_changelog

# ---- note on changelog integration ------------------------------------------
banner "BONUS: cargo-dist changelog integration note"
echo "cargo-dist does NOT generate changelogs."
echo "Release notes come from:"
echo "  1. A companion tool: git-cliff, release-plz, etc."
echo "  2. A CHANGELOG.md file read at release time."
echo "  3. GitHub's auto-generated release notes."
echo ""
echo "The dist.toml / Cargo.toml [dist] section can specify a changelog file:"
echo "  [dist]"
echo "  changelog-path = 'CHANGELOG.md'  # used for GitHub Release body"

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
# Save the dist manifest if it exists
cargo-dist manifest 2>/dev/null > /work/out/dist-manifest.json || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
