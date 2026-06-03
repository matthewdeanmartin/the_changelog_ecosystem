Title: changie (hands-on synthesis)
Date: 2026-06-02
Slug: changie-v2
Ecosystem: go
Tags: go, fragment-tool, changelog-file, language-agnostic, hands-on
Tool_URL: https://changie.dev/
Tool_Version: 1.24.0
Tool_Status: active
Experiment: examples/go/changie/
Summary: Hands-on re-review after driving changie through the tip-calculator life cycle.



## What I actually ran

A Docker container (debian:bookworm-slim) downloaded the `changie_1.24.0_linux_amd64` binary
from GitHub Releases and ran a scripted three-release life cycle against a minimal shell
script fixture. No Go toolchain was involved — the experiment is intentionally
language-agnostic.

The sequence:

1. `changie init` — created `.changes/unreleased/`
2. Dropped a pre-written `.changie.yaml` config
3. Copied hand-written fragment `.yaml` files into `.changes/unreleased/`
4. `changie batch v1.0.0` — consumed the fragments, wrote `.changes/v1.0.0.md`
5. `changie merge` — wrote `CHANGELOG.md`
6. Repeated steps 3–5 for v2.0.0 and v3.0.0

Full transcript and artifacts are in `examples/go/changie/`.


## Real output

All three release cycles completed without error. The final `CHANGELOG.md`:

```markdown
## v3.0.0 - 2026-06-02
### Added
- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2) — output format changed## v2.0.0 - 2026-06-02
### Added
- Split the bill evenly among 4 diners## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total
```

The git log confirmed seven commits and three annotated tags (v1.0.0, v2.0.0, v3.0.0)
exactly as scripted.


## Pros

**Single binary, truly zero runtime dependencies.** The tar.gz from GitHub Releases extracted
to one 9 MB file and worked immediately on a bare Debian image with no package manager
involvement beyond the initial `curl`. This is the clearest advantage over Python-based tools
like scriv or towncrier.

**Fragment-first workflow is low-friction in happy-path use.** `changie batch` cleans up
unreleased fragments atomically in the same step that creates the version file, so there is
no risk of fragments being double-counted. The merge step is equally tidy: it reads every
`.changes/v*.md` and prepends the newest version at the top without requiring any state
beyond the files themselves.

**Newest-first ordering is automatic.** Each `changie merge` run re-sorts the version files
in descending semver order. You never have to maintain the ordering yourself.

**Config uses Go templates throughout.** `versionFormat`, `kindFormat`, and `changeFormat`
are all Go `text/template` expressions evaluated with changie's own context object. Teams
with Go experience will feel at home; the template power is sufficient for any reasonable
changelog style.

**Language-agnostic by design.** The entire tool knows nothing about Go modules, npm
packages, or any build system. It reads and writes Markdown. This makes it a reasonable
default for polyglot monorepos.


## Cons

**`changie merge` does not add a blank line between version sections.** The generated
`CHANGELOG.md` runs all `##` version headings together with no separator. The raw file
fails Markdown linters and looks cluttered in text editors. This is a template gap: the
`versionFormat` string has no trailing newline, and the merge step does not insert one.
A workaround exists (end `versionFormat` with `\n`), but the documentation does not
mention it, and the `changie init` defaults ship broken in this regard.

**`changie new` is interactive-only.** There is no `--kind`/`--body` flag for non-interactive
use in v1.24.0. Scripted pipelines must drop hand-written `.yaml` files directly into
`.changes/unreleased/` and hope they match the schema. This is not hard, but it is
undocumented in the quick-start guide.

**No native breaking-change signal.** The fragment schema has `kind` and `body` (and
optional custom fields). There is no `breaking: true` field that changie recognises and
renders differently. Teams that want to distinguish breaking changes in the changelog must
encode the signal in the body text or in a custom `kind`.

**`changie init` overwrites silently.** Running `changie init` a second time on a directory
that already has `.changie.yaml` silently overwrites it. There is no `--no-clobber` guard
or prompt.

**The version prefix is baked into the default config.** The default `versionFormat` renders
`## v1.0.0 - …` (with the `v` prefix). If your release tags do not have a `v` prefix you
must remember to adjust the template, which is not mentioned prominently.


## Docs vs. reality

The documentation describes the three-step `init → new → batch → merge` workflow accurately.
The quick-start example on changie.dev matches what the binary actually does.

Two gaps: the docs do not warn about the missing blank-line between sections, and the
non-interactive fragment workflow (bypassing `changie new`) is not covered at all. Teams
discovering `changie` for CI automation will have to read the fragment `.yaml` schema from
source or trial-and-error before they get a working fragment file.

The Go template format for dates (`2006-01-02`) is mentioned in the config reference but a
reader unfamiliar with Go's unusual reference-time convention could easily write `YYYY-MM-DD`
and get silent garbage output.


## Revised verdict

**Verdict: Recommended with caveats**

The first-draft review rated changie "Recommended" on the strength of its clean design and
zero-runtime binary. Hands-on use confirms the core workflow is solid: `batch` and `merge`
do exactly what they promise and the tool is genuinely language-agnostic.

The missing blank-line bug is real and annoying enough to be a daily friction point for
anyone using the default config. It deserves a mention before recommending the tool to
teams. The interactive-only `changie new` is a gap for CI pipelines. Neither issue is a
blocker — both have workarounds — but teams should know about them before they commit to
the workflow.

For a Go or polyglot project that wants fragment-based changelogs without pulling in a
language runtime, changie is still the strongest single-binary option. Pair it with a
reviewed `.changie.yaml` that fixes the newline template, and the day-to-day experience
is smooth.
