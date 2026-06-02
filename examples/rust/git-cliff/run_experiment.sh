#!/usr/bin/env bash
# git-cliff life-cycle driver.
#
# git-cliff generates changelogs from git history using Conventional Commits.
# It reads a cliff.toml config and outputs Markdown via Tera templates.
#
# Life cycle:
#   Stage 1 — v1.0.0 code committed with Conventional Commit message, tagged v1.0.0.
#   Stage 2 — git-cliff generates the first changelog from the v1.0.0 tag.
#   Stage 3 — commit v2.0.0 changes (no release yet). git-cliff --unreleased preview.
#   Stage 4a — tag v2.0.0; git-cliff regenerates full CHANGELOG.md.
#   Stage 4b — commit v3.0.0 changes, tag, regenerate.
#
# NOTE: The Rust app is pre-compiled in the image (debian:bookworm-slim with
# git-cliff binary; we use the pre-built app binary from the scenario/).
# The app itself is run via a pre-built binary to avoid needing Rust in this image.
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
git-cliff --version

# ---- STAGE 1: v1.0.0 code, no changelog ------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
# Copy cliff.toml config into the app (git-cliff reads it from repo root).
cp $SCENARIO/cliff.toml ./cliff.toml
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; /work/tipcalc
dump_changelog

# ---- STAGE 2: generate first changelog from v1.0.0 -------------------------
banner "STAGE 2: git-cliff generates first CHANGELOG.md for v1.0.0"
git-cliff --config cliff.toml --output CHANGELOG.md
git add -A && git commit -q -m "docs: add changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: implement v2.0.0 even split, preview unreleased ---------------
banner "STAGE 3: implement even split; preview unreleased notes"
cp $SCENARIO/versions/v2_main.rs src/main.rs
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "--- git-cliff --unreleased (draft preview) ---"
git-cliff --config cliff.toml --unreleased
dump_changelog

# ---- STAGE 4a: tag v2.0.0, regenerate changelog ----------------------------
banner "STAGE 4a: tag v2.0.0, regenerate full CHANGELOG.md"
git tag v2.0.0
git-cliff --config cliff.toml --output CHANGELOG.md
git add -A && git commit -q -m "chore: update changelog for 2.0.0"
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split, tag v3.0.0, regenerate"
cp $SCENARIO/versions/v3_main.rs src/main.rs
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' Cargo.toml
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0
git-cliff --config cliff.toml --output CHANGELOG.md
git add -A && git commit -q -m "chore: update changelog for 3.0.0"
dump_changelog

# ---- bonus: latest-only (single release notes) -----------------------------
banner "BONUS: git-cliff --latest (release notes for v3.0.0 only)"
git-cliff --config cliff.toml --latest

# ---- bonus: git-cliff init (show generated cliff.toml) ---------------------
banner "BONUS: git-cliff --init in a temp dir to show default config"
mkdir -p /tmp/cliff-init-demo && cd /tmp/cliff-init-demo
git init -q && git config user.email "bot@example.invalid" && git config user.name "Bot"
git-cliff --init
cat cliff.toml
cd /work/app

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
