Title: Task Tracking
Date: 2026-07-01
Slug: task-tracking
sortorder: 7
Summary: Repo-native, plain-text task tracking — TODO.md, GFM task lists, todo.txt, TaskPaper, Org-mode — and the emerging bridge from completed tasks to changelog entries.

## Purpose

This section covers **repo-native task tracking**: plain-text task files that live
in the repository and are edited, diffed, and reviewed like code, rather than in a
hosted issue tracker.

It is a deliberately adjacent topic. This is a changelog-and-release-notes site,
and task tracking is a less standardized neighbor — but the two meet at a specific
point worth documenting: **completed repo-local tasks becoming curated changelog
entries.** That bridge (task planning → release notes with git-reviewable
provenance) is the reason task files belong here at all.

For the full tool inventory, start with [All Tools]({filename}tools.md). The goal
here is to explain the format choices and the small set of conventions worth
knowing, not to catalog every task app.

## Core Articles

- [TODO.md and GFM Task Lists]({filename}../articles/todo-md-gfm-task-lists.md) —
  the Markdown-in-repo pattern most projects orbit, and the GitHub-Flavored
  Markdown task-list primitive underneath it.
- [Portable Task Formats]({filename}../articles/portable-task-formats.md) —
  `todo.txt`, TaskPaper, and Org-mode: older, editor-agnostic formats with
  richer metadata conventions.
- [From Task Fragments to Changelog]({filename}../articles/task-fragments-to-changelog.md) —
  the fragment-aggregation pattern (`tasks.d/*` → `TASKS.md`/`CHANGELOG.md`) and
  tooling that promotes completed tasks into Keep a Changelog entries.

## The landscape at a glance

| Pattern | Shape | Best prior art |
|---|---|---|
| `TODO.md` / `TASKS.md` | Markdown headings as columns, GFM checkboxes | [todo.md standard](https://github.com/todomd/todo.md) |
| GFM task lists | `- [ ]` / `- [x]` items, render read-only on GitHub | [GFM spec](https://github.github.com/gfm/) |
| `todo.txt` | One line per task, priority/projects/contexts | [todotxt.org](https://todotxt.org/) |
| TaskPaper | Projects, tasks, notes, `@tags` | [taskpaper.com](https://www.taskpaper.com/) |
| Org-mode | TODO keywords, deadlines, properties | [orgmode.org](https://orgmode.org/features.html) |
| Task fragments | One Markdown file per card, aggregated later | [kanban-md](https://forum.golangbridge.org/t/kanban-md-file-based-kanban-cli-tui-for-multi-agent-workflows/41591), [Tasks.md](https://github.com/BaldissaraMatheus/Tasks.md) |

## Why it is adjacent, not core

"Tasks live in the repo" is not novel — that pattern is well established. The
narrower, more interesting claim is the one this section tracks: a completed
task, staged in a KAC category, can be **promoted into `[Unreleased]`** and become
part of the published changelog. Today the clearest example on this site is
[keepachangelog-manager-fork]({filename}../articles/keepachangelog-manager.md),
which supports `TASKS.md` / `tickets/` fragments flowing into a Keep a Changelog
file — see [From Task Fragments to Changelog]({filename}../articles/task-fragments-to-changelog.md).
