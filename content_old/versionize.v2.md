Title: versionize (hands-on synthesis)
Slug: versionize-v2
Date: 2026-06-02
Ecosystem: Dotnet
Tool_Version: 2.5.0
Experiment: examples/dotnet/versionize/
Summary: Hands-on re-review after driving versionize through the tip-calculator life cycle.


## What I actually ran

The experiment lives at `examples/dotnet/versionize/`. The container is based on
`mcr.microsoft.com/dotnet/sdk:8.0` with `versionize 2.5.0` installed as a global
dotnet tool (`dotnet tool install -g versionize --version 2.5.0`).

The life cycle followed four stages inside an isolated git repo in the container (`/work/app`):

1. **Stage 1 — no changelog:** committed v1 tip-calculator code, manually tagged `v1.0.0`.
2. **Stage 2 — changelog created:** added a `fix:` commit, ran `versionize` — it bumped
   to 1.0.1, wrote `CHANGELOG.md`, auto-committed and auto-tagged `v1.0.1`.
3. **Stage 3 — feature update:** replaced `Program.cs` with the even-split v2 code,
   committed with `feat: split the bill evenly among diners`.
4. **Stage 4a — minor release:** ran `versionize`, which bumped 1.0.1 → 1.1.0, appended
   the new section to `CHANGELOG.md`, committed and tagged `v1.1.0`.
5. **Stage 4b — breaking release:** replaced `Program.cs` with the weighted-split v3
   code, committed with `feat!: split the bill unevenly by weight`, ran `versionize` →
   2.0.0 with a `### Breaking Changes` section.
6. **Bonus — dry-run:** added a final `fix:` commit and ran `versionize --dry-run`,
   which printed the proposed 2.0.1 changelog section to stdout without writing or
   committing anything.

One pre-flight fix was required: the spec listed `--no-verify` as a valid flag, but
versionize 2.5.0 does not support it. The flag was simply dropped.

---

## Real output

### After Stage 2 (first versionize run, bumps 1.0.0 → 1.0.1)

```
Discovered 1 versionable projects
  * /work/app/TipCalc.csproj
√ bumping version from 1.0.0 to 1.0.1 in projects
√ updated CHANGELOG.md
√ committed changes in projects and /work/app/CHANGELOG.md
√ tagged release as v1.0.1 against commit with sha 6ad3a1c...
```

```markdown
# Change Log

All notable changes to this project will be documented in this file. See [versionize](https://github.com/versionize/versionize) for commit guidelines.

<a name="1.0.1"></a>
## 1.0.1 (2026-06-02)

### Bug Fixes

* remove trailing whitespace in output
```

### After Stage 4a (feat → 1.1.0)

```markdown
<a name="1.1.0"></a>
## 1.1.0 (2026-06-02)

### Features

* split the bill evenly among diners
```

### After Stage 4b (feat! → 2.0.0)

```markdown
<a name="2.0.0"></a>
## 2.0.0 (2026-06-02)

### Features

* split the bill unevenly by weight

### Breaking Changes

* split the bill unevenly by weight
```

### Dry-run output

```
√ bumping version from 2.0.0 to 2.0.1 in projects

---
<a name="2.0.1"></a>
## 2.0.1 (2026-06-02)

### Bug Fixes

* add end-of-file comment
---

√ updated CHANGELOG.md
```

### Final git history in container

```
d46812c (HEAD -> master) fix: add end-of-file comment
55a53a4 (tag: v2.0.0) chore(release): 2.0.0
f77cc2d feat!: split the bill unevenly by weight
8b396e9 (tag: v1.1.0) chore(release): 1.1.0
247b6c3 feat: split the bill evenly among diners
6ad3a1c (tag: v1.0.1) chore(release): 1.0.1
51cba87 fix: remove trailing whitespace in output
075a8e9 (tag: v1.0.0) feat: compute tip for a single bill
```

---

## Pros (observed)

- **Zero configuration required.** `versionize` ran against a plain `.csproj` with a
  `<Version>` element and a git repo with Conventional Commits — no config file needed.
- **Accurate SemVer logic.** `fix:` → patch, `feat:` → minor, `feat!:` → major. All
  three were correct without any tuning.
- **One command does everything.** A single `versionize` call bumped the version in the
  `.csproj`, prepended the new section to `CHANGELOG.md`, created a release commit
  (`chore(release): X.Y.Z`), and created the git tag — no separate steps.
- **Dry-run is genuinely useful.** `versionize --dry-run` printed the proposed changelog
  section to stdout and exited cleanly without touching any file or creating a commit.
  Good for CI preview jobs.
- **Clear terminal output.** The checkmark-prefixed lines (`√ bumping version …`,
  `√ tagged release as …`) make it obvious what happened at each step without noise.
- **Discovers all projects.** The "Discovered 1 versionable projects" line suggests the
  tool scans for `.csproj` files, which would handle multi-project solutions without
  extra flags.

---

## Cons / pain points (observed)

- **`--no-verify` does not exist.** The tool's docs list several flags, but
  `--no-verify` (common in other git-adjacent tools to skip hooks) is absent. If a
  project uses commit hooks, there is no built-in bypass. The workaround is to set
  `git config commit.gpgsign false` or configure hooks to allow the release commit.
- **Breaking-change entries are duplicated.** A `feat!:` commit appears under both
  `### Features` and `### Breaking Changes`. Downstream readers see the same line twice,
  which is noisy and arguably wrong: a breaking feature should appear only under
  `### Breaking Changes`.
- **HTML `<a name="…">` anchors instead of pure Markdown.** The changelog uses inline
  HTML anchors (`<a name="2.0.0"></a>`) rather than standard Markdown heading IDs. This
  works in most renderers but breaks strict Markdown linters and looks cluttered in raw
  form.
- **Changelog format is not Keep a Changelog-compliant.** The header style (`## 2.0.0
  (2026-06-02)`) and section names (`### Bug Fixes`, `### Breaking Changes`) differ from
  the canonical Keep a Changelog format (`## [2.0.0] - 2026-06-02` with `### Fixed`).
  The original article described the output as "Keep a Changelog-like shape" — that
  qualifier is doing a lot of work.
- **Requires commits after the most recent tag.** If the working tree is clean and HEAD
  is already tagged, versionize has nothing to process. You must have at least one
  `fix:`, `feat:`, or `feat!:` commit since the last tag before calling it.
- **No `--changelog-all` support in 2.5.0.** The spec mentioned `--changelog-all` as a
  known flag, but `versionize --help` in 2.5.0 does not list it. Commits of types
  outside `fix`, `feat`, and breaking changes (e.g. `chore:`, `docs:`, `refactor:`)
  do not appear in the changelog by default, and there is no flag in this version to
  include them.

---

## Docs vs. reality

The original `versionize.md` article described the output format as
"Keep a Changelog-like shape" and gave an example using `## [2.5.0] - 2026-02-01`
with a `### Bug Fixes` section. The actual output uses `## 2.5.0 (2026-06-02)` (no
brackets, different date separator) and HTML anchors. The article's example was
hand-written and never reflected real tool output — a mild oversell.

The claim that breaking changes trigger a major bump was confirmed exactly.

The claim about minimal configuration (`versionize --dry-run` / `versionize`) was
accurate: zero config files are needed for a single-project repo.

The `--no-verify` flag mentioned in the spec's tool-facts section does not exist in
the tool itself, which is a documentation error in the spec rather than in the original
article.

The original verdict ("Recommended — use `versionize` when a .NET project follows
Conventional Commits and needs automatic version bumps plus `CHANGELOG.md`") is
supported by the run. The tool does exactly what it says.

---

## Revised verdict

**Verdict: Recommended (with caveats — unchanged from original)**

The run confirmed the core promise: point `versionize` at a `.NET` project with
Conventional Commits and it handles the full release loop (version bump, changelog,
commit, tag) in one command with no configuration file. That is genuinely useful.

The two most notable friction points are the `feat!:` duplication in the changelog and
the non-standard HTML anchors. Neither is a blocker, but teams that care about
changelog quality will likely post-process the output or patch it manually.

The original verdict stands. `versionize` occupies a well-defined niche — automated
SemVer + changelog for .NET — and does it reliably. Teams wanting packaging, GitHub
Releases, or NuGet publishing should combine it with `dotnet-releaser` or a CI
workflow.
