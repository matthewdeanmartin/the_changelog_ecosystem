# Publishing

The public site publishes to GitHub Pages through `.github/workflows/deploy-pages.yml`.

The workflow runs on pushes to `main` when site, data, theme, script, dependency,
or workflow files change. It can also be run manually from the GitHub Actions UI.

## What the Workflow Does

The Pages workflow:

1. Checks out the repository without persisted credentials.
2. Installs pinned Python and Node toolchains.
3. Runs `uv sync --locked`.
4. Runs `npm ci`.
5. Builds the production Pelican site with `publishconf.py`.
6. Runs Python and Node quality gates.
7. Uploads `output/` as the GitHub Pages artifact.
8. Deploys through the official GitHub Pages deployment action.

## Before Publishing

Run the local gate:

```bash
just quality
```

Validate workflow hygiene:

```bash
make gha-validate
```

## Updating Action Pins

When GitHub Actions release new versions, run:

```bash
make gha-upgrade
```

This uses `gha-update` to move action references to current commit SHAs and then
runs `zizmor`. Review the diff carefully before committing.
