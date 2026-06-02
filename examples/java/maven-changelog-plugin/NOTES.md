# Experiment Notes: maven-changelog-plugin 2.3

## Environment

- Docker image: `maven:3.9-eclipse-temurin-21-alpine`
- Git version in container: modern (2.x from Alpine apk)
- Maven version: 3.9.16
- Java: 21.0.11 (Eclipse Adoptium)
- Plugin: `org.apache.maven.plugins:maven-changelog-plugin:2.3`

## What was attempted

Five stages:

1. git init, initial commit of tipcalc v1, tag v1.0.0
2. Run `mvn changelog:changelog` (1 commit in repo)
3. Add v2 commit (split bill evenly), tag v2.0.0
4a. Run `mvn changelog:changelog` again (2 commits)
4b. Add v3 commit (uneven weighted split), tag v3.0.0; run changelog and dev-activity
5. Run `mvn site` (full site generation with all reporting plugins)

## Root cause failure: git whatchanged removed

Every invocation of `changelog:changelog`, `changelog:dev-activity`, and `mvn site` failed
with the same error:

```
[INFO] Executing: /bin/sh -c cd /work/app && git whatchanged \
  '--since=2026-05-03 12:40:42 +0000' \
  '--until=2026-06-03 12:40:42 +0000' \
  --date=iso -- /work/app
[ERROR] Provider message:
[ERROR] The git-log command failed.
[ERROR] Command output:
[ERROR] 'git whatchanged' is nominated for removal.
...
fatal: refusing to run without --i-still-use-this
```

The maven-scm `gitexe` provider (version 1.8, bundled with maven-changelog-plugin 2.3)
invokes `git whatchanged` to retrieve commit history. Modern Git versions have deprecated
and then hard-blocked `git whatchanged` unless the caller passes `--i-still-use-this`.
The plugin has no mechanism to pass that flag — it constructs the command internally.

This is not a configuration issue. No pom.xml setting can fix it. The only fixes are:
- Use an older Git binary (pre-deprecation)
- Build a patched version of maven-scm's gitexe provider
- Pin the container to an Alpine release that ships an older Git

## Output produced

None. No HTML files were generated anywhere. `target/site/` was never created.

```
$ ls -la out/
total 232
drwxr-xr-x  out/
-rw-r--r--  transcript.txt   (232 KB — Maven download noise + error messages)
```

No `changelog.html`, no `dev-activity.html`, no `file-activity.html`.

## Git log at end of experiment

```
3f39cdf (HEAD -> master, tag: v3.0.0) feat!: split the bill unevenly by weight
472215d (tag: v2.0.0) feat: split the bill evenly among diners
1aff785 (tag: v1.0.0) feat: compute tip for a single bill
```

## SCM configuration

The pom.xml used `scm:git:file:///work/app` as the SCM connection. Maven-scm accepted
this configuration without complaint — the failure occurs when the actual git subprocess
is launched, not during SCM URL parsing.

## Conclusion

maven-changelog-plugin 2.3 is completely non-functional with any modern Git installation.
The `mvn site` fallback also fails for the same reason since it invokes the same plugin.
The plugin is effectively dead unless pinned to a legacy Git binary.
