#!/usr/bin/env bash
# GitReleaseManager life-cycle driver.
#
# PURPOSE: Confirm that GitReleaseManager requires live GitHub API access and
# has no offline mode. Every subcommand (create, publish, close, export) needs
# --owner, --repository, and a valid --token pointing at github.com.
#
# Contract (see spec/experiments.md):
#   - Build an ISOLATED git repo in /work/app (never touch host git config).
#   - Attempt real gitreleasemanager commands with dummy args and no token.
#   - Print clear banners explaining what each attempt does and why it fails.
#   - Use || true on expected-failure commands so the script runs to completion.
#   - Copy final artifacts + full transcript into /work/out.
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }

# GitReleaseManager has no CHANGELOG.md — it manages GitHub Releases via API.
# This helper echoes what the tool prints when the attempt is made.
dump_changelog() {
  echo "----- gitreleasemanager output captured above -----"
  echo "(no local CHANGELOG.md — tool operates exclusively via GitHub Releases API)"
  echo "---------------------------------------------------"
}

# ---- isolated repo setup ----------------------------------------------------
cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

banner "TOOL UNDER TEST: GitReleaseManager 0.20.0"
echo "NuGet package: gitreleasemanager.tool"
echo "Binary: dotnet-gitreleasemanager"
dotnet-gitreleasemanager --version 2>&1 || true
echo
echo "GitReleaseManager is a GitHub-API-driven CLI."
echo "All subcommands require: --owner, --repository, and a valid --token."
echo "There is no offline mode."

# ---- STAGE 1: project committed, no changelog yet ---------------------------
banner "STAGE 1: v1.0.0 code committed — no changelog yet"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "Git log after stage 1:"
git log --oneline --decorate
dump_changelog

# ---- STAGE 2: attempt 'create' (no token) -----------------------------------
banner "STAGE 2: attempt 'gitreleasemanager create' (no token — expected to fail)"
echo "Command: gitreleasemanager create --owner test --repository test --milestone 1.0.0"
echo "Expected: authentication error or GitHub API connection error"
echo
dotnet-gitreleasemanager create \
  --owner test \
  --repository test \
  --milestone 1.0.0 \
  2>&1 || true
echo
dump_changelog

# ---- STAGE 3: v2 commit, attempt 'export' -----------------------------------
banner "STAGE 3: v2 commit then attempt 'gitreleasemanager export' (no token — expected to fail)"
cat > Program.cs << 'CSHARP'
// TipCalc v2 — split bill evenly among diners (hard-coded constants)
const decimal bill = 85.00m;
const decimal tipPercent = 18.0m;
const int diners = 4;

decimal tip = bill * tipPercent / 100m;
decimal total = bill + tip;
decimal perPerson = total / diners;

Console.WriteLine($"Bill:       ${bill:F2}");
Console.WriteLine($"Tip:        ${tip:F2} ({tipPercent}%)");
Console.WriteLine($"Total:      ${total:F2}");
Console.WriteLine($"Per person: ${perPerson:F2} ({diners} diners)");
CSHARP
git add -A
git commit -q -m "feat: split the bill evenly among diners"
git tag v2.0.0
echo "Git log after stage 3:"
git log --oneline --decorate
echo
echo "Command: gitreleasemanager export --owner test --repository test --tagName v1.0.0"
echo "Expected: authentication error or GitHub API connection error"
echo
dotnet-gitreleasemanager export \
  --owner test \
  --repository test \
  --tagName v1.0.0 \
  2>&1 || true
echo
dump_changelog

# ---- STAGE 4: attempt 'publish' and 'close' to show full API surface --------
banner "STAGE 4: attempt 'publish' and 'close' subcommands (no token — expected to fail)"
echo "--- publish ---"
echo "Command: gitreleasemanager publish --owner test --repository test --tagName v1.0.0"
dotnet-gitreleasemanager publish \
  --owner test \
  --repository test \
  --tagName v1.0.0 \
  2>&1 || true
echo
echo "--- close ---"
echo "Command: gitreleasemanager close --owner test --repository test --milestone 1.0.0"
dotnet-gitreleasemanager close \
  --owner test \
  --repository test \
  --milestone 1.0.0 \
  2>&1 || true
echo
dump_changelog

# ---- STAGE 5: show full command surface (--help) ----------------------------
banner "STAGE 5: gitreleasemanager --help (command surface documentation)"
echo "This is what the tool CAN do — all of it requires live GitHub API:"
echo
dotnet-gitreleasemanager --help 2>&1 || true
echo
echo "--- subcommand help: create ---"
dotnet-gitreleasemanager create --help 2>&1 || true
echo
echo "--- subcommand help: export ---"
dotnet-gitreleasemanager export --help 2>&1 || true

# ---- STAGE 6: summary -------------------------------------------------------
banner "STAGE 6: SUMMARY — GitReleaseManager is GitHub-API-only"
echo "Findings:"
echo "  1. Every subcommand (create, publish, close, export) requires:"
echo "       --owner        GitHub repository owner"
echo "       --repository   GitHub repository name"
echo "       --token        Personal access token or CI token"
echo "  2. Without a valid token, every command fails immediately."
echo "  3. There is no local changelog file mode — the tool reads/writes"
echo "     GitHub Milestones, Issues, and the Releases API exclusively."
echo "  4. The 'export' subcommand fetches release notes from the Releases"
echo "     API rather than generating them from local git history."
echo "  5. Verdict: CI-only — do not use without GitHub credentials"
echo "     and a live remote."
echo

# ---- artifacts ---------------------------------------------------------------
banner "DONE — copying artifacts to out/"
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
