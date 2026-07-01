# Stub Audit

Snapshot of all visible "stub" evidence in this repository, plus the follow-up work it suggests.

## Summary

There are **three different meanings** of "stub" in this repo:

1. **Generated review stubs** for article authoring.
2. **Historical/project-planning references** to the stub workflow.
3. **Tool-behavior stubs/placeholders** described inside reviews and example notes.

The authoring workflow still exists and is documented in several places. The live article set appears largely de-stubbed: a repo-wide check found **no `_TODO_` or `<!-- TODO ... -->` markers in `content/articles/*.md`**. The remaining actionable gap is that **`python-kacl` has no article file yet**, and **three existing articles are not marked `reviewed: true` in `data/tools.json` even though they already exist and have ratings**.

## 1. Generated review stub machinery

These files define or document the actual stub workflow:

| File | Evidence | Notes |
| --- | --- | --- |
| `generate_review_stubs.py:1-11` | "Phase 3 — generate stub review articles for all unreviewed tools." | Canonical generator for article stubs. |
| `generate_review_stubs.py:185-275` | `render_stub()` emits the article body with `_TODO_` text and `<!-- TODO ... -->` comments | This is the machine-generated stub template. |
| `justfile:68-78` | `stubs`, `stubs-must`, `stubs-force` recipes | Main entry points for generating or overwriting stubs. |
| `AGENTS.md:17-18, 42` | stubs are never overwritten by `just stubs`; `just stubs` creates missing stub articles | Agent-facing repository rule. |
| `CLAUDE.md:10, 23, 35` | `just stubs` generates stub review articles; `content/articles/*.md` includes review stubs | Secondary maintainer/agent notes. |
| `CONTRIBUTING.md:36, 43-45, 75-82, 167-189, 204` | contributor workflow explicitly says "Generate a stub review article" and replace `_TODO_` markers | Human maintainer documentation. |
| `rtd/index.md:11, 24` | review stubs are part of the public maintainer docs | Read the Docs landing page. |
| `rtd/adding-tools.md:48-55` | "Create any missing review stubs" with `just stubs` | Tool-addition workflow. |
| `rtd/maintainer-guide.md:8-10` | "Stubs are generated" and preserved by the normal workflow | Layout/maintenance guidance. |

## 2. Historical/project-history references

These references are about the project having used stubs, not about current content being unfinished:

| File | Evidence | Notes |
| --- | --- | --- |
| `spec/spec.md:22` | "first stub review (keepachangelog-manager)" | Stub creation was part of the original project bootstrap. |
| `spec/final_tasks.md:41` | "article stubs filled" | Indicates ecosystem passes were tracked as stub-completion work. |
| `scripts/rewrite_history.py:61-76, 84` | "generate 50 review stubs", "Patched Summary frontmatter in 11 existing article stubs", "first draft everywhere" | Git-history rewrite notes preserve the repo's stub-heavy early phase. |

## 3. Stub mentions inside reviews/examples/tool behavior

These are **not** repository authoring stubs. They describe tools that emit their own stub/placeholder content.

| File | Evidence | Meaning |
| --- | --- | --- |
| `content/articles/cargo-dist.md:131` | "`cargo-dist init` ... created `dist-workspace.toml` ... These stubs are genuinely useful to inspect." | Generated config stubs from the tool under review. |
| `content/articles/org-jetbrains-changelog.md:95, 158, 162, 166` | bracketless `## Unreleased` stub left by `patchChangelog` | Tool behavior, not site-authoring workflow. |
| `examples/java/README.md:10, 18, 26` | warns about org.jetbrains.changelog leaving a stub | Example-suite documentation. |
| `examples/java/org-jetbrains-changelog/NOTES.md:268, 276` | detailed notes on the lingering `## Unreleased` stub | Experiment notes. |
| `content_old/cargo-dist.v2.md:60` | old version of cargo-dist review mentions config stubs | Historical content copy. |
| `content_old/org-jetbrains-changelog.v2.md:74, 152, 160, 168` | old version of review discusses `## Unreleased` stub behavior | Historical content copy. |

Related but not literal "stub" language:

- `content/articles/com-diffplug-spotless-changelog.md:132,163` discusses an empty `## [Unreleased]` **placeholder** left behind for the next release cycle.
- `content/articles/changelog-validation-boundaries.md:131` discusses teams adding **placeholder** entries under `[Unreleased]`.

## 4. Current live-state findings

### 4.1 No obvious unfinished review stubs remain in `content/articles`

Repo search result:

- `content/articles/*.md` contains **no** `_TODO_`
- `content/articles/*.md` contains **no** `<!-- TODO ... -->`

That strongly suggests the live review corpus is no longer carrying machine-generated stub markers.

### 4.2 One tool is missing an article file entirely

Current unreviewed tool entries in `data/tools.json`:

- `GitHub/GitLab + git-cliff/Changie pattern`
- `@changesets/changelog-github`
- `@semantic-release/release-notes-generator`
- `python-kacl`

Article-file existence check:

- `content/articles/github-gitlab-git-cliff-changie-pattern.md` — exists
- `content/articles/changesets-changelog-github.md` — exists
- `content/articles/semantic-release-release-notes-generator.md` — exists
- `content/articles/python-kacl.md` — **missing**

Implication: **`python-kacl` is the one current case where `just stubs` still has real work to do.**

### 4.3 Three completed articles are still treated as "unreviewed" in `tools.json`

The following tools have all of the following at once:

1. article files exist
2. rating rows exist in `data/tool_ratings.csv`
3. `data/tools.json` still says `reviewed: false` and `review_slug: null`

Affected tools:

- `GitHub/GitLab + git-cliff/Changie pattern`
- `@changesets/changelog-github`
- `@semantic-release/release-notes-generator`

Evidence:

- Article files exist in `content/articles/*.md`
- Ratings exist in `data/tool_ratings.csv:11,24,49`
- `data/tools.json:1-20, 690-730` still shows `reviewed: false`

Likely cause:

- `generate_pages.py` only auto-syncs review status by simple slug/name heuristics.
- That heuristic appears to miss:
  - scoped npm package names like `@changesets/changelog-github`
  - scoped npm package names like `@semantic-release/release-notes-generator`
  - workflow-pattern names like `GitHub/GitLab + git-cliff/Changie pattern`

This is not a stub-content problem, but it **is** a stub/workflow bookkeeping bug.

## 5. TODO

### Immediate

- [ ] Generate or hand-write `content/articles/python-kacl.md`
- [ ] Mark the three existing reviewed articles as reviewed in `data/tools.json`

### Near-term cleanup

- [ ] Decide whether "stub" references in `spec/`, `scripts/rewrite_history.py`, and maintainer docs should remain as historical record or be trimmed
- [ ] Decide whether `content_old/*.v2.md` should remain searchable in the repo, since they preserve obsolete stub-related narratives

### Workflow hardening

- [ ] Fix `generate_pages.py` review-sync logic so it recognizes existing articles for scoped npm packages and workflow-pattern names
- [ ] Consider syncing `reviewed:true` from `data/tool_ratings.csv` when a rating row exists, since a rated article is functionally no longer a stub

