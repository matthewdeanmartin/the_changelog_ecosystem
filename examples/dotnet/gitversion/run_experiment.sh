#!/usr/bin/env bash
# GitVersion life-cycle driver.
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work/app (never touch host git config).
#   - Walk stages: no version -> tag v1.0.0 -> feature bump -> breaking bump.
#   - After each stage print a banner and dump the gitversion JSON output.
#   - Copy final artifacts + full transcript into /work/out.
#   - Exit non-zero if a required tool command fails.
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }

# GitVersion produces version JSON instead of a CHANGELOG.md.
# This helper shows the computed version — equivalent to the "changelog dump" in
# other experiments.
dump_version() {
  echo "----- gitversion output -----"
  dotnet-gitversion 2>&1 || true
  echo "-----------------------------"
}

show_version_var() {
  local var="$1"
  local val
  val=$(dotnet-gitversion /showvariable "$var" 2>&1 || echo "unknown")
  echo "  $var = $val"
}

# $SCENARIO/ is baked at /work/scenario (sibling of the app), so reference it by
# absolute path: we `cd` into the app repo and must not assume scenario is relative.
SCENARIO=/work/scenario

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "tool under test:"
dotnet-gitversion /version

# Copy GitVersion.yml into the repo root so GitVersion can find it.
cp "$SCENARIO/GitVersion.yml" ./GitVersion.yml

# Restore + build once (after git init so msbuild incremental tracking is stable).
dotnet restore -q
dotnet build --nologo -v minimal

banner "STAGE 1: v1 code committed — no tag yet"
git add -A
git commit -q -m "feat: compute tip for a single bill"
echo "program output:"
dotnet run --project TipCalc.csproj --no-build
echo
echo "computed version before any tag:"
show_version_var "MajorMinorPatch"
show_version_var "SemVer"
dump_version

# ---- STAGE 2: tag v1.0.0 and show full JSON ---------------------------------
banner "STAGE 2: tag v1.0.0 — show full gitversion JSON"
git tag v1.0.0
echo "tagged v1.0.0"
echo
echo "computed version after v1.0.0 tag:"
show_version_var "MajorMinorPatch"
show_version_var "SemVer"
dump_version

# ---- STAGE 3: feature commit (minor bump) -----------------------------------
banner "STAGE 3: feat commit (even split) — expect minor bump to 1.1.0"
cp "$SCENARIO/versions/v2/Program.cs" ./Program.cs
git add -A
git commit -q -m "feat: split the bill evenly among diners"
# Rebuild for the new Program.cs
dotnet build --nologo -v minimal --no-restore
echo "program output:"
dotnet run --project TipCalc.csproj --no-build
echo
echo "computed version after feat commit (should be 1.1.0):"
show_version_var "MajorMinorPatch"
show_version_var "SemVer"
dump_version

# Tag the feature release.
git tag v1.1.0
echo "tagged v1.1.0"

# ---- STAGE 4: breaking change commit (major bump) ---------------------------
banner "STAGE 4: feat! commit (uneven split by weight) — expect major bump to 2.0.0"
cp "$SCENARIO/versions/v3/Program.cs" ./Program.cs
git add -A
git commit -q -m "feat!: split the bill unevenly by weight"
# Rebuild for the new Program.cs
dotnet build --nologo -v minimal --no-restore
echo "program output:"
dotnet run --project TipCalc.csproj --no-build
echo
echo "computed version after feat! commit (should be 2.0.0):"
show_version_var "MajorMinorPatch"
show_version_var "SemVer"
echo
echo "full gitversion JSON at breaking-change state:"
dump_version

# Tag the major release.
git tag v2.0.0
echo "tagged v2.0.0"
echo
echo "computed version after v2.0.0 tag:"
show_version_var "MajorMinorPatch"
show_version_var "SemVer"
dump_version

# ---- git log summary --------------------------------------------------------
banner "GIT LOG"
git log --oneline --decorate

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
dotnet-gitversion > /work/out/gitversion.json 2>&1 || true
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"
ls -la /work/out
