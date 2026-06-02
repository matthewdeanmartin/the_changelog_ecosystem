#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }
dump_changelog() {
  if [ -f CHANGELOG.md ]; then echo "----- CHANGELOG.md -----"; cat CHANGELOG.md; echo "------------------------";
  else echo "(no changelog output yet)"; fi
}

SCENARIO=/work/scenario
cd /work/app
git init -q
git config user.name "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "goreleaser version:"; goreleaser --version

# STAGE 1
banner "STAGE 1: v1.0.0 code, NO changelog"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "program output:"; go run main.go
dump_changelog

# STAGE 2: try goreleaser changelog for v1.0.0
banner "STAGE 2: goreleaser changelog for v1.0.0"
echo "--- goreleaser changelog ---"
goreleaser changelog --skip=announce,validate 2>&1 || true
# goreleaser changelog needs a previous tag; show what it generates
dump_changelog

# STAGE 3: v2 feature
banner "STAGE 3: implement even split"
cp $SCENARIO/versions/v2_main.go main.go
git add -A && git commit -q -m "feat: split the bill evenly among diners"
echo "program output:"; go run main.go

# STAGE 4a: snapshot release v2.0.0
banner "STAGE 4a: goreleaser release --snapshot for v2.0.0"
git tag v2.0.0
goreleaser release --snapshot --clean --skip=publish,announce,validate 2>&1 || true
# Extract generated changelog from dist/ if present
if [ -f dist/CHANGELOG.md ]; then
  echo "----- dist/CHANGELOG.md -----"; cat dist/CHANGELOG.md; echo "------------------------"
fi
echo "--- goreleaser changelog (v2.0.0) ---"
goreleaser changelog --skip=announce,validate 2>&1 || true

# STAGE 4b: v3.0.0
banner "STAGE 4b: implement uneven split, snapshot release v3.0.0"
cp $SCENARIO/versions/v3_main.go main.go
git add -A && git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0
goreleaser release --snapshot --clean --skip=publish,announce,validate 2>&1 || true
echo "--- goreleaser changelog (v3.0.0) ---"
goreleaser changelog --skip=announce,validate 2>&1 || true

banner "DONE — copying artifacts to out/"
cp -f dist/CHANGELOG.md /work/out/CHANGELOG.md 2>/dev/null || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "dist/ contents:"; ls -la dist/ 2>/dev/null || echo "(no dist/)"
echo "Artifacts in /work/out:"; ls -la /work/out
