Title: git-chglog (hands-on synthesis)
Date: 2026-06-02
Slug: git-chglog-v2
Ecosystem: go
Tags: go, conventional-commits, templates, archived, git-history, hands-on
Tool_URL: https://github.com/git-chglog/git-chglog
Tool_Version: 0.15.4
Tool_Status: archived
Experiment: examples/go/git-chglog/
Summary: Hands-on re-review of git-chglog — an archived Go changelog generator that still works.



## What I actually ran

The experiment ran `git-chglog` v0.15.4 inside a Debian container against a three-release
shell-script fixture with tagged Conventional Commits messages. Three stages were tested:

1. **Single-tag generation** — `git-chglog --output CHANGELOG.md v1.0.0` to bootstrap
   a changelog for the first release.
2. **Incremental regeneration** — `git-chglog --output CHANGELOG.md` after tagging v2.0.0
   to produce a two-version changelog in one pass.
3. **Breaking change** — a `feat!:` commit with a `BREAKING CHANGE:` footer tagged as v3.0.0,
   then a full-history regeneration.

Config was provided manually (`scenario/config.yml` and `scenario/CHANGELOG.tpl.md`) rather
than using the interactive `--init` wizard. One adjustment was required: the `pattern_maps`
list must match the number of regex capture groups exactly; using a two-group pattern with a
three-entry list causes silent mismatches.

Full files: `examples/go/git-chglog/`

## Real output

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

- v2.0.0 and v3.0.0 headers rendered as compare-range hyperlinks; v1.0.0 (no previous tag)
  rendered as a plain heading. Both are correct.
- The `BREAKING CHANGE` footer content appeared in a dedicated section under v3.0.0.
- The `docs:` commit was silently filtered out per the type filter — expected and correct.
- Generation time was under 10 ms for a three-tag repo.

## Pros

- **Works as documented.** Install the binary, supply config and template, run — done.
  No hidden runtime dependencies or OS quirks in 2026.
- **Template power.** Go `text/template` plus a set of helper functions gives precise
  control over every line of output. If the built-in style does not match your house style,
  you can rewrite the template rather than working around a hard-coded renderer.
- **Language-agnostic.** The tool reads git history; it does not care what language the
  repository contains. Works equally well for shell scripts, Go modules, Python packages,
  or anything else tracked with Conventional Commits.
- **Single-tag and full-history modes both work.** You can bootstrap a changelog for an
  existing repo's entire history with one command, or generate only the newest release.
- **Breaking change detection is solid.** `feat!:` and `BREAKING CHANGE:` footers both
  parsed and surfaced correctly.
- **Fast.** Sub-10 ms generation on a small repo; acceptable even at large tag counts.

## Cons

- **Archived.** The repository has been read-only since February 2023. Bug reports
  and pull requests are open but unanswered. Any regression or compatibility issue
  with a future git version will not be fixed upstream.
- **Config is verbose and brittle.** The `pattern_maps` count must match the regex
  capture group count exactly, with no helpful error message when they diverge. The
  original documented three-group config silently produces wrong output if pasted
  without understanding the coupling.
- **No built-in scope support in the simplified pattern.** Supporting commit scopes
  requires a three-group regex plus a matching three-entry `pattern_maps`. This is
  not hard, but it is a non-obvious configuration step.
- **No incremental update.** Every run rewrites the whole file. In very large repos
  with hundreds of tags, this is slower than tools that append incrementally.
- **Template syntax is unforgiving.** Whitespace control in Go templates (the `-` trim
  markers) must be placed precisely; misplaced markers produce blank-line noise or
  drop content silently.
- **Tooling ecosystem is frozen.** No new integrations, GitHub Actions, or IDE plugins
  will be built for this tool. Users must wire it into CI themselves.

## Docs vs. reality

The official documentation and README are accurate for the features that were implemented
before archival. The template reference, config schema, and `--init` wizard all reflect
the actual behavior of v0.15.4.

One real gap: the README shows a three-capture-group header pattern with `Type`, `Scope`,
and `Subject` mapped in `pattern_maps`. If you copy that config verbatim but use a
two-group regex (dropping the optional scope group), generation silently produces wrong
groupings. The documentation does not call out the coupling between group count and
`pattern_maps` length, which is the single most confusing part of first-time setup.

The `datetime` template helper uses standard Go time-format strings (e.g., `"2006-01-02"`),
not strftime notation. This is consistent with Go conventions but catches users coming from
Ruby or Python-based generators.

## Revised verdict

**Verdict: Legacy — use only for existing installations**

git-chglog still works in 2026. The binary installs cleanly, the core changelog generation
pipeline functions correctly, and the output quality is good when commit messages follow
Conventional Commits. Nothing is broken.

The decisive issue is the archived status. The repository has received no updates since
February 2023. That means no security patches, no compatibility fixes for future git
versions, and no responses to issues or pull requests. For new projects starting today,
choosing git-chglog means accepting a frozen dependency with no upstream support path.

For teams that already have git-chglog with working templates: continue using it. There
is no urgent need to migrate, and the tool is stable enough to keep running. Plan a
migration in your own time rather than as an emergency.

For new projects: use `git-cliff` instead. It is actively maintained, supports the same
Conventional Commits workflow, offers comparable template flexibility via TOML/Tera, and
has a significantly larger active community. For Go projects that want integrated release
automation beyond just changelog generation, GoReleaser is the broader alternative.

The archived status is not a reason to panic about existing use; it is a reason to not
start new use.
