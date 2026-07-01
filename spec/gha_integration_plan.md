# Plan: Integrating GitHub Actions changelog tools

Status: proposed. Source list: `spec/so_many_gha.md` (37 marketplace actions).

## Problem

A batch of ~37 GitHub Actions for changelog/release-notes needs to land on the
site, but:

- Many are **GHA wrappers of tools already reviewed** (semantic-release,
  changesets, git-chglog, release-please) — reviewing them again duplicates prose.
- Many are **thin/low-value** (Commits→Changelog is ~1 line; Chalogen; rtf42-*;
  quant-eagle; dlavrenuek) — not worth burning tokens on a full article.
- Some marketplace links are **missing** in the source table.
- GHA is a **major distribution channel**, so ignoring it is wrong.
- We must not let GHA **bury the Recommended tools** in low-effort noise.

## Key architecture facts (verified in code, not docs)

- The live store is `data/tools.json` (via `pipeline/tool_store.py`), NOT
  `top_prio_tools.toml` (that TOML is a dead one-time seed).
- `gather_metadata.py` already enriches **any tool with a `github.com` repo**
  (stars, archived) and pulls latest-release version/date when
  `distribution == "github"`. So GHA actions need no new metadata pipeline.
- `generate_pages.py` buckets tools into recommended / situational /
  not_recommended and renders `tools.md` + per-ecosystem pages. There is
  currently **no `github-action` ecosystem** — the 3 existing actions
  (Release Drafter, release-please, Create-release-notes) sit in `cross`.
- Verdicts come from `data/tool_ratings.csv` (primary) or the article
  `**Verdict:**` line (fallback).

## Design: a contained "GitHub Actions" surface, three tiers

GHA actions become normal `tools.json` records with:

```json
"ecosystem": "github-action",
"distribution": "github",
"repo": "https://github.com/owner/repo",
"gha_tier": 1 | 2 | 3,
"wraps": "semantic-release"   // slug of engine review, tier-2 only
"marketplace_url": "https://github.com/marketplace/actions/..."
```

Because `ecosystem == "github-action"` is new, `generate_pages.py` routes it to
its **own page** and **excludes it from the ecosystem tables and the `tools.md`
Recommended/Situational flood**. This is the anti-burial mechanism: GHA lives on
one page and cannot swamp git-cliff et al.

`distribution == "github"` + a `repo` means `gather_metadata.py` fills stars /
version / archived automatically (decision: reuse the existing fetcher).

### Tier 1 — Full review (~6 tools, most already done)

Genuinely distinct behavior; deserve a real article + `tool_ratings.csv` row.

- Release Drafter — `release-drafter/release-drafter` *(reviewed)*
- release-please — `googleapis/release-please-action` *(reviewed)*
- Release Changelog Builder — `mikepenz/release-changelog-builder-action`
- Changesets Action — `changesets/action`
- Action For Semantic Release — `cycjimmy/semantic-release-action`
- Conventional Changelog Action — `TriPSs/conventional-changelog-action`

### Tier 2 — "GHA distribution of X" (cross-reference, no new article)

One catalog-table row: action name + marketplace link + "wraps
[engine](review)". `wraps` points at an existing review slug. **No prose, no
`tool_ratings.csv` row** (inherits the engine's verdict for display).

- cycjimmy/semantic-release-action → semantic-release
- changesets/action → changesets
- git-chglog action (nuuday) → git-chglog
- python-semantic-release, go-semantic-release/action
- go-changelog-generator (somaz94), generic-conventional-changelog (dlavrenuek)
- changeset-github-release, changesets-gh, the-guild-org changesets-deps

### Tier 3 — Thin / low-value (list only, capped, no article ever)

One row in a single "Also on the Marketplace" table. Never gets an article,
never appears on a recommender surface. One-liner description only.

- Commits→Changelog one-liners, Chalogen, rtf42-*, quant-eagle/*,
  bsord conventional-bump, single-purpose validators/extractors/readers,
  ChangesetsSnapshot, ChangesetsDependencies.

## New/changed files

| File | Change |
|------|--------|
| `data/gha_actions.toml` | **New.** Hand-curated source of the 37 actions: id, name, repo, marketplace_url, tier, wraps, one-liner. The editable seed. |
| `sync_gha_actions.py` (or extend `discover`) | **New.** Reads `gha_actions.toml`, upserts `github-action` records into `tools.json` (via `tool_store.merge`). Idempotent, `--dry-run`. |
| `gather_metadata.py` | No change needed — github repos already enriched. |
| `generate_pages.py` | Add `github-action` to `ECOSYSTEM_LABELS`; route it to a dedicated `generate_gha_page()` grouped by the 5 categories + tier; **exclude it from `tools.md` bucket tables and ecosystem pages** so it can't flood them. |
| `content/pages/github-actions.md` | **Generated.** Tier-1 = linked reviews; Tier-2 = table linking to engine reviews + marketplace; Tier-3 = compact "also available" table. |
| theme nav / `sortorder` | Add the new page to the menu (decision: own page + nav entry). |
| `data/tool_ratings.csv` | Add rows for the ~4 unreviewed Tier-1 actions only. |
| `content/articles/*.md` | New review stubs for unreviewed Tier-1 only (via `just stubs`). |
| `CONTRIBUTING.md` / `CLAUDE.md` | Document the `gha_tier` / `wraps` fields and the "GHA never on recommender surfaces" rule. |

## Token / effort budget

- Tier 1: ~4 new short reviews (2 already exist). Real prose, but bounded.
- Tier 2: **zero** new prose — table rows generated from TOML.
- Tier 3: **zero** new prose — one hand-written line each in the TOML.

## Missing-link handling

`marketplace_url` is an explicit column in `gha_actions.toml`. Entries left blank
are rendered as "marketplace link needed" and can be filled incrementally — a
`--check-links` pass (reuse `scripts/check_links.py`) can flag blanks/404s.

## Anti-burial guarantees (maps to the stated worry)

1. `github-action` ecosystem is **excluded** from `tools.md`'s Recommended/
   Situational/Not-Recommended tables and from every `{ecosystem}.md` page.
2. GHA lives on **one** page reachable from the nav — discoverable, not dominant.
3. Tier-2/3 never appear on `decision-chart.md`, `decision-helper.md`, or topic
   "see also" lists (extends the existing `recommendable: no` rule).
4. Tier-1 actions may be cross-linked from relevant topic pages like any tool.

## Build order

1. Author `data/gha_actions.toml` from `spec/so_many_gha.md` (assign tiers,
   fill known marketplace URLs, one-liners).
2. Write `sync_gha_actions.py`; run `--dry-run`, then upsert into `tools.json`.
3. Run `just gather` — auto-fills stars/version for the github repos.
4. Extend `generate_pages.py` (label + dedicated page + exclusions).
5. `just stubs` for unreviewed Tier-1; write those ~4 reviews; add CSV rows.
6. Add nav entry; `just build`; `just devserver` to eyeball.
7. Update `CONTRIBUTING.md` / `CLAUDE.md`.
```
