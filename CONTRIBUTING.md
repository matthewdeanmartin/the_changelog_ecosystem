# Contributing to The Changelog Ecosystem

## Quick start

```bash
uv sync          # install dependencies
just build       # generate pages + build HTML
just devserver   # serve with live reload at http://localhost:8000
```

Run `just` with no arguments to list all available recipes.

---

## Two kinds of files

This repo has a strict separation between **generated** and **hand-written** files.
Understanding this prevents accidental data loss.

### Generated (safe to overwrite via Just recipes)

| File(s) | Generator | Recipe |
|---------|-----------|--------|
| `content/pages/tools.md` | `generate_pages.py` | `just generate-pages` |
| `content/pages/{ecosystem}.md` | `generate_pages.py` | `just generate-pages` |
| `data/tools.json` (metadata fields) | `gather_metadata.py` | `just gather` |

**Do not hand-edit these files.** Changes will be lost the next time the generator runs.
If you want to change what appears on these pages, edit `data/tools.json` or the
generator script itself.

### Hand-written (never overwritten by tools)

| File(s) | Notes |
|---------|-------|
| `content/articles/*.md` | Review stubs and finished reviews |
| `data/top_prio_tools.toml` | Curated tool list with priorities and capabilities |
| `content/pages/home.md` | Site landing page |
| `content/pages/about.md` | About page |
| `themes/` | Theme templates and CSS |

`just stubs` generates an article stub **only if the file does not already exist**.
It will never overwrite a file you have edited. Use `just stubs-force` only when you
want to reset a stub to its machine-generated baseline (destroying any hand prose).

---

## Adding a new tool

1. Add an entry to `data/top_prio_tools.toml` following the existing format.
   Key fields:

   ```toml
   [tools.my-tool-slug]
   name = "my-tool"
   ecosystem = "python"          # python rust go node java ruby dotnet cpp
   distribution = "pypi"         # pypi crates.io npm rubygems nuget maven github
   package_id = "my-tool"        # ID used to query the registry API
   repo = "https://github.com/owner/my-tool"
   description = "One-line description."
   priority = "important"        # must | important | secondary
   capabilities = [
     "changelog-file",
     "conventional-commits",
   ]
   ```

2. Run the data pipeline to pull live metadata:

   ```bash
   just gather
   ```

3. Generate a stub review article:

   ```bash
   just stubs
   ```

4. Fill in the stub at `content/articles/{slug}.md`. Replace every `_TODO_` and
   `<!-- TODO ... -->` marker with real prose. The key sections are:

   - **Overview** — what problem it solves and who it is for
   - **Configuration** — first-run complexity, minimal config example
   - **Output Quality** — paste a real sample output snippet
   - **Ecosystem Fit** — does it feel native? CI/CD story?
   - **Verdict** — `Recommended` / `Situational` / `Avoid` + one paragraph

5. Rebuild the site to check your work:

   ```bash
   just build
   just devserver   # then visit http://localhost:8000
   ```

---

## Updating tool metadata

Metadata (version, last release, stars, archived) is fetched from registries. To refresh:

```bash
just gather            # update all tools
just gather-one git-cliff   # update a single tool
just gather-eco python      # update one ecosystem
```

After gathering, regenerate the pages:

```bash
just generate-pages
just html
```

Or do it all at once:

```bash
just all    # discover + gather + generate-pages + html
```

---

## Tags

Each review article carries a `Tags:` frontmatter field that drives the `/tags/` browse
page and individual tag pages. Tags come from two sources:

1. **Automatically set by `just stubs`** — derived from the tool's `capabilities` list
   in `top_prio_tools.toml`. Common tags:

   | Tag | Meaning |
   |-----|---------|
   | `conventional-commits` | Parses Conventional Commits |
   | `keep-a-changelog` | Targets the Keep a Changelog format |
   | `semantic-versioning` | Automates semver bumping |
   | `news-fragments` | Fragment-assembly workflow (towncrier-style) |
   | `github-integration` | Creates/reads GitHub Releases or PRs |
   | `gitlab-integration` | Creates/reads GitLab Releases |
   | `ci-cd` | Designed for CI/CD pipeline use |
   | `monorepo` | Supports monorepo workflows |
   | `custom-templates` | User-defined output templates |
   | `package-publishing` | Publishes to a registry |
   | Ecosystem name | e.g. `python`, `rust`, `node` |

2. **Hand-edited** — you can add additional tags directly in the article frontmatter.
   Separate tags with commas: `Tags: conventional-commits, rust, custom-templates`.

Tags on existing articles are **not** updated by `just stubs` (the file won't be
overwritten). To refresh tags on stubs you haven't edited yet, you can safely delete
the file and re-run `just stubs`.

---

## Workflow summary

```
# One-time setup
uv sync

# Routine data refresh
just gather
just generate-pages

# Writing a new review
just stubs          # create stub if it doesn't exist
$EDITOR content/articles/my-tool.md
just build
just devserver

# Full pipeline from scratch
just all
```
