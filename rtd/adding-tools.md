# Adding Tools

## Add the Curated Entry

Add or update the tool in `top_prio_tools.toml`:

```toml
[tools.my-tool-slug]
name = "my-tool"
ecosystem = "python"
distribution = "pypi"
package_id = "my-tool"
repo = "https://github.com/owner/my-tool"
description = "One-line description."
priority = "important"
capabilities = [
  "changelog-file",
  "conventional-commits",
]
```

Use existing entries as the source of truth for allowed ecosystems,
distributions, priority values, and capability names.

## Refresh Metadata

Fetch live metadata:

```bash
just gather
```

For a smaller update:

```bash
just gather-one git-cliff
just gather-eco python
```

## Generate Pages and Stubs

Regenerate public pages:

```bash
just generate-pages
```

Create any missing review stubs:

```bash
just stubs
```

The normal stub command skips existing articles. Use `just stubs-force` only when
you intentionally want to overwrite stubs.

## Write the Review

Edit the matching file in `content/articles/`. Replace TODO markers with real
prose, including configuration notes, output examples, ecosystem fit, and a
clear verdict.

## Record the Rating

Add a row to `data/tool_ratings.csv` derived from the article's verdict:

```
tool_name,slug,rating,recommendable,verdict_summary
```

`recommendable` is `yes`, `no`, or `unknown`. Use `no` for any tool you would steer a
new project away from (Avoid, deprecated, unmaintained, legacy-only, internal-only).

A `recommendable: no` tool stays in its ecosystem tool list and in `tools.md`, but must
**not** be linked or named from any overview / "see also" / recommender page (decision
chart, decision helper, topic pages, "Core/Related Articles" lists). See
`CONTRIBUTING.md` ("Recommendable tools and overview pages") for the full rule.

Then run:

```bash
just build
just quality
```
