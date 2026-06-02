#!/usr/bin/env bash
# dotnet-releaser life-cycle driver.
#
# Goal: probe which dotnet-releaser sub-commands work offline (no GitHub token,
#       no NuGet key) and which require live remotes.
#
# Findings from initial probe:
#  - The tool requires .NET 10 SDK (package targets net10.0).
#  - Config TOML must use [msbuild] (singular table) and [github] with key
#    "user" (not "owner"); the [[nuget]] array-of-tables format is invalid.
#  - `build` proceeds through compile+pack locally but hits GitHub API when
#    trying to fetch release notes — fails with auth errors, not config errors.
#  - `run` and `changelog` fail immediately with "Missing required option
#    --github-token" — no local-only path exists.
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work/repo (never touch host git config).
#   - Walk the life-cycle stages, echoing each step.
#   - Use || true on expected failures so the transcript captures the error
#     without aborting the whole experiment prematurely.
#   - Copy final artifacts + full transcript into /work/out.
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }

SCENARIO=/work/scenario
REPO=/work/repo

# ---- STAGE 0: tool sanity check ---------------------------------------------
banner "STAGE 0: tool version + help"
echo "--- dotnet-releaser version ---"
dotnet-releaser --version

echo ""
echo "--- dotnet-releaser --help ---"
dotnet-releaser --help

echo ""
echo "--- sub-command: build --help ---"
dotnet-releaser build --help

echo ""
echo "--- sub-command: run --help ---"
dotnet-releaser run --help

echo ""
echo "--- sub-command: changelog --help ---"
dotnet-releaser changelog --help

echo ""
echo "--- sub-command: new --help ---"
dotnet-releaser new --help

# ---- Set up isolated git repo -----------------------------------------------
banner "STAGE 1: isolated git repo + v1.0.0 code, NO changelog"
mkdir -p "$REPO"
cd "$REPO"

git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

# A fake GitHub remote is required: dotnet-releaser reads git remote to detect
# the GitHub owner/repo, and crashes with NullReferenceException if no remote
# is configured. We use a non-resolvable URL so it cannot make real API calls.
git remote add origin https://github.com/test/test.git

# Copy the .NET app into the repo
cp -r /work/app/. "$REPO/"

# Build requires a committed tree
dotnet restore TipCalc.csproj

git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0

echo "--- program output (v1.0.0) ---"
dotnet run --project TipCalc.csproj

# Generate the config using dotnet-releaser new (ensures correct TOML format)
echo ""
echo "--- generating dotnet-releaser.toml via 'dotnet-releaser new' ---"
dotnet-releaser new --project TipCalc.csproj --user test --repo test
echo "--- generated config ---"
cat dotnet-releaser.toml

# ---- STAGE 2: probe 'build' sub-command offline -----------------------------
banner "STAGE 2: probe 'dotnet-releaser build' (offline — no GitHub token)"
echo "Attempting: dotnet-releaser build dotnet-releaser.toml"
echo "(Expected: compiles + packs locally, then fails at GitHub API for release"
echo " notes; NuGet publish is off by default so that step is skipped)"
echo ""
dotnet-releaser build dotnet-releaser.toml 2>&1 || \
  echo "[OBSERVED] 'dotnet-releaser build' failed — see error above"

# ---- STAGE 3: probe 'run' sub-command without GitHub/NuGet creds ------------
banner "STAGE 3: probe 'dotnet-releaser run' (offline — no tokens)"
echo "Attempting: dotnet-releaser run dotnet-releaser.toml"
echo "(Expected: fails immediately with missing --github-token error)"
echo ""
dotnet-releaser run dotnet-releaser.toml 2>&1 || \
  echo "[OBSERVED] 'dotnet-releaser run' failed — see error above"

# ---- STAGE 4: v2.0.0 — even split, probe changelog sub-command -------------
banner "STAGE 4: v2.0.0 code + probe 'changelog' sub-command"

# Update Program.cs to v2 behaviour (even split)
cat > "$REPO/Program.cs" << 'CSHARP'
// TipCalc v2.0.0 — split the bill evenly among a constant number of diners.

const decimal bill = 100.00m;
const decimal tipPercent = 0.18m;
const int diners = 4;

decimal total = bill * (1 + tipPercent);
decimal perPerson = total / diners;

Console.WriteLine($"Bill:      {bill:C}");
Console.WriteLine($"Tip:       {bill * tipPercent:C}  ({tipPercent:P0})");
Console.WriteLine($"Total:     {total:C}");
Console.WriteLine($"Per diner: {perPerson:C}  ({diners} people)");
CSHARP

# Bump version in csproj
sed -i 's|<Version>1.0.0</Version>|<Version>2.0.0</Version>|' TipCalc.csproj

git add -A
git commit -q -m "feat: split the bill evenly among diners"
git tag v2.0.0

echo "--- program output (v2.0.0) ---"
dotnet run --project TipCalc.csproj

echo ""
echo "--- probe: dotnet-releaser changelog (requires --github-token) ---"
dotnet-releaser changelog dotnet-releaser.toml 2>&1 || \
  echo "[OBSERVED] 'changelog' invocation failed — see error above"

# ---- STAGE 5: v3.0.0 — uneven split (breaking output) ----------------------
banner "STAGE 5: v3.0.0 code commit + git log"

cat > "$REPO/Program.cs" << 'CSHARP'
// TipCalc v3.0.0 — split the bill unevenly by per-person weight constants.

const decimal bill = 100.00m;
const decimal tipPercent = 0.18m;

// Weights (must sum to 1.0 for correct math)
decimal[] weights = [0.50m, 0.30m, 0.20m];
string[] names   = ["Alice", "Bob", "Carol"];

decimal total = bill * (1 + tipPercent);

Console.WriteLine($"Bill:  {bill:C}   Tip: {bill * tipPercent:C}   Total: {total:C}");
for (int i = 0; i < names.Length; i++)
{
    decimal share = total * weights[i];
    Console.WriteLine($"  {names[i],-6} ({weights[i]:P0}): {share:C}");
}
CSHARP

sed -i 's|<Version>2.0.0</Version>|<Version>3.0.0</Version>|' TipCalc.csproj

git add -A
git commit -q -m "feat!: split the bill unevenly by weight"
git tag v3.0.0

echo "--- program output (v3.0.0) ---"
dotnet run --project TipCalc.csproj

echo ""
echo "--- git log (in-container scenario repo) ---"
git log --oneline --decorate

# ---- Summary ----------------------------------------------------------------
banner "SUMMARY: offline capability matrix"
cat << 'EOF'
Command                               Works offline?   Notes
----------------------------------------------------------------------
dotnet-releaser --version             YES              Pure binary, no config
dotnet-releaser --help                YES              Pure binary, no config
dotnet-releaser new --project X       YES              Generates local TOML;
                                                       does NOT need GitHub creds
dotnet-releaser build <config>        PARTIAL          Compiles + packs locally
                                                       via MSBuild; fails when
                                                       fetching GitHub release
                                                       notes (auth error)
dotnet-releaser run <config>          NO               Requires GITHUB_TOKEN;
                                                       fails before any local work
dotnet-releaser changelog <config>    NO               Requires GITHUB_TOKEN;
                                                       fails immediately
----------------------------------------------------------------------
Key findings:
1. The package requires .NET 10 SDK — documented as net8+ but built for net10.
2. Config TOML must use [msbuild] + [github] with key "user"; the [[nuget]]
   array-of-tables form is invalid (tool uses singular [nuget] if needed).
3. `build` reaches the MSBuild compile+pack step without a token but stops
   at GitHub API calls for release notes — even with a fake remote.
4. All changelog/release functionality requires a live GitHub token and a
   resolvable GitHub remote. There is no --dry-run or --offline mode.
5. Conclusion: dotnet-releaser is a CI/CD release orchestrator. Its core
   value (GitHub Release creation, NuGet publish, PR-sourced release notes)
   is inseparable from live remotes. The "CI-only" characterization is
   accurate. Local use is limited to 'new' and build compilation.
EOF

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
git -C "$REPO" log --oneline --decorate > /work/out/git-log.txt 2>/dev/null || true
git -C "$REPO" tag                      > /work/out/git-tags.txt 2>/dev/null || true
cp -f "$REPO/dotnet-releaser.toml" /work/out/dotnet-releaser.toml 2>/dev/null || true
# transcript is already being tee'd to out/transcript.txt
echo "Artifacts in /work/out:"; ls -la /work/out
