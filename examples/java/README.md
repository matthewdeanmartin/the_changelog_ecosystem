# Java tool experiments

Five Java changelog/release tools (3 Gradle, 2 Maven), each driven through the tip-calculator life cycle in Docker.
Run any experiment with `make run` from its directory. Artifacts land in `out/`.

## Results (run date: 2026-06-02)

| Tool | Version | Outcome | Headline finding |
|------|---------|---------|-----------------|
| [org-jetbrains-changelog](org-jetbrains-changelog/) | 2.5.0 | ⚠️ Works with caveats | `patchChangelog` moves `[Unreleased]` to a versioned section correctly, but leaves a bare `## Unreleased` stub (no brackets) after each run — diverges from strict KAC format. `getChangelog` fails before the first release (`MissingVersionException`). No `checkChangelog` task despite docs. |
| [spotless-changelog](spotless-changelog/) | 3.1.2 | ⚠️ Works with caveats | First version computed as `0.1.0` (not `1.0.0`) — implicit `0.0.0` base unless `nextVersion` is configured. `**BREAKING**` marker did not trigger a major bump on a `0.x` project (undocumented guard). `changelogPush` fails without a `.gitignore` — build artifacts count as dirty. `changelogPrint` not `printLastChangelog` is the real task name. |
| [git-changelog-maven-plugin](git-changelog-maven-plugin/) | 2.2.11 | ✅ Full success | Generates CHANGELOG.md from git history using Handlebars templates. Works entirely offline on local git history. `<file>` is the real parameter name (docs show `<toFile>`). Conventional Commits prefixes passed verbatim — no built-in grouping by type. `{{#issues}}` silently produces nothing without issue-pattern config. Cold start ~60s (large dep graph: JGit + Handlebars + OkHttp + Kotlin stdlib). |
| [maven-changelog-plugin](maven-changelog-plugin/) | 2.3 | ❌ Broken | `git whatchanged` removed in modern Git; the bundled `maven-scm 1.8` gitexe provider cannot pass `--i-still-use-this`. Every invocation fails: `fatal: refusing to run without --i-still-use-this`. No HTML output produced. Not a CHANGELOG.md generator — produces Maven site HTML reports. |
| [net-wooga-github-release-notes](net-wooga-github-release-notes/) | 4.1.1 | ❌ Not publicly distributed | Plugin not on Gradle Plugin Portal — distributed only through a private Wooga Artifactory instance. Configuration-time failure: `Plugin not found in any of the following sources`. Even if resolved, it is CI-only (GitHub API calls for every operation). |

## Recommended by use case

- **KAC manual editing + Gradle release (IntelliJ plugin workflow):** org.jetbrains.changelog (with awareness of the stub-leaving behavior)
- **KAC as version source of truth (Gradle):** com.diffplug.spotless-changelog (configure `nextVersion` explicitly for 1.0.0 start)
- **Git-history changelog generation (Maven):** git-changelog-maven-plugin — the only Java tool in this batch that works cleanly from git commits
- **Maven site SCM reporting:** maven-changelog-plugin (only if using ancient Maven infrastructure; broken on modern Git)
- **GitHub Release automation (Gradle):** net.wooga.github-release-notes is internal-only; use the GitHub CLI or semantic-release instead

## Key gotchas

- **org.jetbrains.changelog leaves a `## Unreleased` stub** (without brackets) after every `patchChangelog` call. Re-add the `[brackets]` manually or write a sed fix in your release script.
- **spotless-changelog starts at `0.1.0`**, not `1.0.0`. Set `spotlessChangelog { nextVersion("1.0.0") }` explicitly for the first release.
- **maven-changelog-plugin is broken on modern Git** (`git whatchanged` removed). Version 2.3 (2014) uses maven-scm 1.8 (2013) — do not use.
- **net.wooga.github-release-notes is not publicly available.** The plugin ID appears on the Gradle Plugin Portal listing page, but the artifact is hosted on a private registry. Fetching it requires Wooga-internal Artifactory credentials.
- **git-changelog-maven-plugin `{{#issues}}` is silent without config.** Without an `<issuePattern>` configured, the issues helper never matches and produces no output — no error, no warning.
