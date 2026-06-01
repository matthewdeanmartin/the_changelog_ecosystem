# Final Tasks Before Publish

This file tracks the remaining hand-editing work after the Python, Rust, Go, Java, and Node/npm review passes.

## Article Stub Prose Pass

Completed: all remaining article placeholder markers were replaced with prose in these review articles:

### Cross-platform / platform tools

- `content/articles/changelog-from-release.md`
- `content/articles/create-release-notes-from-changelog.md`
- `content/articles/github-automatically-generated-release-notes.md`
- `content/articles/gitlab-changelogs.md`
- `content/articles/glab-changelog.md`
- `content/articles/glab-release.md`
- `content/articles/logchange.md`
- `content/articles/release-cli.md`
- `content/articles/release-drafter.md`
- `content/articles/release-please.md`

### .NET / NuGet tools

- `content/articles/dotnet-releaser.md`
- `content/articles/gitreleasemanager.md`
- `content/articles/gitreleasenotes.md`
- `content/articles/gitversion.md`
- `content/articles/nerdbank-gitversioning.md`
- `content/articles/versionize.md`

### Ruby tools

- `content/articles/github-changelog-generator.md`

### C / C++ workflow pattern

- `content/articles/github-gitlab-git-cliff-changie-pattern.md`

## Completed Ecosystem Passes

These ecosystems have had their reviewed/on-radar article stubs filled and placeholder scans run:

- Python
- Rust
- Go
- Java
- Node / npm

## Verification To Run After Each Pass

Use direct `uv run` commands on this Windows/Git Bash setup. Avoid `just build` here because the current `Justfile` shell setting can route through WSL on this machine.

```bash
rg -n "<placeholder regex>" content/articles
uv run python generate_pages.py
uv run pelican content -o output -s pelicanconf.py
```

Expected Pelican build shape at this point:

```text
Processed 51 articles, 0 drafts, 0 hidden articles, 12 pages
```

## Final Site QA

- Re-run the placeholder-marker scan across `content/articles` and `spec`.
- Rebuild generated pages and Pelican output.
- Spot-check `/tools/`, `/tags/`, and each ecosystem page for link/rendering issues.
- Check that legacy/deprecated tools have honest verdicts and do not read like current recommendations.
- Check that generated pages under `content/pages/` were only updated through `generate_pages.py`.
