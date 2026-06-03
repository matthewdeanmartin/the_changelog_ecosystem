Title: git-chglog
Date: 2026-06-02
Slug: git-chglog
Ecosystem: Go
Tags: backfill, conventional-commits, git-tags, go, go-cli, custom-templates, changelog-file, archived, templates, git-history, hands-on
Tool_URL: https://github.com/git-chglog/git-chglog
Tool_Version: 0.15.4
Tool_Status: archived
Experiment: examples/go/git-chglog/
Summary: An archived but still-working Go changelog generator that renders git tags and commits through Go templates — hands-on testing confirms it runs cleanly in 2026.



## Overview

`git-chglog` is a Go-based changelog generator that reads git tags and commits, groups them by configured rules, and renders a changelog through Go templates. Historically, it was one of the stronger standalone choices for Conventional Commits-style changelog generation before `git-cliff` became the more active cross-language default.

Its main value today is existing installations and backfill workflows. It can still generate useful output — our hands-on run confirmed it works cleanly — but the archived repository status should shape any new adoption decision.

> A reproducible hands-on experiment for this tool lives in [`examples/go/git-chglog/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/git-chglog). We drove git-chglog through a real three-release life cycle in an offline Docker container; the real output and findings are at the end of this article.

## Installation

```bash
# Pre-built binaries from GitHub Releases (Linux/macOS/Windows), plus
# Homebrew and package managers:
# https://github.com/git-chglog/git-chglog
```

## What It Does

- Generates changelogs from git tag ranges such as `v1.0.0..v1.1.0`.
- Supports Conventional Commits-like grouping by type, scope, subject, issues, refs, merges, and reverts.
- Uses YAML configuration in `.chglog/config.yml`.
- Renders output with Go `text/template` plus Sprig-style helper functions.
- Supports custom templates, repository URLs, path filters, and output files.
- Can backfill a `CHANGELOG.md` from existing tag history.

## Configuration

`git-chglog --init` creates `.chglog/config.yml` and a template file. The config is explicit and powerful, but it is more old-school than current `git-cliff` configuration.

```yaml
bin: git
style: github
template: CHANGELOG.tpl.md
info:
  title: CHANGELOG
  repository_url: https://github.com/example/project
options:
  tag_filter_pattern: '^v'
  sort: date
  commits:
    filters:
      Type:
        - feat
        - fix
  commit_groups:
    group_by: Type
    title_maps:
      feat: Features
      fix: Bug Fixes
```

First-run setup is moderate: you need both config and template files, and teams should understand their commit format before relying on the output. **One sharp edge worth flagging up front (confirmed in testing):** the header `pattern_maps` list must match the number of regex capture groups exactly. The README's three-group `Type`/`Scope`/`Subject` example, pasted with a two-group regex, silently produces wrong groupings with no error.

## Ecosystem Fit

The tool is implemented in Go and distributed as a CLI, so it remains easy to install in Go-oriented environments. It is not Go-specific in behavior, though; it is a general git changelog generator — our run drove it against a plain shell-script repo.

In new projects, `git-cliff` usually offers a more active path with similar or better flexibility. Existing `git-chglog` users with stable templates can continue using it, but should plan around the archived status.

## Maintenance Status

- Latest version: **0.15.4**
- Last release: **2023-02-15**
- GitHub stars: **2,874**
- **Repository is archived** — no new development expected.
- Repository: <a href="https://github.com/git-chglog/git-chglog" target="_blank" rel="noopener noreferrer">https://github.com/git-chglog/git-chglog</a>

The documentation and repository remain available, but the archived state makes it a maintenance risk for new release infrastructure. Bug reports and pull requests are open but unanswered; any regression or compatibility issue with a future git version will not be fixed upstream. It is not unusable — but if you adopt it for the long term you are effectively taking on a frozen dependency you may eventually need to fork and maintain yourself.

---

## Hands-On Findings

We ran `git-chglog` v0.15.4 inside a Debian container against a three-release shell-script fixture with tagged Conventional Commits messages. Config and template were supplied manually (`scenario/config.yml`, `scenario/CHANGELOG.tpl.md`) rather than using the interactive `--init` wizard. Full files and transcript are in [`examples/go/git-chglog/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/go/git-chglog).

**The tool worked.** Despite the archived status, the binary installed cleanly and drove the full life cycle without any breakage in 2026. Three stages were exercised: single-tag generation (`git-chglog --output CHANGELOG.md v1.0.0`), incremental two-version regeneration after tagging v2.0.0, and a `feat!:` breaking change with a `BREAKING CHANGE:` footer tagged v3.0.0 followed by a full-history regeneration.

### Real output

```markdown
<a name="v3.0.0"></a>
## [v3.0.0](https://github.com/example/tipcalc/compare/v2.0.0...v3.0.0) (2026-06-02)

### Features

- split the bill unevenly by weight

### BREAKING CHANGE

output format changes — per-person amounts replace single total line


<a name="v2.0.0"></a>
## [v2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)

### Features

- split the bill evenly among diners


<a name="v1.0.0"></a>
## v1.0.0 (2026-06-02)

### Features

- compute tip for a single bill
```

Notable details:

- v2.0.0 and v3.0.0 headers rendered as compare-range hyperlinks; v1.0.0 (no previous tag) rendered as a plain heading. Both correct.
- The `BREAKING CHANGE` footer content appeared in a dedicated section under v3.0.0.
- The `docs:` commit was silently filtered out per the type filter — expected and correct.
- Generation time was under 10 ms for a three-tag repo.

### Pros (observed)

- **Works as documented.** Install the binary, supply config and template, run — done. No hidden runtime dependencies or OS quirks in 2026.
- **Template power.** Go `text/template` plus helper functions gives precise control over every line of output. You can rewrite the template rather than working around a hard-coded renderer.
- **Language-agnostic.** It reads git history and does not care what language the repo contains.
- **Single-tag and full-history modes both work.** Bootstrap a changelog for an entire repo history in one command, or generate only the newest release.
- **Breaking change detection is solid.** Both `feat!:` and `BREAKING CHANGE:` footers parsed and surfaced correctly.
- **Fast.** Sub-10 ms generation on a small repo.

### Cons (observed)

- **Archived.** Read-only since February 2023. No security patches, no compatibility fixes for future git versions, no responses to issues or PRs.
- **Config is verbose and brittle.** The `pattern_maps` count must match the regex capture-group count exactly, with no helpful error when they diverge.
- **Scope support is non-obvious.** Supporting commit scopes requires a three-group regex plus a matching three-entry `pattern_maps` — not hard, but not discoverable.
- **No incremental update.** Every run rewrites the whole file; slower than append-based tools in repos with hundreds of tags.
- **Template syntax is unforgiving.** Go-template whitespace trim markers (`-`) must be placed precisely or you get blank-line noise or silently dropped content.
- **Tooling ecosystem is frozen.** No new integrations, Actions, or plugins will be built; you wire it into CI yourself.

### Docs vs. reality

The official docs and README are accurate for the features implemented before archival — the template reference, config schema, and `--init` wizard all reflect v0.15.4 behavior. The one real gap is the `pattern_maps`/capture-group coupling described above, which is the single most confusing part of first-time setup. Also note the `datetime` helper uses Go time-format strings (`"2006-01-02"`), not strftime — a trap for users coming from Ruby or Python generators.

## Verdict

**Verdict: Legacy — use only for existing installations.**

git-chglog still works in 2026. The binary installs cleanly, the core generation pipeline functions correctly, and output quality is good when commit messages follow Conventional Commits. Nothing is broken.

The decisive issue is the archived status — no updates since February 2023, no upstream support path. For teams that already have git-chglog with working templates, continue using it; the tool is stable enough to keep running, and you can plan any migration in your own time rather than as an emergency. If you depend on it long-term, be ready to fork and patch it yourself should a future git version break something.

For new projects, prefer `git-cliff`: actively maintained, the same Conventional Commits workflow, comparable template flexibility via TOML/Tera, and a much larger active community. For Go projects wanting integrated release automation beyond changelog generation, GoReleaser is the broader alternative. The archived status is not a reason to panic about existing use — it is a reason to not start new use.
