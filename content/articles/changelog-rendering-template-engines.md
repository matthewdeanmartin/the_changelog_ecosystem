Title: Changelog Rendering and Template Engines
Date: 2026-06-02
Slug: changelog-rendering-template-engines
Ecosystem: Cross
Tags: templates, rendering, markdown, release-notes
Tool_Status: research
Summary: A comparison of the template languages changelog tools use to render release notes — Tera/Jinja2, Handlebars, Go text/template, and built-in renderers — focusing on what each makes easy or difficult.

## Overview

Most changelog tools separate data (commits, fragments, parsed entries) from presentation (the rendered Markdown or RST that readers see). The presentation layer is where template engines live. The choice of engine determines how much the output can be customized, how readable that customization is, and what happens when the default output is not quite right.

This article covers the four template families in active use: Tera/Jinja2, Handlebars, Go `text/template`, and built-in renderers with no user-facing template language. It focuses on changelog and release-note rendering specifically — not general documentation theming.

## The Four Template Families

### 1. Tera / Jinja2

**Used by:** git-cliff (Tera in Rust), Towncrier (Jinja2 in Python), python-semantic-release (Jinja2)

[Tera](https://keats.github.io/tera/) is a Jinja2 port written in Rust, with nearly identical syntax. Both use `{{ variable }}` for interpolation and `{% for %}` / `{% if %}` for control flow.

**git-cliff** renders three separate template strings — `header`, `body`, and `footer` — configured in `cliff.toml`. The body is rendered once per release:

```toml
[changelog]
header = "# Changelog\n\n"
body = """
{% if version %}
## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{% else %}
## [Unreleased]
{% endif %}
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {% if commit.breaking %}[**breaking**] {% endif %}{{ commit.message | upper_first }}\
{% endfor %}
{% endfor %}
"""
footer = ""
```

The template context for each release contains: `version`, `timestamp`, `previous`, `commits` (a list of commit objects), and `releases` (in header/footer). Commit objects expose `message`, `group`, `breaking`, `scope`, `id`, `author`, and custom `extra` fields from the config.

Tera filters (`trim_start_matches`, `date`, `upper_first`, `group_by`) drive most of the formatting work. Custom filters cannot be added without forking the binary, but the built-in set covers most changelog patterns.

**Towncrier** uses a single Jinja2 template, defaulting to either `towncrier:default.rst` or `towncrier:default.md` depending on whether the output filename ends in `.md`. A custom template is specified with `template = "path/to/template.jinja2"` in the config. The context object contains `sections` (fragment types), `versiondata` (version string, date), and `top_line` (the assembled first line).

```jinja
{% for section, _ in sections.items() %}
{% set underline = "#" %}
{% if sections[section] %}
### {{ sections[section] }}

{% for category, val in sections[section].items() %}
- {{ val }}
{% endfor %}
{% endif %}
{% endfor %}
```

**What Tera/Jinja2 makes easy:** Grouping, filtering, conditional sections, date formatting, multi-line output. String filters eliminate most shell post-processing. The familiar Python-adjacent syntax lowers the learning curve for Python projects.

**What it makes difficult:** Debugging template errors returns terse messages without line numbers. Generating non-Markdown output (e.g. AsciiDoc) requires fighting the default filters. Tera does not support custom functions without modifying the host binary.

---

### 2. Handlebars

**Used by:** conventional-changelog ecosystem (semantic-release, release-it with @release-it/conventional-changelog), auto-changelog, release-drafter templates (partial)

The `conventional-changelog-writer` package sits at the center of the Node.js ecosystem. It takes a stream of parsed commits and renders them through a set of Handlebars templates. The templates are split into partials: `template.hbs` (the wrapper), `commit.hbs` (per-commit line), `footer.hbs` (links and contributors).

A minimal customization replaces just the commit partial:

```handlebars
{{#each commitGroups}}
### {{title}}
{{#each commits}}
- {{#if this.scope}}**{{this.scope}}:** {{/if}}{{this.subject}}{{#if this.references}} {{#each this.references}}([{{this.issue}}]({{this.url}})){{/each}}{{/if}}
{{/each}}
{{/each}}
```

The context object passed to the template includes: `version`, `title`, `date`, `isPatch`, `commitGroups` (grouped by type), `noteGroups` (BREAKING CHANGE notes), `revertedCommits`, `mentions`, and `repository` URL.

**semantic-release** delegates rendering to `@semantic-release/release-notes-generator`, which in turn delegates to `conventional-changelog`. Customization happens through `writerOpts` in the plugin config:

```json
{
  "plugins": [
    ["@semantic-release/release-notes-generator", {
      "preset": "conventionalcommits",
      "writerOpts": {
        "commitPartial": "* {{#if scope}}**{{scope}}:** {{/if}}{{subject}} ([{{hash}}]({{@root.host}}/{{@root.owner}}/{{@root.repository}}/commit/{{hash}}))\n"
      }
    }]
  ]
}
```

**What Handlebars makes easy:** Per-commit line customization, iterating commit groups and note groups, conditional rendering for patch vs minor vs major releases. The partial system is clean for incremental overrides — replace just one partial rather than the whole template.

**What it makes difficult:** The context object is large and only partially documented; discovering available variables requires reading the `conventional-changelog-writer` source. Handlebars has no built-in date formatting; it must be registered as a helper. Debugging requires adding `console.log` to a custom helper because template error messages are minimal.

---

### 3. Go `text/template`

**Used by:** Changie, GoReleaser (chglog library), git-chglog

Go's built-in `text/template` package is the de-facto standard for Go CLI tools. It uses `{{ .Field }}` for access and `{{ range }}` / `{{ if }}` for control flow.

**Changie** uses Go templates throughout its config: `versionFormat`, `kindFormat`, `changeFormat`, `headerFormat`, and `footerFormat` are all template strings. The template context for a change entry exposes `.Kind`, `.Body`, `.Time`, and `.Custom` (custom fields):

```yaml
versionFormat: '## {{.Version}} - {{.Time.Format "2006-01-02"}}'
kindFormat: '### {{.Kind}}'
changeFormat: '- {{.Body}}'
```

Date formatting uses Go's reference-time convention: the literal string `2006-01-02` means ISO date, not a format pattern. This is Go-idiomatic but surprising for developers from other language backgrounds — writing `YYYY-MM-DD` produces literal output, not a date.

**git-chglog** uses `.chglog/config.yml` to configure a Go template style and separate `.chglog/CHANGELOG.tpl.md`:

```go
{{ range .Versions }}
## {{ if .Tag.Previous }}[{{ .Tag.Name }}]{{ else }}{{ .Tag.Name }}{{ end }}
{{ range .CommitGroups }}
### {{ .Title }}
{{ range .Commits }}
- {{ if .Scope }}**{{ .Scope }}:** {{ end }}{{ .Subject }}
{{ end }}{{ end }}{{ end }}
```

The template context includes `.Versions` (list of version objects), each with `.Tag`, `.CommitGroups`, `.MergeCommits`, `.RevertCommits`, and `.NoteGroups`.

**What Go templates make easy:** Zero-dependency rendering, straightforward field access, clean range loops. Works on any platform that can run the binary.

**What they make difficult:** No built-in string filters — `upper_first`, `trim`, regex replacement all require custom template functions registered in the host binary. The date reference-time convention is a recurring footgun. Error messages point to template line numbers but don't show the surrounding context.

---

### 4. Built-in Renderers (No User-Facing Template Language)

**Used by:** Towncrier (default output), Reno, release-please, GitHub auto-notes, Scriv

Several tools do not expose a template language at all — rendering is handled by Python or JavaScript code, and the user configures the output through structured settings rather than template strings.

**Reno** renders RST by iterating over the YAML sections in note files and producing RST headings and bullet lists. There is no template file to edit; section names, RST heading underline characters, and branch scanning all come from `reno.yaml` keys. The output shape is fixed: a nested RST document grouped by version, then by section.

**release-please** renders changelog entries directly in TypeScript. The section mapping (which Conventional Commit type goes to which heading) is configured in `release-please-config.json` via `changelog-sections`:

```json
{
  "changelog-sections": [
    { "type": "feat",  "section": "Features" },
    { "type": "fix",   "section": "Bug Fixes" },
    { "type": "chore", "section": "Chores", "hidden": false }
  ]
}
```

That covers section visibility and naming, but not the line format for individual entries. The entry format is hardcoded.

**Scriv** copies fragment headings and bullet lists verbatim into the changelog. There is no separate rendering step: fragments are Markdown, the changelog is Markdown, `collect` concatenates them with version headings. Customization is in the fragment itself.

**What built-in renderers make easy:** Zero configuration for the common case; no template syntax to learn. Output is consistent and predictable.

**What they make difficult:** Any output shape not anticipated by the tool is impossible without patching the source. Adding a contributors list, an emoji prefix, a comparison link in a non-standard format, or a section that doesn't exist in the taxonomy requires either post-processing or a different tool.

## Comparison Table

| Tool | Engine | Template location | Output format | Custom filters/helpers |
|---|---|---|---|---|
| git-cliff | Tera (Jinja2-like) | `cliff.toml` inline or `--template` | Markdown (any) | No |
| Towncrier | Jinja2 | `template =` in config | RST or Markdown | No |
| python-semantic-release | Jinja2 | `changelog_templates/` directory | Markdown | No |
| semantic-release | Handlebars | `writerOpts.commitPartial` etc. | Markdown | Via JS helper |
| release-it | Handlebars | Via `@release-it/conventional-changelog` | Markdown | Via JS helper |
| Changie | Go `text/template` | Inline in `.changie.yaml` | Markdown | No |
| git-chglog | Go `text/template` | `.chglog/CHANGELOG.tpl.md` | Markdown | No |
| GoReleaser | Go `text/template` | Inline or via chglog | Markdown | No |
| Reno | Built-in Python | `reno.yaml` section names only | RST | No |
| release-please | Built-in TypeScript | `changelog-sections` in config JSON | Markdown | No |
| Scriv | Built-in (fragment passthrough) | Fragment content | Markdown or RST | No |
| GitHub auto-notes | Built-in | `.github/release.yml` categories | Markdown | No |

## Output Shapes That Each Engine Makes Difficult

| Desired output | Challenge |
|---|---|
| Per-commit author attribution | Requires custom helper or filter; not in Tera built-ins |
| Multi-column tables | Possible in Tera/Jinja2, impossible in Go templates without helper |
| AsciiDoc or HTML output | Go templates produce it; Tera built-in filters assume Markdown |
| Emoji prefix on section headings | Trivial in all template engines; hard in built-in renderers |
| Conditional entry inclusion (e.g. hide deps) | Easy in Tera/Jinja2 with `reject`; Handlebars needs helper; Go `if` works |
| Contributors section | Requires context variable; Handlebars (`conventional-changelog`) has it; others do not |
| Linked issue numbers when the issue tracker is not GitHub | Requires custom template in all engines |

## Choosing a Template Engine

If the project already uses **git-cliff**, Tera is the path of least resistance. The built-in filter set covers most changelog patterns and the inline config keeps everything in one file.

If the project is **Node-based and uses Conventional Commits**, the Handlebars layer in `conventional-changelog-writer` is well-worn and widely understood. The partial-override pattern (replace only `commit.hbs`) is the right approach for incremental customization.

If the project is **Go-based or wants a static binary**, Go `text/template` via Changie or git-chglog is idiomatic. Expect to encode date formatting and string manipulation into the template rather than calling filters.

If the team wants **no template language at all** — consistent, zero-config output — Reno, release-please, or Scriv deliver that at the cost of fixed output shapes.

## Related Articles

- [git-cliff]({filename}git-cliff.md)
- [towncrier]({filename}towncrier.md)
- [changie]({filename}changie.md)
- [semantic-release]({filename}semantic-release.md)
- [release-it]({filename}release-it.md)
- [reno]({filename}reno.md)
- [Changelog File Schemas]({filename}changelog-file-schemas.md)
- [Change Taxonomies Across Tools]({filename}change-taxonomies-across-tools.md)
