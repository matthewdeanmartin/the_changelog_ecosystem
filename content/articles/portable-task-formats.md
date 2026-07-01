Title: Portable Task Formats
Date: 2026-07-01
Slug: portable-task-formats
Ecosystem: Cross
Tags: task-tracking, plain-text, todo-txt, org-mode
Tool_Status: research
Summary: todo.txt, TaskPaper, and Org-mode — three older, editor-agnostic plain-text task formats with richer metadata conventions than GFM checkboxes, and what each contributes as prior art.

## Overview

Before `TODO.md`, several plain-text task formats already solved "tasks in a file
you control." They are less GitHub-native than Markdown checkboxes, but they carry
more structured metadata — priorities, dates, projects, contexts, deadlines — and
are strong prior art for anyone designing a task-to-changelog workflow. Three are
worth knowing: **todo.txt**, **TaskPaper**, and **Org-mode**.

## todo.txt

[todo.txt](https://todotxt.org/) is a one-line-per-task format: software- and
OS-agnostic, searchable, and portable. Each line encodes priority, dates,
projects (`+`), and contexts (`@`) positionally:

```txt
(A) 2026-07-01 Add TASKS.md parser +kacl @repo due:2026-07-05
x 2026-06-30 2026-06-29 Support changelog fragments +kacl
```

Leading `(A)` is priority; `x` marks completion with a completion date. It is
excellent prior art for **metadata syntax** and pairs naturally with a
file-in-git workflow, but it offers no Markdown sections or human narrative.

## TaskPaper

[TaskPaper](https://www.taskpaper.com/) began as a Mac app, but the format has
escaped the application. It models projects, tasks, notes, and `@tags` in plain
text, pitched as "future proof" and editable anywhere:

```text
Keepachangelog Manager:
    - Support TASK.md @today
    - Flow completed tasks into CHANGELOG.md @release
    Notes about design here.
```

Good prior art for **lightweight hierarchy and tagging**. Less GitHub-native than
GFM checkboxes, since GitHub will not render it specially.

## Org-mode

[Org-mode](https://orgmode.org/features.html) is the heavyweight ancestor of
plain-text task and project management. It supports TODO keywords, priorities,
deadlines, scheduled tasks, tags, time clocking, agenda views, and multi-file
projects:

```org
* TODO Support TASK.md
  DEADLINE: <2026-07-05>
  :PROPERTIES:
  :TYPE: feature
  :END:
```

It is the richest of the three for **state machines and structured metadata** —
the `:PROPERTIES:` drawer, for instance, maps cleanly onto change types you might
later want in a changelog. The cost is ecosystem lock-in: it is most comfortable
inside Emacs, so casual non-Emacs contributors will not edit it naturally.

## How they compare

| Format | Strength | Weakness for repos |
|---|---|---|
| todo.txt | Compact, portable metadata syntax | No sections or narrative |
| TaskPaper | Simple hierarchy + tags | Not rendered by forges |
| Org-mode | Deadlines, properties, state machine | Emacs-centric in practice |

## Relevance here

These formats matter as **design vocabulary**. If the goal is promoting completed
tasks into [Keep a Changelog]({filename}keep-a-changelog.md) entries, their
metadata conventions (todo.txt priorities, Org `:TYPE:` properties, completion
dates) are exactly the fields a bridge tool needs to sort a finished task into the
right changelog category. For that bridge, see
[From Task Fragments to Changelog]({filename}task-fragments-to-changelog.md); for
the more common Markdown-native approach, see
[TODO.md and GFM Task Lists]({filename}todo-md-gfm-task-lists.md).
