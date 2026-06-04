#!/usr/bin/env bash
# logchange life-cycle driver (cross-ecosystem example).
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work (never touch host git config).
#   - Walk 4 stages: no changelog -> created -> updated -> bump+release (x2).
#   - After each stage print a banner and dump the current CHANGELOG.
#   - Copy final artifacts + full transcript into /work/out.
#   - Exit non-zero if a required tool command fails.
#
# logchange model (observed via `logchange <cmd> --help` on logchange/logchange:1.19.15):
#   - `logchange init`     -> creates changelog/logchange-config.yml + changelog/unreleased/.gitkeep
#   - change entries        -> one YAML file per change in changelog/unreleased/*.yml
#   - `logchange lint`      -> validates the YAML entries + config (a CI gate)
#   - `logchange generate`  -> (re)writes CHANGELOG.md from entries; NON-destructive
#                              (does not move files; pending entries show under [unreleased])
#   - `logchange release --versionToRelease X --releaseDate Y`
#                           -> MOVES changelog/unreleased/*.yml into changelog/vX/,
#                              writes changelog/vX/release-date.txt, recreates the
#                              unreleased dir (with a fresh .gitkeep)
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md yet)"; fi
}
show_entries() {
  echo "changelog/unreleased/:"; ls -1 changelog/unreleased 2>/dev/null || echo "  (none)"
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
logchange -V

# ---- STAGE 1: no changelog --------------------------------------------------
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; python3 -m tipcalc
dump_changelog

# ---- STAGE 2: changelog created ---------------------------------------------
banner "STAGE 2: logchange init + first entry + generate for v1.0.0"
# init lays down changelog/logchange-config.yml and the unreleased/ dir.
logchange init
echo "--- generated config + dir ---"; find changelog -type f | sort
# Drop the v1 change entry into the unreleased dir logchange reads.
rm -f changelog/unreleased/.gitkeep
cp $SCENARIO/fragments/v1/*.yml changelog/unreleased/
show_entries
# lint is logchange's validation gate — run it before anything else.
echo "--- logchange lint ---"; logchange lint
# generate (re)writes CHANGELOG.md; entries still pending => shown under [unreleased].
logchange generate
git add -A && git commit -q -m "docs: configure logchange + add 1.0.0 entry"
dump_changelog
# release 1.0.0: move the unreleased entry into changelog/v1.0.0/ and re-generate.
echo "--- release 1.0.0 ---"
logchange release --versionToRelease 1.0.0 --releaseDate 2026-01-01
logchange generate
git add -A && git commit -q -m "docs: release changelog for 1.0.0"
echo "--- tree after 1.0.0 release ---"; find changelog -type f | sort
dump_changelog

# ---- STAGE 3: changelog updated (toward v2.0.0) -----------------------------
banner "STAGE 3: implement even split, add an entry (no release yet)"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python3 -m tipcalc
# release recreated unreleased/ with a .gitkeep; drop the v2 entry alongside it.
cp $SCENARIO/fragments/v2/*.yml changelog/unreleased/
show_entries
logchange lint
# generate previews the pending 2.0.0 work under [unreleased] WITHOUT releasing.
logchange generate
git add -A && git commit -q -m "feat: split the bill evenly among diners"
dump_changelog

# ---- STAGE 4a: version bump + release v2.0.0 --------------------------------
banner "STAGE 4a: release v2.0.0"
logchange release --versionToRelease 2.0.0 --releaseDate 2026-02-01
logchange generate
git add -A && git commit -q -m "chore(release): 2.0.0"
git tag v2.0.0
dump_changelog

# ---- STAGE 4b: second loop -> v3.0.0 (uneven split) ------------------------
banner "STAGE 4b: implement uneven split, release v3.0.0"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python3 -m tipcalc
cp $SCENARIO/fragments/v3/*.yml changelog/unreleased/
show_entries
logchange lint
logchange release --versionToRelease 3.0.0 --releaseDate 2026-03-01
logchange generate
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0
dump_changelog

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
cp -f CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
# Capture the whole logchange tree so the entry->version layout is visible in out/.
cp -rf changelog /work/out/changelog 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
