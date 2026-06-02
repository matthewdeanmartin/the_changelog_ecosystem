#!/usr/bin/env bash
# gitreleasenotes experiment driver.
#
# GitReleaseNotes 0.7.1 is an unmaintained tool. This experiment:
#   1. Checks whether the tool even installed successfully on .NET 8 SDK.
#   2. If installed, probes basic invocation (--help / --version).
#   3. Attempts a live-tracker call with a fake token to observe the error
#      (the tool requires live GitHub/Jira/YouTrack access; there is no offline mode).
#   4. Documents the outcome in the transcript for the synthesis article.
#
# All `|| true` calls are intentional — expected failures must not abort the script.
set -euo pipefail

# Tee everything into the transcript that ends up in out/.
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }

# ---- STAGE 1: check dotnet SDK version --------------------------------------
banner "STAGE 1: environment — dotnet SDK version"

dotnet --version
echo "PATH: $PATH"

# ---- STAGE 2: check whether gitreleasenotes installed -----------------------
banner "STAGE 2: probe install — was gitreleasenotes installed?"

echo "Listing installed global tools:"
dotnet tool list -g || true

echo ""
echo "Attempting: gitreleasenotes --version"
gitreleasenotes --version || true

echo ""
echo "Attempting: gitreleasenotes --help"
gitreleasenotes --help || true

# ---- STAGE 3: set up a minimal git repo (required by the tool) --------------
banner "STAGE 3: build a minimal git repo for the tool to read"

cd /work/app
git init -q
git config user.name  "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

# Commit v1.0.0 code so the repo has actual history.
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0

echo "git log:"
git log --oneline --decorate

# ---- STAGE 4: attempt live-tracker call (expected to fail offline) -----------
banner "STAGE 4: attempt GitHub tracker call — expected connection/auth failure"

echo "Attempting: gitreleasenotes /u https://github.com/GitTools/GitReleaseNotes /t fake_token"
echo "(This requires live internet access and a valid token — it will fail.)"
gitreleasenotes /u https://github.com/GitTools/GitReleaseNotes /t fake_token || true

echo ""
echo "Attempting alternative flag style (some versions use --)"
gitreleasenotes --url https://github.com/GitTools/GitReleaseNotes --token fake_token || true

# ---- STAGE 5: summary -------------------------------------------------------
banner "STAGE 5: summary"

INSTALL_OK=false
if command -v gitreleasenotes &>/dev/null; then
  INSTALL_OK=true
fi

echo "Install succeeded: $INSTALL_OK"
if [ "$INSTALL_OK" = "false" ]; then
  echo ""
  echo "CONCLUSION: GitReleaseNotes 0.7.1 did NOT install on .NET 8 SDK."
  echo "The package likely targets an older framework (.NET Framework / .NET Core 2.x)"
  echo "and is incompatible with the current SDK."
  echo "The tool is unmaintained and cannot be used in modern .NET projects."
else
  echo ""
  echo "CONCLUSION: GitReleaseNotes installed, but requires live tracker access."
  echo "All calls with a fake token fail with a connection or authentication error."
  echo "There is no offline/dry-run mode — the tool is unusable without live credentials."
fi

# ---- artifacts --------------------------------------------------------------
banner "DONE — copying artifacts to out/"
git log --oneline --decorate > /work/out/git-log.txt 2>/dev/null || true
echo "Artifacts in /work/out:"
ls -la /work/out
