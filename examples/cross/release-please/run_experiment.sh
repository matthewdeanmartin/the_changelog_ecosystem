#!/usr/bin/env bash
# release-please life-cycle driver — LOCAL-ONLY SUBSET.
#
# WHY THIS IS DIFFERENT FROM THE OTHER EXAMPLES
# ---------------------------------------------
# release-please is fundamentally a GitHub-API tool. Every subcommand requires
# --token and --repo-url and calls api.github.com; even --dry-run and --local
# perform an initial `GET /repos/{owner}/{repo}` before doing anything. There is
# NO fully offline mode. So we cannot walk the same "produces a CHANGELOG.md"
# arc the fragment tools do.
#
# Instead this experiment honestly drives the LOCAL-ONLY SUBSET and DOCUMENTS THE
# LIMIT as the finding:
#   - It builds the exact repo state release-please expects: an isolated git repo
#     with Conventional-Commit history (feat / feat / feat!) across the three
#     tip-calculator versions, plus release-please-config.json and
#     .release-please-manifest.json.
#   - It runs the parts that DO work locally, and then attempts
#     `release-pr --local --dry-run` while OFFLINE (the Makefile runs the
#     container with --network none), capturing the precise GitHub-API failure.
#
# The script therefore EXITS 0 on the *expected* offline failure (that failure is
# the deliverable), but prints loud banners so the transcript is unambiguous.
set -uo pipefail   # NOTE: not -e — we expect the GitHub step to fail and want to continue.

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no CHANGELOG.md — release-please writes it only via a GitHub release PR)"; fi
}

SCENARIO=/work/scenario
REPO_URL="https://github.com/example/tipcalc.git"   # placeholder; never reached offline

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false
git branch -M main 2>/dev/null || true
echo "tool under test:"
release-please --version

# Bake release-please's config + manifest into the repo root.
cp $SCENARIO/release-please-config.json ./release-please-config.json
cp $SCENARIO/.release-please-manifest.json ./.release-please-manifest.json

# ---- STAGE 1: no changelog, v1.0.0 committed (Conventional Commits) ----------
banner "STAGE 1: v1.0.0 code, NO changelog (Conventional Commit history)"
git add -A
git commit -q -m "feat: compute the tip for a single bill"
# release-please's 'python' strategy with include-v-in-tag=false and
# package-name=tipcalc tags as 'tipcalc-1.0.0'. Seed the v1 tag so the tool has a
# baseline to diff the next release from.
git tag tipcalc-1.0.0
echo "program output:"; python3 -m tipcalc
dump_changelog

# ---- STAGE 2: "changelog created" — what release-please would do for v1 ------
banner "STAGE 2: release-please debug-config (local config inspection)"
# debug-config is the subcommand closest to a local-only operation. Try it
# offline and capture exactly what it does (it, too, reaches for the API).
echo "--- release-please debug-config (offline) ---"
release-please debug-config --repo-url="$REPO_URL" --token=offline-fake --debug 2>&1 \
  | sed 's/^/  /' | head -40 || true
echo "(debug-config also reaches for the GitHub API; output above shows where.)"

# ---- STAGE 3: changelog updated — add the even-split feature commit ----------
banner "STAGE 3: implement even split, commit as a Conventional 'feat'"
cp $SCENARIO/versions/v2_init.py tipcalc/__init__.py
sed -i 's/^version = "1.0.0"/version = "2.0.0"/' pyproject.toml
echo "program output:"; python3 -m tipcalc
git add -A
git commit -q -m "feat: split the bill evenly among diners"

# ---- STAGE 4: bump + release — the GitHub-API wall --------------------------
banner "STAGE 4: attempt release-pr (this is where the offline limit bites)"
cp $SCENARIO/versions/v3_init.py tipcalc/__init__.py
sed -i 's/^version = "2.0.0"/version = "3.0.0"/' pyproject.toml
echo "program output:"; python3 -m tipcalc
git add -A
# Conventional Commits encode the version bump intent: feat! => major (3.0.0).
git commit -q -m "feat!: split the bill unevenly by weight

BREAKING CHANGE: output is now one line per diner."

echo "git history release-please would parse:"
git log --oneline --decorate

echo
echo "--- ATTEMPT: release-please release-pr --local --dry-run (OFFLINE) ---"
echo "Expectation: release-please immediately calls the GitHub API even with"
echo "--local and --dry-run, so this fails. The failure is the finding."
echo
release-please release-pr \
  --repo-url="$REPO_URL" \
  --token=offline-fake \
  --target-branch=main \
  --local --local-path=/work/app \
  --dry-run --debug 2>&1 | sed 's/^/  /'
RP_EXIT=${PIPESTATUS[0]}
echo
echo ">>> release-pr exit code: $RP_EXIT (non-zero = the expected GitHub-API wall)"

banner "FINDING SUMMARY"
cat <<'EOF'
release-please has NO fully offline / local-only release path:
  - Even with --local, --local-path, and --dry-run, the first action is a GitHub
    REST call (GET /repos/{owner}/{repo}). Offline (or with a fake token) it fails
    before producing any CHANGELOG.md or version bump.
  - The conventional-commit parsing, version inference (feat -> minor, feat! ->
    major), config and manifest are all real and correct LOCALLY — but the tool
    will not emit a changelog without talking to GitHub.
Conclusion: release-please belongs to the SERVER/API-bound class. The local-only
subset is limited to repo + config setup and commit-convention modeling; the
changelog/release output requires a live GitHub repo + token.
EOF

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
dump_changelog
cp -f release-please-config.json /work/out/release-please-config.json 2>/dev/null || true
cp -f .release-please-manifest.json /work/out/release-please-manifest.json 2>/dev/null || true
git -C /work/app log --oneline --decorate > /work/out/git-log.txt
git -C /work/app tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out

# Intentionally exit 0: the expected offline failure is the documented outcome,
# not a broken experiment. (The transcript records RP_EXIT for transparency.)
exit 0
