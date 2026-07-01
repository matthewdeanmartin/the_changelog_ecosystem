Yeah, you’re not alone here. There is a real family of **repo-native / plain-text task tracking** patterns, but it is much less standardized than changelogs. The closest buckets:

## 1. `TODO.md` / `TASKS.md` as a repo convention

The most direct prior art is **TODO.md**: a Markdown file at repo root, usually using GitHub-style checkboxes and headings as columns/statuses. There is even a `todo.md` “standard” project that explicitly says it is based on GitHub Flavored Markdown task lists, organizes tasks into sections/columns, can be visualized as Kanban, and was inspired by Keep a Changelog. ([GitHub][1])

Typical shape:

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

There is also another `TODO.md` spec/project describing “multi project task management using standardized TODO.md markdown files,” aimed at teams/individuals managing todos “the git-way.” ([GitHub][2])

So: **TODO.md is probably the name of the pattern you’re orbiting.** `TASK.md` / `TASKS.md` is a reasonable variant, but `TODO.md` has more discoverable prior art.

## 2. GitHub Flavored Markdown task lists

The underlying mini-standard is **GFM task list items**:

```md
- [ ] not done
- [x] done
```

GitHub added task lists for issues/PRs/comments in 2013, then added read-only task lists in all Markdown documents in repositories and wikis in 2014. ([The GitHub Blog][3]) ([The GitHub Blog][4]) The GFM spec formalizes “task list items” as an extension to Markdown. ([github.github.com][5])

This matters because a repo-level `TODO.md` or `TASKS.md` can be rendered nicely on GitHub/GitLab without your tool existing.

## 3. `todo.txt`

Different vibe, older and more portable. **todo.txt** is a plaintext task format designed around one line per task, with priority, projects, contexts, dates, etc. It is not specifically repo-focused, but it is extremely compatible with “file in git” workflows. The official site describes it as task tracking in a `todo.txt` file you control, software/OS agnostic, searchable, and portable. ([todotxt.org][6])

Example-ish:

```txt
(A) 2026-07-01 Add TASKS.md parser +kacl @repo due:2026-07-05
x 2026-06-30 2026-06-29 Support changelog fragments +kacl
```

Good prior art for metadata syntax. Less good if you want Markdown sections and human narrative.

## 4. TaskPaper

**TaskPaper** is another plaintext task format, originally Mac-oriented, but the format has escaped the app. It models projects, tasks, notes, and tags in simple text. The product pitches it as “plain text,” “future proof,” editable in any text editor, and compatible with other apps. ([TaskPaper][7])

Example-ish:

```text
Keepachangelog Manager:
    - Support TASK.md @today
    - Flow completed tasks into CHANGELOG.md @release
    Notes about design here.
```

Good prior art for lightweight hierarchy and tags. Less GitHub-native than Markdown checkboxes.

## 5. Org-mode

**Org-mode** is the heavyweight “plain text task/project management” ancestor. It supports TODO keywords, priority, deadlines, scheduled tasks, tags, clocking, agenda views, and multiple files. ([Org Mode][8])

Example:

```org
* TODO Support TASK.md
  DEADLINE: <2026-07-05>
  :PROPERTIES:
  :TYPE: feature
  :END:
```

Great prior art for state machines and metadata. Bad fit if you want non-Emacs users to casually edit it.

## 6. Markdown Kanban / file-backed task board tools

There are a bunch of tools very close to your “repo task file” idea:

| Tool / pattern                   | What it does                                                                                                                                                                           | Why it matters                                                                                               |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **todo-md**                      | CLI task list stored in a simple Markdown file, GFM-compatible, meant to be checked into a repo. ([Hypercubed][9])                                                                     | Direct “todo file in repo” prior art.                                                                        |
| **Coddx / TODO.md Kanban Board** | VS Code task board that saves tasks as `TODO.md`; compatible with GitHub Markdown; portable and commit-able in PRs. ([GitHub][10])                                                     | Very close to “repo TODO as source of truth.”                                                                |
| **Taskell**                      | Command-line Kanban/task manager; per-project task lists; stored using Markdown; clean diffs for version control. ([SourceForge][11])                                                  | Strong prior art for Markdown Kanban in git.                                                                 |
| **Tasks.md**                     | Self-hosted Markdown file-based task board; tasks/cards stored as Markdown files. ([GitHub][12])                                                                                       | More “filesystem as database” than single `TODO.md`.                                                         |
| **Markdown Task Manager**        | Local-first Kanban over Markdown files, no database/server, aimed at developers and AI assistants. ([GitHub][13])                                                                      | Newer “AI-agent-friendly repo tasks” angle.                                                                  |
| **Imdone**                       | Kanban over Markdown and code blocks; cards represented by Markdown blocks in notes/docs/code. ([GitHub][14])                                                                          | Blurs doc TODOs and code TODOs; probably adjacent but partly in the source-code TODO world you’re excluding. |
| **kanban-md**                    | File-based Kanban where each task is a Markdown file with YAML frontmatter; positioned for multi-agent workflows; commit board with code, review task changes in PRs. ([Go Forum][15]) | Extremely close to “task fragments in repo,” especially for agents.                                          |

## 7. Changelog-fragment systems as adjacent prior art

Your changelog-fragment flow also has a strong ancestor family: **Towncrier**, **Scriv**, **reno**, etc. Towncrier’s docs describe generating Markdown changelogs from news fragments, and explicitly say the Markdown setup can be language/platform independent. ([towncrier.readthedocs.io][16])

The analogy is pretty clean:

```text
changelog.d/*.md  -> CHANGELOG.md
tasks.d/*.md      -> TASKS.md / TODO.md / CHANGELOG.md
```

That “fragments get aggregated later” pattern is not super common for tasks, but `kanban-md`/Tasks.md-style “one Markdown file per card” is basically the task-management cousin of changelog fragments.

## My read

The prior art names to search / cite in your docs are:

**Standards / formats:** `TODO.md`, GFM task lists, `todo.txt`, TaskPaper, Org-mode.

**Repo/file-native tools:** todo-md, Coddx TODO.md Kanban Board, Taskell, Tasks.md, Imdone, MarkdownTaskManager, kanban-md.

**Adjacent release-note fragment tools:** Towncrier, Scriv, Reno, changesets.

Your differentiator is probably not “tasks live in repo.” That exists. The more original bit is:

> Completed repo-local tasks and/or task fragments become curated Keep a Changelog entries.

That is a narrower bridge: **task planning → release notes**, with git-reviewable task provenance.

[1]: https://github.com/todomd/todo.md?utm_source=chatgpt.com "TODO.md file format - todomd.org"
[2]: https://github.com/todo-md/todo-md?utm_source=chatgpt.com "TODO.md"
[3]: https://github.blog/news-insights/product-news/task-lists-in-gfm-issues-pulls-comments/?utm_source=chatgpt.com "Task Lists in GFM: Issues/Pulls, Comments"
[4]: https://github.blog/news-insights/product-news/task-lists-in-all-markdown-documents/?utm_source=chatgpt.com "Task lists in all markdown documents"
[5]: https://github.github.com/gfm/?utm_source=chatgpt.com "GitHub Flavored Markdown Spec"
[6]: https://todotxt.org/?utm_source=chatgpt.com "Todo.txt: Future-proof task tracking in a file you control"
[7]: https://www.taskpaper.com/?utm_source=chatgpt.com "TaskPaper – Plain text to-do lists for Mac"
[8]: https://orgmode.org/features.html?utm_source=chatgpt.com "Features"
[9]: https://hypercubed.github.io/todo-md/?utm_source=chatgpt.com "todo-md"
[10]: https://github.com/coddx-hq/coddx-alpha?utm_source=chatgpt.com "Kanban Board manages tasks and save them as TODO.md"
[11]: https://sourceforge.net/projects/taskell.mirror/?utm_source=chatgpt.com "Taskell download | SourceForge.net"
[12]: https://github.com/BaldissaraMatheus/Tasks.md?utm_source=chatgpt.com "BaldissaraMatheus/Tasks.md: A self-hosted, Markdown file ..."
[13]: https://github.com/ioniks/MarkdownTaskManager?utm_source=chatgpt.com "ioniks/MarkdownTaskManager: Local-first Kanban task ..."
[14]: https://github.com/imdone/imdone?utm_source=chatgpt.com "imdone"
[15]: https://forum.golangbridge.org/t/kanban-md-file-based-kanban-cli-tui-for-multi-agent-workflows/41591?utm_source=chatgpt.com "file-based Kanban CLI/TUI for multi-agent workflows - Go Forum"
[16]: https://towncrier.readthedocs.io/en/stable/markdown.html?utm_source=chatgpt.com "How to Keep a Changelog in Markdown - Towncrier"
