Title: From Task Fragments to Changelog
Date: 2026-07-01
Slug: task-fragments-to-changelog
Ecosystem: Cross
Tags: task-tracking, keep-a-changelog, news-fragments, release-notes, python
Tool_Status: research
Summary: The fragment-aggregation pattern applied to tasks — one file per card, promoted later into TASKS.md or a changelog — and how keepachangelog-manager-fork bridges completed TASK.md items into Keep a Changelog entries.

## Overview

The most original idea in repo-native task tracking is not that tasks live in the
repo — it is that **completed tasks become curated changelog entries**, with the
task's history reviewable in git. This article covers that bridge: the
fragment-aggregation pattern borrowed from release-note tooling, and the concrete
tooling that promotes finished tasks into a [Keep a Changelog]({filename}keep-a-changelog.md)
file.

## The fragment analogy

Changelog-fragment systems already solved "many small files aggregated into one
document later." [Towncrier](https://towncrier.readthedocs.io/en/stable/markdown.html),
[Scriv]({filename}scriv.md), and [reno]({filename}reno.md) collect per-change
fragments from a `changelog.d/` directory and assemble a `CHANGELOG.md` at release
time. The task-management cousin is the same shape, one directory over:

```text
changelog.d/*.md  ->  CHANGELOG.md        (Towncrier / Scriv / reno)
tasks.d/*.md      ->  TASKS.md / CHANGELOG.md
```

Tools like [kanban-md](https://forum.golangbridge.org/t/kanban-md-file-based-kanban-cli-tui-for-multi-agent-workflows/41591)
(one Markdown file per card, with YAML frontmatter, committed alongside code) and
[Tasks.md](https://github.com/BaldissaraMatheus/Tasks.md) (a self-hosted board
where each card is a Markdown file) are the "one file per task" analog of changelog
fragments. This model is well suited to multi-agent and PR-reviewed workflows,
where each task change shows up as a reviewable diff.

## Where the two ecosystems meet

A fragment on the task side and a fragment on the changelog side are close enough
that a single tool can carry a unit of work across the boundary: stage it as a
task, and when it is done, promote it into the changelog. That promotion — task
provenance in git, then a curated release note — is the narrow, useful bridge this
whole section exists to document.

## keepachangelog-manager-fork: TASK.md → changelog

The clearest working example on this site is
[keepachangelog-manager-fork]({filename}keepachangelog-manager.md). It supports
staging future release notes in a `TASKS.md` file (or richer `tickets/` fragments)
and **promoting completed items into the `[Unreleased]` section** of a Keep a
Changelog file:

```toml
# changelogmanager.toml
[component.client]
changelog = "client/CHANGELOG.md"
tasks_file = "client/TASKS.md"
```

Work is staged in KAC categories in `TASKS.md`, then promoted into `[Unreleased]`,
and finally released into a versioned section — all as ordinary, human-readable
Keep a Changelog Markdown rather than a generated commit digest. That task-staging
workflow is distinctive: most of the ecosystem generates changelogs from commit
history, whereas this treats the changelog as a first-class artifact fed by curated
tasks. See its [full review]({filename}keepachangelog-manager.md) for the complete
command set (task promotion, fragment collection, backfill, validation, release).

## When the bridge is worth it

The task-to-changelog bridge pays off when:

- release notes should be **curated prose**, not raw commit subjects;
- you want **git-reviewable provenance** from planned task to published note; and
- your team is comfortable staying inside the [Keep a Changelog]({filename}keep-a-changelog.md)
  model rather than a Conventional-Commits release bot.

If instead you want changelogs generated automatically from commits, a
commit-driven generator is a better fit, and the task file is just a planning
convenience — see [TODO.md and GFM Task Lists]({filename}todo-md-gfm-task-lists.md)
for that lighter-weight approach.
