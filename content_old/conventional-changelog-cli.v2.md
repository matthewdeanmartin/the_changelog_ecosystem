Title: conventional-changelog-cli (hands-on synthesis)
Date: 2026-06-02
Slug: conventional-changelog-cli-v2
Ecosystem: node
Tags: conventional-commits, cli, node, changelog-file, hands-on
Tool_URL: https://www.npmjs.com/package/conventional-changelog-cli
Tool_Version: 5.0.0
Tool_Status: active
Experiment: examples/node/conventional-changelog-cli/
Summary: Hands-on re-review after driving conventional-changelog-cli through the tip-calculator life cycle.



## What I actually ran

- **Base image:** node:20-slim (Debian bookworm)
- **Tool version:** conventional-changelog-cli 5.0.0, installed globally via `npm install -g conventional-changelog-cli@5.0.0`
- **Scenario:** a four-stage Node.js tip-calculator life cycle inside Docker, all git activity contained in the container

The four stages were:

1. **v1.0.0 baseline** — initial commit tagged `v1.0.0`, no changelog yet.
2. **Full-history generation** — `conventional-changelog -p angular -i CHANGELOG.md -s -r 0` wrote a complete CHANGELOG.md covering all history from the first commit.
3. **Unreleased preview** — a new feature commit was made, then `conventional-changelog -p angular -u` previewed the pending release block to stdout without touching CHANGELOG.md.
4. **Incremental releases** — `conventional-changelog -p angular -i CHANGELOG.md -s` (without `-r 0`) prepended only the new release block and preserved existing content for v2.0.0 and v3.0.0.

## Real output

The final CHANGELOG.md produced after all three releases:

```markdown
# [3.0.0](https://github.com/example/tipcalc/compare/v2.0.0...v3.0.0) (2026-06-02)
# [2.0.0](https://github.com/example/tipcalc/compare/v1.0.0...v2.0.0) (2026-06-02)


### Features

* split the bill evenly among diners ([5aac67e](https://github.com/example/tipcalc/commit/5aac67e0c22c97d00385335867c41fb1de472da2))

# [1.0.0](https://github.com/example/tipcalc/compare/12ea504fb1898ff97805ad9724ea3f409daa3d5a...v1.0.0) (2026-06-02)


### Features

* compute tip for a single bill ([12ea504](https://github.com/example/tipcalc/commit/12ea504fb1898ff97805ad9724ea3f409daa3d5a))
```

## Pros (observed)

**Zero-config startup.** No `.versionrc`, no `conventional-changelog.config.js`, no `package.json` extras beyond a `repository.url` field. A single command generated a complete changelog from scratch.

**Incremental append works reliably.** The `-i CHANGELOG.md -s` flags correctly prepend the newest release block and leave existing history untouched across multiple releases. This is the core workflow, and it held up across v1 through v2.

**Unreleased preview is usable.** The `-u` flag, which some older documentation suggests may be absent or unstable, worked in v5.0.0. It emits the candidate release block to stdout without modifying the file — useful for CI diff checks or human review before tagging.

**Automatic commit links.** Short SHA hashes are hyperlinked to the GitHub compare/commit URLs drawn from `package.json`'s `repository.url`. No additional configuration needed.

**`vX.Y.Z` tag format recognized out of the box.** The angular preset's tag pattern matched standard semver tags without extra regex configuration.

## Cons / pain points (observed)

**The `feat!:` breaking-change shorthand silently drops its content.** Commit `feat!: split the bill unevenly by weight` triggered v3.0.0 generation but the "Features" list under that heading was empty. Worse, the v3.0.0 and v2.0.0 headers ran together with no blank line between them, producing invalid markdown. No error, no warning — the tool succeeded with exit code 0. The `!` breaking-change indicator is not reliably supported in the angular preset at this version; a conventional `BREAKING CHANGE:` footer in the commit body is likely required instead.

**Silent data loss with no diagnostic.** The tool produced a structurally broken changelog entry and exited cleanly. In a release pipeline, this would silently publish a changelog with a missing v3.0.0 body.

**The package is deprecated.** `npm install -g conventional-changelog-cli@5.0.0` prints:

```
npm warn deprecated conventional-changelog-cli@5.0.0: This package is no longer maintained.
Please use the conventional-changelog package instead.
```

The maintainers have consolidated tooling into the `conventional-changelog` monorepo. This CLI is a dead end for new projects.

**`chore(release):` commits are suppressed without explanation.** Correct behavior, but non-obvious to first-time users who wonder where their release commits went.

**`repository.url` is mandatory for usable output.** If the field is missing from `package.json`, commit links are dropped and the release header URL is broken. The tool makes no attempt to detect the URL from `git remote`.

## Docs vs. reality

The first-pass article (`conventional-changelog-cli.md`) described the tool as "actively maintained as part of the conventional-changelog package family" and gave a **Situational** verdict. Both of those assessments need updating:

- **Maintenance:** The package is deprecated at npm install time, not "actively maintained." It received a final 5.0.0 release but is no longer being developed. The recommended path is the underlying `conventional-changelog` library or a higher-level tool like `release-please` or `semantic-release`.
- **Output quality:** The first article described output as "useful and predictable." Hands-on testing found a silent content-drop bug on breaking-change commits that undermines the "predictable" characterization.
- **The `-u` flag:** The first article did not mention the unreleased-preview flag at all. It works and is genuinely useful for pre-release inspection.
- **Configuration burden:** The first article correctly noted low setup friction. That held up — the zero-config experience for simple `feat:` and `fix:` commits is real.

## Revised verdict

**Verdict: Do Not Start Here**

`conventional-changelog-cli` does one thing well: it generates a reasonably formatted CHANGELOG.md from conventional commits with almost no configuration. The incremental append model works. For a project already using it and not hitting breaking-change commits, there is no urgent reason to migrate.

However, the deprecation notice and the silent breaking-change data-loss bug are disqualifying for new adoption. Any project evaluating changelog tooling in 2026 should use `release-please`, `semantic-release`, or at minimum the upstream `conventional-changelog` library directly. If the npm script simplicity is the draw, a shell alias around the underlying library avoids the deprecated CLI layer.

If you do use it, test your changelog output after any `feat!:` or `BREAKING CHANGE:` commit before tagging and publishing.
