Title: conventional-changelog-cli
Date: 2026-06-02
Slug: conventional-changelog-cli
Ecosystem: Node
Tags: node, npm-cli, conventional-commits, changelog-file, release-notes, cli, hands-on
Tool_URL: https://www.npmjs.com/package/conventional-changelog-cli
Tool_Version: 5.0.0
Tool_Status: deprecated
Experiment: examples/node/conventional-changelog-cli/
Summary: Command-line wrapper around the conventional-changelog engine for scriptable changelog generation; hands-on testing found the core append workflow works but the package is deprecated and silently drops content on breaking-change commits.



A reproducible hands-on experiment for this tool lives in [`examples/node/conventional-changelog-cli/`](https://github.com/matthewdeanmartin/the_changelog_ecosystem/tree/main/examples/node/conventional-changelog-cli).

<div style="background:#fff8c4;border:1px solid #e0c000;padding:1em;border-radius:4px;margin:1em 0;">
<strong>⚠️ Heads-up:</strong> In our hands-on testing (see the linked experiment), this package prints a deprecation warning at install time and silently dropped the body of a breaking-change (<code>feat!:</code>) commit — producing a structurally broken CHANGELOG with no error and exit code 0. It is not unusable for plain <code>feat:</code>/<code>fix:</code> commits, but it is a dead end for new projects and you should validate output after any breaking-change commit (or fork/replace it). See the hands-on findings below.
</div>

## Overview

`conventional-changelog-cli` is the direct command-line wrapper around the conventional-changelog ecosystem. It gives projects a small executable for generating or appending changelog text without adopting a full release manager.

It is best for npm scripts and one-off generation. If you need version bumping, tagging, and publishing, use a higher-level tool.

## Installation

```bash
npm install --save-dev conventional-changelog-cli
```

Note: as of v5.0.0 this prints `npm warn deprecated conventional-changelog-cli@5.0.0: This package is no longer maintained. Please use the conventional-changelog package instead.`

## What It Does

- Generates changelog text from Conventional Commits.
- Writes to stdout or updates `CHANGELOG.md`.
- Supports presets such as Angular and conventionalcommits.
- Can append only the latest release section, or preview an unreleased block with `-u`.
- Can be used in npm scripts, CI jobs, or release hooks.

## Configuration

Most projects configure it as a script:

```json
{
  "scripts": {
    "changelog": "conventional-changelog -p conventionalcommits -i CHANGELOG.md -s"
  }
}
```

First-run setup is very low when commit messages already follow a recognized preset. A `repository.url` field in `package.json` is effectively mandatory for usable output — without it, commit links are dropped and the release-header URL is broken. The tool does not detect the URL from the git remote.

## Output Quality

Output mirrors the underlying conventional-changelog writer and groups commits as "Features" / "Bug Fixes" under the angular preset. It is predictable for plain `feat:`/`fix:` commits — but see the hands-on section for a serious caveat around breaking-change commits, where the experiment observed silent content loss.

## Ecosystem Fit

This is a very Node-native utility: install it as a dev dependency and call it from `npm run changelog`. It is a component, not a release workflow.

Use it when you want the conventional-changelog engine without version bumping or publishing — though given the deprecation, calling the underlying `conventional-changelog` library directly is the better long-term path.

## Maintenance Status

- Latest version tested: **5.0.0**
- Tool status in this survey: **deprecated** — npm prints a deprecation notice at install time, and the maintainers have consolidated tooling into the `conventional-changelog` monorepo.
- Repository: <a href="https://github.com/conventional-changelog/conventional-changelog" target="_blank" rel="noopener noreferrer">https://github.com/conventional-changelog/conventional-changelog</a>

This CLI received a final 5.0.0 release but is no longer being developed.

---

## Hands-On Findings

This section is grounded in actually running `conventional-changelog-cli@5.0.0`, not reading its docs.

### What I actually ran

- **Base image:** node:20-slim (Debian bookworm)
- **Tool version:** 5.0.0, installed globally
- **Scenario:** a four-stage Node.js tip-calculator life cycle inside Docker, all git activity contained in the container

The four stages:

1. **v1.0.0 baseline** — initial commit tagged `v1.0.0`, no changelog yet.
2. **Full-history generation** — `conventional-changelog -p angular -i CHANGELOG.md -s -r 0` wrote a complete CHANGELOG covering all history.
3. **Unreleased preview** — after a new feature commit, `conventional-changelog -p angular -u` previewed the pending release block to stdout without touching the file.
4. **Incremental releases** — `conventional-changelog -p angular -i CHANGELOG.md -s` (without `-r 0`) prepended only the new release block, for v2.0.0 and then a v3.0.0 breaking change.

### Real output

The final CHANGELOG.md after all releases — note the malformed, content-less v3.0.0 block:

```markdown
# [3.0.0](https://github.com/example/tipcalc/compare/v2.0.0...v3.0.0) (2026-06-02)
# [2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)


### Features

* split the bill evenly among diners ([5aac67e](https://github.com/example/tipcalc/commit/5aac67e0c22c97d00385335867c41fb1de472da2))

# [1.0.0](https://github.com/example/tipcalc/compare/12ea504fb1898ff97805ad9724ea3f409daa3d5a...v1.0.0) (2026-06-02)


### Features

* compute tip for a single bill ([12ea504](https://github.com/example/tipcalc/commit/12ea504fb1898ff97805ad9724ea3f409daa3d5a))
```

The v3.0.0 heading has no body and runs directly into the v2.0.0 heading with no blank line — invalid markdown. The breaking-change commit's content was dropped entirely.

### Pros (observed)

**Zero-config startup.** No `.versionrc`, no config JS, nothing beyond a `repository.url` field. A single command generated a complete changelog from scratch.

**Incremental append works reliably.** The `-i CHANGELOG.md -s` flags correctly prepend the newest release block and leave existing history untouched across multiple releases. This is the core workflow and it held up for `feat:`/`fix:` commits.

**Unreleased preview is usable.** The `-u` flag — which some older docs suggest may be absent or unstable — worked in v5.0.0, emitting the candidate release block to stdout without modifying the file. Useful for CI diff checks or human review before tagging.

**Automatic commit links.** Short SHAs are hyperlinked to GitHub compare/commit URLs drawn from `package.json`'s `repository.url`.

**`vX.Y.Z` tag format recognized out of the box** by the angular preset, no extra regex.

### Cons / pain points (observed)

**The `feat!:` breaking-change shorthand silently drops its content.** Commit `feat!: split the bill unevenly by weight` triggered v3.0.0 generation but the "Features" list under that heading was empty, and the v3.0.0/v2.0.0 headers ran together with no blank line — invalid markdown. No error, no warning, exit code 0. The `!` indicator is not reliably supported in the angular preset at this version; a `BREAKING CHANGE:` footer in the commit body is likely required instead.

**Silent data loss with no diagnostic.** The tool produced a structurally broken entry and exited cleanly. In a release pipeline this would silently publish a changelog with a missing release body.

**The package is deprecated** (see install warning above). A dead end for new projects.

**`chore(release):` commits are suppressed without explanation.** Correct behavior, but non-obvious to newcomers wondering where their release commits went.

**`repository.url` is mandatory for usable output.** Missing it drops commit links and breaks the release-header URL; the tool makes no attempt to read the git remote.

### Docs vs. reality

The v1 article described the tool as "actively maintained as part of the conventional-changelog package family" and gave a **Situational** verdict. Both need updating:

- **Maintenance:** the package is deprecated at install time, not actively maintained. The recommended path is the underlying `conventional-changelog` library, or a higher-level tool like `release-please` or `semantic-release`.
- **Output quality:** the v1 article called output "useful and predictable." Hands-on testing found a silent content-drop bug on breaking-change commits that undermines "predictable."
- **The `-u` flag:** unmentioned in v1; it works and is genuinely useful.
- **Configuration burden:** v1 correctly noted low setup friction; the zero-config experience for simple `feat:`/`fix:` commits is real.

## Verdict

**Verdict: Do not start here (works, but deprecated and buggy on breaking changes)**

`conventional-changelog-cli` does one thing well: it generates a reasonably formatted CHANGELOG.md from conventional commits with almost no configuration, and the incremental append model works. For a project already using it and not hitting breaking-change commits, there is no urgent reason to migrate.

But the deprecation notice and the silent breaking-change data-loss bug are disqualifying for new adoption. Any project evaluating changelog tooling in 2026 should reach for `release-please`, `semantic-release`, or at minimum the upstream `conventional-changelog` library directly. If the npm-script simplicity is the draw, a shell alias around the underlying library avoids the deprecated CLI layer. If you must keep using this tool, you would effectively be maintaining a dead end — test your changelog output after any `feat!:` or `BREAKING CHANGE:` commit before tagging and publishing.
