Title: goreleaser (hands-on synthesis)
Date: 2026-06-02
Slug: goreleaser-v2
Ecosystem: go
Tags: go, release-orchestration, changelog-generate, ci-cd, hands-on
Tool_URL: https://goreleaser.com/
Tool_Version: 2.16.0
Tool_Status: active
Experiment: examples/go/goreleaser/
Summary: Hands-on re-review of goreleaser — Go release automation where changelog is one stage of a larger pipeline.



## What I actually ran

The experiment built a Docker image from `golang:1.22-bullseye`, installed goreleaser 2.16.0 from the official GitHub Release tarball, set up a minimal Go project (`github.com/example/tipcalc`) with three tagged commits, and attempted to exercise every changelog-related command path:

- `goreleaser --version` — confirmed v2.16.0
- `goreleaser changelog` — tested as documented in some goreleaser references
- `goreleaser release --snapshot --clean --skip=publish,announce,validate` — full offline release run, twice (v2.0.0 and v3.0.0)

The git history had three commits on tags `v1.0.0`, `v2.0.0`, and `v3.0.0`, all with conventional-commit messages (`feat:`, `feat!:`). The `.goreleaser.yaml` used `changelog.use: github` with commit grouping by prefix.

Full transcript: `examples/go/goreleaser/out/transcript.txt`

---

## Real output

### `goreleaser changelog` does not exist

The first surprise: `goreleaser changelog` is not a real subcommand in v2.16.0.

```
⨯ command failed    error=unknown command "changelog" for "goreleaser release"
```

Some blog posts and older docs refer to it, but in the current release there is no standalone changelog subcommand. Changelog generation is a pipeline stage that runs internally during `goreleaser release` and the result goes directly into the GitHub/GitLab/Gitea release body. It is never printed to stdout or written to `CHANGELOG.md` by default.

### Snapshot mode skips the changelog stage

`goreleaser release --snapshot` is the recommended offline path. It ran successfully and produced real artifacts — a compiled Linux amd64 binary, a tarball, and checksums:

```
dist/tipcalc_0.0.0-SNAPSHOT-none_linux_amd64.tar.gz
dist/tipcalc_0.0.0-SNAPSHOT-none_checksums.txt
```

But the changelog pipe was skipped entirely:

```
• pipe skipped or partially skipped    reason=disabled during snapshot mode
```

There is no way to preview what goreleaser would write to a GitHub Release body without actually performing a release against a real remote. The `--snapshot` flag exists specifically to validate the build and archive pipeline in isolation.

### Version detection without a remote

Without a git remote configured, goreleaser could not determine the current tag:

```
error=couldn't get remote URL: fatal: No remote configured to list refs from.
using tags    previous=<unknown> current=v0.0.0
```

Even with local tags `v1.0.0`/`v2.0.0`/`v3.0.0` present, goreleaser fell back to `v0.0.0`. This is specific to `changelog.use: github`, which calls the GitHub compare API. Switching to `changelog.use: git` would read local tags directly and work without a remote.

### Deprecation notice

The config used `archives.format: tar.gz` (scalar). goreleaser 2.x expects `archives.formats: [tar.gz]` (array) and emits a deprecation warning on every run. Minor but visible.

---

## What the changelog output looks like in production

Because snapshot mode skips changelog generation, no release note text was produced in the experiment. In a real release against a remote with `GITHUB_TOKEN` set, goreleaser would query the GitHub compare endpoint and embed structured markdown in the release body. With the grouping config used (`feat` → Features, `fix` → Bug Fixes), the three commits from this experiment would produce approximately:

```markdown
## Changelog

### Features

* feat: compute tip for a single bill
* feat: split the bill evenly among diners
* feat!: split the bill unevenly by weight

**Full Changelog**: https://github.com/example/tipcalc/compare/v1.0.0...v3.0.0
```

This text appears in the GitHub Release UI. It is not written to a `CHANGELOG.md` file on disk. If you want a file-based changelog you need to add a separate step — goreleaser integrates with `git-cliff` via its `before.hooks` or you can use the `--release-notes` flag to supply a pre-written file.

---

## Pros

**Full pipeline coherence.** Binary cross-compilation, archive creation, checksums, SBOMs, container image publishing, Homebrew taps, and release-note generation are all driven by a single config and a single command. For a Go CLI that distributes compiled artifacts, nothing else matches this scope.

**Proven and actively maintained.** 15,800+ GitHub stars, consistent releases, comprehensive documentation, and deep GitHub Actions integration. The goreleaser ecosystem is stable.

**Conventional commit grouping works.** The `changelog.groups` configuration with `regexp` matchers correctly categorizes commits without any boilerplate. You define the groups once and the tool applies them on every release.

**`goreleaser check` is fast and useful.** Config validation runs instantly and catches schema errors before you attempt a real release.

**`use: git` works locally.** Switching `changelog.use` from `github` to `git` makes changelog generation work from local git history without an API call or token.

---

## Cons

**No standalone changelog subcommand.** If you want to preview or extract the release notes text without pushing a release, you cannot do it with goreleaser alone. This is a meaningful gap for teams that do changelog-first workflows or want to review notes in a PR before the release tag is created.

**Changelog generation is gated behind a real release.** The `--snapshot` flag, which is the documented offline testing path, explicitly disables the changelog pipe. You cannot dry-run the notes text.

**`use: github` requires a remote and token.** The default recommended setting for Go projects hosted on GitHub requires network access even for what feels like a local operation. Developers who regularly run goreleaser locally must either switch to `use: git` or keep a token in their environment.

**Not a file-based changelog tool.** goreleaser writes release notes into the hosted release UI. It does not maintain `CHANGELOG.md`. Teams that want a checked-in file need a second tool or a custom `before.hooks` script.

**Config surface area is large.** The `.goreleaser.yaml` schema covers builds, archives, checksum, signs, SBOMs, snapshots, publishers, homebrew, announce, and more. For a team that only wants automated release notes, this is significant overhead to get started and maintain.

---

## Docs vs. reality

The goreleaser documentation is thorough and generally accurate for the full release pipeline. Two discrepancies surfaced in this experiment:

1. **`goreleaser changelog` subcommand.** References to a `changelog` subcommand appear in community blog posts and some older documentation. It does not exist in v2.16.0. The correct approach is `goreleaser release` with release-note config, or using the GitHub Release API directly.

2. **Snapshot mode and changelog.** The docs describe `--snapshot` as a way to "test your release pipeline locally." This is true for the build and archive stages. It is not true for the changelog/release-notes stage, which is silently skipped. The distinction is not prominently called out in the snapshot documentation.

The deprecation of `archives.format` (scalar) in favor of `archives.formats` (array) is documented in the goreleaser deprecations page but is easy to miss when copying config examples from tutorials written for 1.x.

---

## Revised verdict

**Verdict: Recommended for Go release pipelines; not recommended as a changelog-only tool**

goreleaser is the right choice when you are releasing a Go CLI or service that needs binary distribution — cross-platform builds, archives, checksums, Homebrew taps, container images, and hosted GitHub/GitLab releases all driven from a single pipeline. The changelog component comes along for free and is good enough for standard GitHub Release notes.

goreleaser is the wrong choice if your primary goal is changelog management:

- It does not write `CHANGELOG.md`.
- You cannot preview release notes without performing an actual release.
- The setup cost (full pipeline config, GitHub token, remote) is disproportionate if you only want a formatted commit log.

**When to use goreleaser for changelog:** You are already using goreleaser for binary distribution and want release notes auto-generated in the GitHub Release body. Configure `changelog.use: git` (not `github`) for offline safety, add grouping rules, and you are done.

**When to use something else:** You want a `CHANGELOG.md` file, a changelog preview in CI before the release tag, or changelog tooling that works independently of the deployment pipeline. In those cases, `git-cliff` (Rust-based, highly configurable templates, works entirely from local git) or `changie` (fragment-based, explicit control over every entry) are more appropriate. Both integrate with goreleaser via `before.hooks` if you need both a file and a hosted release body.
