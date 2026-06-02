Title: changelog-generator (hands-on synthesis)
Date: 2026-06-02
Slug: changelog-generator-v2
Ecosystem: go
Tags: go, conventional-commits, git-history, changelog-file, hands-on
Tool_URL: https://pkg.go.dev/gabe565.com/changelog-generator
Tool_Version: 1.1.5
Tool_Status: active
Experiment: examples/go/changelog-generator/
Summary: Hands-on re-review of changelog-generator — a commit-based changelog generator with 4 GitHub stars.



## What I Actually Ran

I built a Docker container using `golang:1.24-bookworm`, installed `changelog-generator` via
`go install gabe565.com/changelog-generator@v1.1.5`, and ran a three-tag lifecycle on a
language-agnostic shell script app (`tipcalc.sh`). Commits were tagged v1.0.0, v2.0.0, and v3.0.0.
The full script and transcript live in `examples/go/changelog-generator/`.

**First hurdle:** The Dockerfile initially used `golang:1.22`, which the module rejects at install
time — v1.1.5 requires Go >= 1.24. That requirement is not mentioned on the GitHub releases page or
in the README prominently. Bumping the base image to `golang:1.24` resolved it cleanly.

**Second discovery:** The GitHub Action documentation implies an `--output` flag on the binary.
It does not exist. There is no `--output`, no `-o`, and no equivalent. The binary writes to stdout
only. The `output` parameter in the GitHub Action is handled by the Action wrapper, not by the
binary itself. That distinction matters for anyone trying to use the binary directly in a CI script.

## Real Output

### Help text (entire CLI surface)

```
Generates a changelog from commits since the previous release

Usage:
  changelog-generator [flags]

Flags:
      --config string   Config file (default ".changelog-generator.yaml")
  -h, --help            help for changelog-generator
  -C, --repo string     Path to the git repo root. Parent directories will be walked until .git is found. (default ".")
  -v, --version         version for changelog-generator
```

Three user-facing flags. That is the entire interface.

### Version string

```
changelog-generator version beta
```

The binary reports "beta" rather than "1.1.5". This appears to be a stale embedded build-time
constant. It is cosmetically confusing but has no functional impact.

### Generated changelog — no config file

After tagging v1.0.0 and committing one conventional-commit message, running `changelog-generator`
produces:

```markdown
## Changelog
- 240c69c7 feat: compute tip for a single bill
```

After v2.0.0 → v3.0.0 with a breaking-change commit:

```markdown
## Changelog
- 5c837c1b feat!: split the bill unevenly by weight
```

The tool correctly finds only the commits since the previous tag. Without a config file there are
no sections — one flat list under `## Changelog`. The `feat!:` breaking-change marker appears
verbatim; the tool does not automatically separate it into a "Breaking Changes" section.

### Writing to a file

```bash
changelog-generator > CHANGELOG.md
```

That is the only file-writing mechanism. The `--output` flag shown in some external documentation
does not exist in the binary.

## Pros

- **Zero mandatory configuration.** Run it in any git repo with tagged releases and it produces
  output immediately.
- **Correct incremental behavior.** It reliably finds the previous tag and shows only the commits
  since then. No manual range arguments needed.
- **Language-agnostic.** The shell-script fixture confirmed it works on any repo. Not Go-specific
  despite the Go distribution.
- **Small, fast binary.** At roughly 8 MiB (per the release notes) it is an unobtrusive addition
  to any CI image.
- **GitHub Action wrapper available.** If the primary use case is GitHub Actions, the wrapper
  handles file writing and token auth cleanly.

## Cons

- **Stdout only.** No `--output` flag. Shell redirection is required to write a file, which is a
  minor but real ergonomic gap versus tools like `git-cliff --output CHANGELOG.md`.
- **No grouping without config.** Out of the box there are no "Features", "Bug Fixes", or
  "Breaking Changes" sections. Every commit lands in one flat list. This is fine for simple release
  notes but falls short of what most teams expect from a changelog generator.
- **Version string says "beta."** A v1.1.5 binary that identifies itself as "beta" is a quality
  signal that deserves notice.
- **Requires Go 1.24.** That is a newer toolchain than many CI base images include. Users of
  `golang:1.22` images (still common) will hit an install-time error with no clear guidance.
- **4 GitHub stars.** At time of writing the project has four stars. That is not evidence of
  a bad tool, but it does mean the community is tiny, issue response time may be slow, and
  long-term maintenance is uncertain. By contrast, `git-cliff` has over 6,000 stars.
- **No changelog accumulation.** Each run replaces the previous output. There is no `--prepend`
  or append mode; maintaining a running `CHANGELOG.md` across many releases requires scripting
  on top of the tool.
- **Docs vs. reality gap.** The GitHub Action documentation creates the impression that `--output`
  is a binary flag. It is not. Users trying to use the CLI outside of GitHub Actions will be
  confused.

## Docs vs. Reality

The README covers installation and the GitHub Action well. The CLI itself is barely documented —
there is no man page, no extended help, and no examples section for CLI-only usage. The
`config_example.yaml` (linked from the README) shows what grouping and filtering look like with a
config file, which is the most useful piece of secondary documentation.

The release page is accurate about binary sizes but the "version beta" string in the binary is
inconsistent with a tagged 1.x release series. This is a documentation-quality signal.

The GitHub Action's `output` parameter is documented as writing the changelog to a file path. This
works, but the underlying binary does not support `--output`. Anyone reading the Action docs and
trying to replicate the behavior in a non-Actions CI will be frustrated until they discover the
stdout-only design.

## Revised Verdict

**Verdict: Narrow fit, use with clear expectations**

`changelog-generator` does its one job — emit commits since the last tag to stdout — correctly and
with zero friction. If your use case is exactly "run in GitHub Actions, get a text blob for a
GitHub Release body," it is a reasonable choice.

Outside that narrow scope, the tool has gaps that matter. No output flag, no accumulation mode,
no auto-grouping without config, a misleading version string, and a Go 1.24 requirement that is
not prominently documented combine to make it a rougher experience than the documentation implies.

The 4-star count is not a disqualifier by itself — plenty of small, focused tools earn their place
without community buzz — but it does mean you are taking on maintenance risk. If the maintainer
stops responding, there is no ecosystem to fall back on. For teams already in the GitHub Actions
ecosystem and wanting GoReleaser-style release notes without GoReleaser, this is worth a try. For
everyone else, `git-cliff` offers substantially more functionality, better documentation, and a
large community at the cost of slightly more initial configuration.
