#!/usr/bin/env bash
# reno life-cycle driver.
#
# reno is an OpenStack release-notes tool that stores YAML note files in the
# repo and scans git tags to associate them with releases. Its output is
# reStructuredText (RST) by default, suitable for Sphinx.
#
# Life cycle:
#   Stage 1 — v1.0.0 code committed, no notes yet.
#   Stage 2 — `reno new` creates the v1 note; commit + tag v1.0.0;
#             `reno report` generates the first release notes RST.
#   Stage 3 — `reno new` for v2.0.0 feature; commit.
#   Stage 4a — tag v2.0.0; `reno report` for v2.0.0.
#   Stage 4b — `reno new` for v3.0.0; commit; tag; report.
#
# NOTE: reno scans git *history* and *tags* to know which notes belong to which
# release. Notes committed BEFORE a tag land in that release; notes committed
# AFTER the previous tag and before the next tag belong to the next release.
# Output is RST (releasenotes/notes/), not CHANGELOG.md — we copy the generated
# report to out/CHANGELOG.md for the artifact convention.
set -euo pipefail

exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_report() {
  echo "--- reno report (stdout) ---"
  reno report --no-show-source 2>/dev/null || reno report 2>/dev/null || echo "(reno report failed)"
  echo "---"
}
show_notes() {
  echo "releasenotes/notes/:"; ls -1 releasenotes/notes 2>/dev/null || echo "  (none)"
}

SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false
echo "tool under test:"
python -c "import reno; print('reno', reno.__version__)"

# ---- STAGE 1: no release notes ----------------------------------------------
banner "STAGE 1: v1.0.0 code, NO release notes"
git add -A
git commit -q -m "feat: compute tip for a single bill"
# NOTE: do NOT tag yet — the v1.0.0 note must be committed first so reno
# associates it with this release. We tag after adding the note.
echo "program output:"; python -m tipcalc

# ---- STAGE 2: create v1.0.0 release note ------------------------------------
banner "STAGE 2: add reno note for v1.0.0 and tag the release"
# `reno new` creates a uniquely-named YAML note file under releasenotes/notes/.
reno new initial-release
show_notes

# Overwrite the templated note with our pre-written content.
cp $SCENARIO/notes/v1/initial-release.yaml releasenotes/notes/$(ls releasenotes/notes/ | head -1)

echo "--- note content ---"
cat releasenotes/notes/$(ls releasenotes/notes/ | head -1)

git add -A && git commit -q -m "docs: add reno note for 1.0.0"
git tag 1.0.0

echo "--- reno report for 1.0.0 ---"
dump_report

# ---- STAGE 3: add v2.0.0 release note ---------------------------------------
banner "STAGE 3: implement even split, add reno note for v2.0.0"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

reno new even-split
show_notes

# Overwrite the newest note with our prepared content.
NEWEST=$(ls -t releasenotes/notes/ | head -1)
cp $SCENARIO/notes/v2/even-split.yaml releasenotes/notes/$NEWEST
echo "--- note content ---"
cat releasenotes/notes/$NEWEST

git add -A && git commit -q -m "feat: split the bill evenly among diners"

echo "--- reno report (unreleased) ---"
dump_report

# ---- STAGE 4a: tag v2.0.0 and report ----------------------------------------
banner "STAGE 4a: tag v2.0.0 and generate release notes"
git tag 2.0.0
echo "--- reno report after v2.0.0 tag ---"
dump_report

# ---- STAGE 4b: v3.0.0 (uneven split) ----------------------------------------
banner "STAGE 4b: implement uneven split, add note, tag v3.0.0"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python -m tipcalc

reno new uneven-split
show_notes

NEWEST=$(ls -t releasenotes/notes/ | head -1)
cp $SCENARIO/notes/v3/uneven-split.yaml releasenotes/notes/$NEWEST
echo "--- note content ---"
cat releasenotes/notes/$NEWEST

git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git tag 3.0.0

echo "--- final reno report (all versions) ---"
dump_report

# ---- reno lint (CI gate) -----------------------------------------------------
banner "BONUS: reno lint (CI gate)"
reno lint || echo "(lint returned non-zero)"

# ---- artifacts (reno generates RST, not CHANGELOG.md) -----------------------
banner "DONE — copying artifacts to out/"
# Capture the full report as the output artifact.
reno report --no-show-source > /work/out/CHANGELOG.md 2>/dev/null || \
  reno report > /work/out/CHANGELOG.md 2>/dev/null || \
  echo "(reno report failed; writing empty placeholder)" > /work/out/CHANGELOG.md
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
