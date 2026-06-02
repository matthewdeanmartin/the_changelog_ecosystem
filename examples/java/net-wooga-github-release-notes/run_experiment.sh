#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /work/out/transcript.txt) 2>&1

banner() { echo; echo "==================== $* ===================="; echo; }

cd /work/app
git init -q
git config user.name "Experiment Bot"
git config user.email "bot@example.invalid"
git config commit.gpgsign false

echo "Plugin: net.wooga.github-release-notes 4.1.1"
gradle --version | head -3

# STAGE 1: basic project setup
banner "STAGE 1: v1.0.0 code setup"
git add -A
git commit -q -m "feat: compute tip for a single bill"
git tag v1.0.0
echo "Committed v1.0.0 and tagged."

# STAGE 2: discover available tasks
banner "STAGE 2: list all tasks registered by the plugin"
gradle --no-daemon tasks --all 2>&1 | head -80 || true

# STAGE 3: try task help
banner "STAGE 3: task help / dry-run"
gradle --no-daemon help --task githubPublish 2>&1 || true
gradle --no-daemon githubPublish --dry-run 2>&1 || true

# STAGE 4: attempt actual invocation (expected to fail without GitHub token)
banner "STAGE 4: attempt githubPublish (expected: FAILED — no GitHub token)"
gradle --no-daemon githubPublish 2>&1 || echo "FAILED as expected — requires GITHUB_TOKEN"

# STAGE 5: document what we know
banner "STAGE 5: summary"
echo "Project properties (version line):"
gradle --no-daemon properties 2>&1 | grep 'version:' || true
echo ""
echo "Available release-notes related tasks:"
gradle --no-daemon tasks --all 2>&1 | grep -i -E "(release|notes|github|publish)" || echo "(none found or plugin failed to apply)"

banner "DONE — copying artifacts to out/"
git log --oneline --decorate > /work/out/git-log.txt
git tag > /work/out/git-tags.txt
echo "Artifacts in /work/out:"; ls -la /work/out
