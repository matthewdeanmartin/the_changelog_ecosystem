# Quality Gates

The project has Python gates, Node gates, link checks, and GitHub Actions hygiene
checks.

## Routine Local Gate

Run:

```bash
just quality
```

This performs a full page generation and build, then checks generated Pelican
artifacts, internal links, HTML validity, browser support, and accessibility.

## Python Gates

Run:

```bash
just quality-python
```

This builds the site, validates generated Pelican artifacts, and checks internal
links.

Run the external link audit when network access is available:

```bash
just quality-links
```

External link checks can fail because a registry, documentation host, or project
site is temporarily unavailable. Treat failures as review items, not automatic
content rewrites.

## Node Gates

Run:

```bash
just quality-node
```

This runs the `npm run quality` suite:

- `html-validate` for generated HTML.
- `doiuse`-based browser support checks.
- `pa11y` accessibility checks.

## GitHub Actions Hygiene

Run:

```bash
make gha-validate
```

This parses workflow YAML and runs `zizmor` against the repository.

Run:

```bash
make gha-upgrade
```

This updates GitHub Actions pins with `gha-update`, then validates the workflows
again. Review the resulting workflow diff before committing.
