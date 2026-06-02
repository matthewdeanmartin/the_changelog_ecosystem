# Go tool experiments

Four Go changelog/release tools, each driven through the tip-calculator life cycle in Docker.
Run any experiment with `make run` from its directory. Artifacts land in `out/`.

## Results (run date: 2026-06-02)

| Tool | Version | Outcome | Headline finding |
|------|---------|---------|-----------------|
| [changie](changie/) | 1.24.0 | ✅ Full success | Fragment workflow (`init → batch → merge`) works cleanly offline. Missing blank lines between version sections in the default template. `changie new` is interactive-only — no flags for scripted/CI use; drop raw `.yaml` files into `.changes/unreleased/` instead. No native breaking-change field. |
| [git-chglog](git-chglog/) | 0.15.4 | ✅ Works (archived) | Still fully functional despite repo being archived since 2023. All three tags, compare links, and `BREAKING CHANGE` detection worked correctly. Config gotcha: `pattern_maps` count must match regex group count or output is silently wrong. Recommend `git-cliff` for new projects. |
| [goreleaser](goreleaser/) | 2.16.0 | ⚠️ Build pipeline only | `goreleaser changelog` is not a real subcommand in v2.x. `--snapshot` mode explicitly disables changelog generation (`reason=disabled during snapshot mode`). No `CHANGELOG.md` produced — goreleaser writes changelog text into GitHub Release bodies, not local files. `changelog.use: github` requires a live remote; `changelog.use: git` works locally. |
| [changelog-generator](changelog-generator/) | 1.1.5 | ⚠️ Minimal, niche | Requires Go 1.24 (undocumented). No `--output` flag — use shell redirection. `--version` prints `version beta` despite tagged release. Core behavior works: emits commits since previous tag as bullets. No grouping without a config file. 4 GitHub stars — very low adoption; use `git-cliff` instead. |

## Recommended by use case

- **Fragment-based changelog (language-agnostic):** changie — closest Go-ecosystem equivalent to towncrier/scriv
- **Commit-history changelog (template control):** git-chglog still works, but start new projects with `git-cliff` (cross-ecosystem, actively maintained)
- **Go release pipeline (binaries + GitHub Release):** goreleaser — but pair it with `git-cliff` or changie via `before.hooks` for local `CHANGELOG.md`
- **Minimal commit-log to changelog:** changelog-generator works, but the 4-star count and no-output-flag UX make it hard to recommend

## Key gotchas

- **goreleaser does not write CHANGELOG.md.** It generates release note text for GitHub/GitLab/Gitea Release bodies. If you need a CHANGELOG.md file in your repo, wire git-cliff or changie as a `before.hooks` step.
- **goreleaser `--snapshot` disables changelog.** The documented offline testing path skips the entire changelog pipe. You cannot preview release notes without a live remote when using `changelog.use: github`.
- **changie `new` is interactive-only.** There are no `--kind` or `--body` flags. In CI or scripted workflows, write the `.yaml` fragment files directly into `.changes/unreleased/`.
- **git-chglog `pattern_maps` must match regex group count.** A 3-group regex with 3 pattern_maps entries is required; mismatches cause silent empty output with no error. Start with a 2-group config if you don't need scope.
- **changelog-generator requires Go 1.24.** The module's `go.mod` has a `go 1.24` directive that is enforced at install time. `golang:1.22` base images will fail.
- **git-chglog is archived.** The repository has been read-only since 2023. It works today but will not receive bug fixes. Migrate to `git-cliff` for new projects.
