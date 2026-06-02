#!/usr/bin/env bash
# scriv life-cycle driver.
#
# scriv is a changelog fragment tool: contributors run `scriv create` to make a
# fragment; maintainers run `scriv collect` to aggregate them into CHANGELOG.md.
#
# Life cycle:
#   Stage 1 — v1.0.0 code committed, no changelog yet.
#   Stage 2 — Configure scriv; drop v1 fragment; `scriv collect` assembles CHANGELOG.md.
#   Stage 3 — Add v2 fragment; preview with `scriv collect --add`.
#   Stage 4a — `scriv collect` for v2.0.0; tag.
#   Stage 4b — Add v3 fragment, collect, tag.
set -euo pipefail

exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}
show_fragments() {
  echo "changelog.d/:"; ls -1 changelog.d 2>/dev/null || echo "  (none)"
}

SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false
echo "tool under test:"
scriv --version

# ---- STAGE 1: no changelog --------------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; python -m tipcalc
dump_changelog

# ---- STAGE 2: configure scriv + build first changelog for v1.0.0 -----------
banner "STAGE 2: configure scriv + collect first changelog for v1.0.0"
# Append scriv config to pyproject.toml.
cat $SCENARIO/scriv_config.toml >> pyproject.toml

# Drop the v1 fragment into changelog.d.
mkdir -p changelog.d
cp $SCENARIO/fragments/v1/*.md changelog.d/
show_fragments

# Commit before collect — scriv uses git to track fragment files.
git add -A && git commit -q -m "docs: add news fragment for 1.0.0 feature"

# Collect assembles all fragments into CHANGELOG.md for the current version.
scriv collect
show_fragments
git add -A && git commit -q -m "docs: collect changelog for 1.0.0"
dump_changelog

# ---- STAGE 3: add v2 fragment (don't collect yet) --------------------------
banner "STAGE 3: implement even split, add fragment for v2.0.0"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

mkdir -p changelog.d   # re-create after collect emptied it
cp $SCENARIO/fragments/v2/*.md changelog.d/
show_fragments
git add -A && git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: collect + release v2.0.0 ------------------------------------
banner "STAGE 4a: collect fragments + release v2.0.0"
scriv collect
show_fragments
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split, collect + release v3.0.0"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

mkdir -p changelog.d
cp $SCENARIO/fragments/v3/*.md changelog.d/
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
show_fragments
scriv collect
git add -A && git commit -q -m "chore(release): 3.0.0"
git tag v3.0.0
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
