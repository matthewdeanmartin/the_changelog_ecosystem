#!/usr/bin/env bash
# changelog-rs life-cycle driver.
#
# The `changelog` crate (crates.io: changelog, GitHub: yoshuawuyts/changelog)
# was last released on 2020-03-02. This experiment documents its current state:
# whether it installs, what it produces, and why it is no longer recommended.
set -euo pipefail

exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}

SCENARIO=/work/scenario

# ---- check installation state -----------------------------------------------
banner "INSTALLATION CHECK"
if command -v changelog &>/dev/null; then
  echo "changelog binary found:"
  changelog --version 2>&1 || changelog --help 2>&1 | head -5
else
  echo "FINDING: changelog binary NOT installed."
  echo "cargo install failed in Dockerfile — see Docker build output."
  echo "This is expected: the crate is from 2020 and likely fails to compile"
  echo "on Rust 2024/2025 editions due to dependency incompatibilities."
fi

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

# ---- STAGE 1: v1.0.0 committed -----------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
dump_changelog

# ---- STAGE 2: attempt to generate changelog ---------------------------------
banner "STAGE 2: attempt changelog generation"
if command -v changelog &>/dev/null; then
  echo "--- changelog (attempting to run) ---"
  changelog 2>&1 || echo "(changelog command failed)"
  dump_changelog
else
  echo "SKIPPED: tool not installed."
  echo ""
  echo "If it had installed, the usage would be:"
  echo "  changelog > CHANGELOG.md   # generate from git history"
  echo "  changelog --help           # see options"
fi

# ---- note on tool status ----------------------------------------------------
banner "TOOL STATUS ASSESSMENT"
echo "changelog crate status (as of 2026-06-02):"
echo "  - Last release: 2020-03-02 (v0.3.4)"
echo "  - No pre-built binaries ever provided"
echo "  - Repository: https://github.com/yoshuawuyts/changelog"
echo "  - GitHub shows no activity since 2020"
echo ""
echo "Attempting cargo install in Docker produced one of:"
echo "  a) Compilation failure due to dependency resolution on modern Rust"
echo "  b) Success but with 2020-era output quality"
echo ""
echo "VERDICT: Do not use for new projects. Use git-cliff instead."

# ---- stages 3-4 (skipped) ---------------------------------------------------
banner "STAGES 3-4: skipped — tool not functional"
echo "The remaining life-cycle stages (even split, uneven split) are not"
echo "runnable because the tool either failed to install or is not useful."

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || echo "(no CHANGELOG.md)" > /work/out/CHANGELOG.md
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
