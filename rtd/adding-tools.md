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

Then run:

```bash
just build
just quality
```
