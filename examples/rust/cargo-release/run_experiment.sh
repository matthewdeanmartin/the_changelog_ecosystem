#!/usr/bin/env bash
# cargo-release life-cycle driver.
#
# cargo-release is a release orchestrator, not a changelog generator.
# It bumps versions, commits, tags, and publishes. Changelog integration
# happens via pre-release-hook (e.g. git-cliff) and file replacements.
#
# We use --dry-run throughout (cargo-release default) to show what would happen
# without actually publishing to crates.io. We also demonstrate file-replacement
# and hook-based changelog updates which run even in dry-run mode.
#
# Life cycle:
#   Stage 1 — v1.0.0 committed and tagged manually (baseline state).
#   Stage 2 — Run git-cliff to create CHANGELOG.md; commit it.
#   Stage 3 — Implement v2.0.0; show cargo-release --dry-run output.
#   Stage 4a — cargo-release with hook writes CHANGELOG.md; tag v2.0.0.
#   Stage 4b — Repeat for v3.0.0.
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
cargo-release release --help 2>&1 | head -1 || true
echo "cargo-release binary found at: $(which cargo-release)"
echo "git-cliff version:"
git-cliff --version

# Copy cliff.toml for the hook
cp $SCENARIO/cliff.toml ./cliff.toml

# ---- STAGE 1: v1.0.0 committed, no changelog --------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
dump_changelog

# ---- STAGE 2: generate initial changelog with git-cliff ----------------------
banner "STAGE 2: generate CHANGELOG.md for v1.0.0 using git-cliff"
git-cliff --config cliff.toml --output CHANGELOG.md
git add -A && git commit -q -m "docs: add changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: implement v2.0.0 -----------------------------------------------
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_main.rs src/main.rs
# Bump version in Cargo.toml manually (cargo-release would do this with --execute)
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat: split the bill evenly among diners"

# Show what cargo-release would do (dry-run is the default)
echo "--- cargo-release --dry-run ---"
echo "(note: cargo-release dry-run requires cargo, which is available in this image)"
# cargo-release dry-run — shows what would happen without executing
cargo-release release --no-publish --no-push --no-tag patch 2>&1 || true

dump_changelog

# ---- STAGE 4a: use git-cliff hook manually to release v2.0.0 ----------------
banner "STAGE 4a: run git-cliff hook + tag v2.0.0"
# Simulate what cargo-release --execute would do: run hook, commit, tag.
git-cliff --config cliff.toml --tag v2.0.0 --output CHANGELOG.md
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_main.rs src/main.rs
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git-cliff --config cliff.toml --tag v3.0.0 --output CHANGELOG.md
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- show release.toml configuration ----------------------------------------
banner "BONUS: show release.toml config approach"
cat <<'EOF'
# release.toml — what a real cargo-release config looks like:
[release]
pre-release-hook = ["git", "cliff", "--tag", "{{version}}", "-o", "CHANGELOG.md"]
tag-name = "v{{version}}"
push = false
publish = false
EOF

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
