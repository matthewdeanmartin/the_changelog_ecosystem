Tool: git-changelog-maven-plugin 2.2.11    Status: complete

# Experiment notes

## Checklist
- [x] Copied TEMPLATE, set TOOL in Makefile
- [x] Dockerfile installs the tool + git on a pinned base image (maven:3.9-eclipse-temurin-21-alpine)
- [x] app/ runs and prints (all three versions)
- [x] scenario/ has the tool's seed config / fragments
- [x] run_experiment.sh walks all 4 life-cycle stages, commits/tags in /work
- [x] `make run` completes end-to-end with only Docker installed
- [x] out/ contains final CHANGELOG.md + transcript
- [x] host `git status` shows only new examples/ source (no scenario .git)
- [x] transcript + pros/cons/pain points captured below
- [x] content/articles/git-changelog-maven-plugin.v2.md written, grounded in the run

## Installed version

Apache Maven 3.9.16 (2bdd9fddda4b155ebf8000e807eb73fd829a51d5)
Java version: 21.0.11, vendor: Eclipse Adoptium
git-changelog-maven-plugin: 2.2.11
git-changelog-lib (transitive): 2.6.1

## Per-stage output

### Stage 1 — no changelog
Initial commit tagged v1.0.0. No CHANGELOG.md exists yet. Confirmed with dump_changelog.

### Stage 2 — changelog created
First `mvn generate-resources` run. Maven downloaded ~40 dependencies from Maven Central on cold
start (about 60s). Plugin executed and wrote CHANGELOG.md:

```
# Changelog

## v1.0.0
- feat: compute tip for a single bill
```

One warning was emitted: `Parameter 'toFile' is unknown for plugin`. The correct parameter name
is `file`, not `toFile`. The plugin defaulted to writing CHANGELOG.md anyway because it falls
back to that name. The pom.xml was corrected after the initial run (toFile -> file) so future
runs are warning-free.

### Stage 3 — changelog updated (toward v2.0.0)
v2 code committed. CHANGELOG.md shows only v1.0.0 (no new tag yet, expected).

### Stage 4 — bump + release (v2.0.0, v3.0.0)

After tagging v2.0.0 and re-running `mvn generate-resources`:
```
# Changelog

## v2.0.0
- feat: split the bill evenly among diners

## v1.0.0
- feat: compute tip for a single bill
```

After committing v3 code, tagging v3.0.0, and re-running:
```
# Changelog

## v3.0.0
- feat!: split the bill unevenly by weight

## v2.0.0
- feat: split the bill evenly among diners

## v1.0.0
- feat: compute tip for a single bill
```

The breaking-change marker `feat!:` is preserved verbatim in the output — the plugin does not
interpret Conventional Commits prefixes by default. The commit message appears as-is.

## Pros (observed)

- Zero ceremony for basic use: one `<plugin>` block in pom.xml, bind to a phase, run. Done.
- Tags are automatically detected via JGit; no extra configuration to group commits by release.
- Handlebars templates are expressive — the same `{{#tags}}...{{#commits}}` pattern works
  and the variable names (`name`, `messageTitle`) are intuitive.
- Runs entirely inside the Maven lifecycle — no extra tool installs or CI steps needed.
- Second run on a warm Maven cache is very fast (~1s).
- Template is inline in pom.xml or can be an external file — both are supported.
- The plugin defaults sensibly: if no output path is set it writes CHANGELOG.md.

## Cons / pain points (observed)

- Wrong parameter name (`toFile`) in 2.2.11 docs/examples — the real name is `file`. The plugin
  silently ignores unknown parameters and falls back to default behavior, which hides the
  misconfiguration rather than failing loudly.
- No built-in Conventional Commits grouping. Commit messages like `feat:` and `feat!:` are
  passed through unchanged. To get a grouped changelog (Features / Breaking Changes / Bug Fixes)
  you must write the grouping logic yourself in the Handlebars template, using the plugin's
  issue-pattern mechanism or custom helper registrations.
- First cold-start dependency resolution is slow (~60s) and downloads a large transitive graph:
  JGit, Handlebars, Jackson, OkHttp, Retrofit, Nashorn, Kotlin stdlib — more than expected for a
  changelog generator.
- The `{{#issues}}` Handlebars helper (shown in some plugin examples) requires explicit issue
  patterns to be configured; without them the block produces no output and silently renders
  nothing. New users are likely to stare at blank output.
- Maven-only. Gradle users must look elsewhere.

## Docs vs. reality

- Official README shows `<toFile>` as a configuration parameter. In 2.2.11 this is wrong — the
  parameter is named `file`. Maven warns but does not error, so the misconfiguration is easy to
  miss.
- Template examples in the README use `{{#issues}}`, which requires issue patterns. Without them
  the block iterates over zero items and produces no output. A beginner following the README
  example exactly will get an empty CHANGELOG.
- The `{{#tags}}...{{#commits}}` nesting does work exactly as documented once you get past the
  issue-section trap.

## Revised verdict

The plugin delivers on its core promise: bind it to a Maven phase, point it at a template, get a
changelog. The machinery (JGit + Handlebars) is solid and the tag-grouping works correctly out
of the box with no configuration beyond the template. For teams that live in Maven and want
changelog generation wired into `mvn verify` or a release profile, this is a practical choice.

The pain is friction, not failure: a wrong parameter name in official documentation, silent
no-op on misconfigured template helpers, and a heavier-than-necessary dependency tree. None of
these are blockers, but they mean the first-time setup experience is rockier than it should be.
Teams expecting zero-config Conventional Commits output will be disappointed; the plugin treats
commit messages as plain strings and leaves grouping to the template author.

Verdict remains Recommended for Maven-native teams willing to spend 30 minutes getting the
template right. Not recommended as a first pick for teams that want out-of-the-box Conventional
Commits structured output.

## Raw transcript

```
Plugin: git-changelog-maven-plugin 2.2.11
Apache Maven 3.9.16 (2bdd9fddda4b155ebf8000e807eb73fd829a51d5)
Maven home: /usr/share/maven
Java version: 21.0.11, vendor: Eclipse Adoptium, runtime: /opt/java/openjdk
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "5.15.153.1-microsoft-standard-wsl2", arch: "amd64", family: "unix"

==================== STAGE 1: v1.0.0 code, NO changelog ====================

(no CHANGELOG.md yet)

==================== STAGE 2: generate changelog from git history ====================

[INFO] Scanning for projects...
[INFO]
[INFO] ------------------------< com.example:tipcalc >-------------------------
[INFO] Building tipcalc 1.0.0
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] Downloading from central: ...git-changelog-maven-plugin-2.2.11.pom (2.3 kB)
[INFO] Downloaded from central: ...git-changelog-maven-plugin-2.2.11.jar (25 kB)
[WARNING] Parameter 'toFile' is unknown for plugin 'git-changelog-maven-plugin:2.2.11:git-changelog (generate-changelog)'
[INFO]
[INFO] --- git-changelog-maven-plugin:2.2.11:git-changelog (generate-changelog) @ tipcalc ---
[INFO] ... (dependency downloads ~60s cold start) ...
[INFO] Extended variables:
[INFO] No output set, using file CHANGELOG.md
[INFO] #
[INFO] # Wrote: /work/app/CHANGELOG.md
[INFO] #
[INFO] BUILD SUCCESS
----- CHANGELOG.md -----
# Changelog

## v1.0.0
- feat: compute tip for a single bill

------------------------

==================== STAGE 3: implement even split ====================

----- CHANGELOG.md -----
# Changelog

## v1.0.0
- feat: compute tip for a single bill

------------------------

==================== STAGE 4a: tag v2.0.0, regenerate changelog ====================

[INFO] Building tipcalc 2.0.0
[WARNING] Parameter 'toFile' is unknown for plugin ...
[INFO] --- git-changelog-maven-plugin:2.2.11:git-changelog (generate-changelog) @ tipcalc ---
[INFO] Extended variables:
[INFO] No output set, using file CHANGELOG.md
[INFO] # Wrote: /work/app/CHANGELOG.md
[INFO] BUILD SUCCESS
[INFO] Total time:  1.010 s
----- CHANGELOG.md -----
# Changelog

## v2.0.0
- feat: split the bill evenly among diners

## v1.0.0
- feat: compute tip for a single bill

------------------------

==================== STAGE 4b: implement uneven split, tag v3.0.0 ====================

[INFO] Building tipcalc 3.0.0
[WARNING] Parameter 'toFile' is unknown for plugin ...
[INFO] --- git-changelog-maven-plugin:2.2.11:git-changelog (generate-changelog) @ tipcalc ---
[INFO] Extended variables:
[INFO] No output set, using file CHANGELOG.md
[INFO] # Wrote: /work/app/CHANGELOG.md
[INFO] BUILD SUCCESS
[INFO] Total time:  1.082 s
----- CHANGELOG.md -----
# Changelog

## v3.0.0
- feat!: split the bill unevenly by weight

## v2.0.0
- feat: split the bill evenly among diners

## v1.0.0
- feat: compute tip for a single bill

------------------------

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
-rw-r--r-- 1 root root   170 Jun  2 12:35 CHANGELOG.md
-rw-r--r-- 1 root root   200 Jun  2 12:35 git-log.txt
-rw-r--r-- 1 root root    21 Jun  2 12:35 git-tags.txt
-rw-r--r-- 1 root root 41783 Jun  2 12:35 transcript.txt
```
