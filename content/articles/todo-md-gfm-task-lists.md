Title: TODO.md and GFM Task Lists
Date: 2026-07-01
Slug: todo-md-gfm-task-lists
Ecosystem: Cross
Tags: task-tracking, markdown, github-integration, keep-a-changelog
Tool_Status: research
Summary: The TODO.md repo convention and the GitHub-Flavored Markdown task-list primitive underneath it — how they work, what renders on GitHub, and the tooling that treats a repo TODO file as the source of truth.

## Overview

If repo-native task tracking has a canonical name, it is **`TODO.md`**: a Markdown
file at the repository root that uses headings as status columns and GFM checkboxes
as tasks. The [todo.md standard](https://github.com/todomd/todo.md) makes this
explicit — it is built on GitHub-Flavored Markdown task lists, organizes tasks into
sections that can be read as Kanban columns, and was, by its own account, inspired
by [Keep a Changelog]({filename}keep-a-changelog.md). A separate
[TODO.md project](https://github.com/todo-md/todo-md) frames the same idea as
"multi-project task management using standardized TODO.md files," managed the
git way.

`TASKS.md` is a common variant of the same pattern; `TODO.md` simply has more
discoverable prior art.

## The format

A `TODO.md` is just Markdown. Sections are statuses; list items are tasks;
inline `#tags` carry metadata:

```md
# Project TODO

## Backlog
- [ ] Add JSON export #feature
- [ ] Fix Windows path handling #bug

## In Progress
- [ ] Refactor parser

## Done ✓
- [x] Add tests for fragment loading
```

Because it is ordinary Markdown, it renders on GitHub, GitLab, and in any editor
without special tooling.

## The primitive underneath: GFM task lists

The mini-standard that makes this work is the **GFM task list item**:

```md
- [ ] not done
- [x] done
```

GitHub [added task lists to issues, PRs, and comments in 2013](https://github.blog/news-insights/product-news/task-lists-in-gfm-issues-pulls-comments/),
then [extended read-only task lists to all Markdown documents](https://github.blog/news-insights/product-news/task-lists-in-all-markdown-documents/)
in repositories and wikis in 2014. The
[GFM specification](https://github.github.com/gfm/) formalizes task-list items as
a Markdown extension. The practical consequence: a repo-level `TODO.md` or
`TASKS.md` gets a rendered, checkbox-aware view for free, with no tool of your own
required.

## Tooling

Several tools treat a Markdown task file as the board's source of truth:

- **[todo-md](https://hypercubed.github.io/todo-md/)** — a CLI that stores tasks
  in a GFM-compatible Markdown file meant to be checked into a repo.
- **[Coddx / TODO.md Kanban Board](https://github.com/coddx-hq/coddx-alpha)** — a
  VS Code board that saves tasks as `TODO.md`, commit-able in PRs.
- **[Taskell](https://sourceforge.net/projects/taskell.mirror/)** — a command-line
  Kanban manager that stores per-project lists as Markdown with clean diffs for
  version control.
- **[Imdone](https://github.com/imdone/imdone)** — Kanban over Markdown and code
  blocks; blurs the line between document TODOs and source-code `TODO:` comments.

## Trade-offs

The strength is ubiquity: no adoption cost, renders everywhere, reviews in a PR
like any file. The weakness is exactly the flip side — headings-as-columns and
inline `#tags` are conventions, not a schema, so anything beyond "todo / doing /
done" (due dates, assignees, priorities) has no agreed structure. For richer,
machine-parseable metadata, see [Portable Task Formats]({filename}portable-task-formats.md).

## Relevance here

`TODO.md` matters to this site because it is the most GitHub-native staging ground
for work that will eventually be described in a changelog. When "Done" items are
also the raw material for release notes, the interesting question becomes how they
get promoted — covered in
[From Task Fragments to Changelog]({filename}task-fragments-to-changelog.md).
