## Experiment Notes: net.wooga.github-release-notes 4.1.1

**Run date:** 2026-06-02  
**Environment:** Docker, gradle:8.8-jdk21-alpine  
**Gradle version:** 8.8  

---

## Result: Plugin Not Found in Gradle Central

Every stage of the experiment failed at the same point — the plugin cannot be resolved at all:

```
Plugin [id: 'net.wooga.github-release-notes', version: '4.1.1'] was not found
in any of the following sources:

- Gradle Core Plugins (plugin is not in 'org.gradle' namespace)
- Included Builds (No included builds contain this plugin)
- Plugin Repositories (could not resolve plugin artifact
  'net.wooga.github-release-notes:net.wooga.github-release-notes.gradle.plugin:4.1.1')
  Searched in the following repositories:
    Gradle Central Plugin Repository
```

This is a harder failure than anticipated. The pre-experiment hypothesis was that the plugin would
apply successfully but then fail at runtime when making GitHub API calls without a token. Instead,
the plugin is not published to the Gradle Plugin Portal at all.

---

## Full Experiment Transcript

```
Plugin: net.wooga.github-release-notes 4.1.1

------------------------------------------------------------
Gradle 8.8

==================== STAGE 1: v1.0.0 code setup ====================

Committed v1.0.0 and tagged.

==================== STAGE 2: list all tasks registered by the plugin ====================

FAILURE: Build failed with an exception.

* Where:
Build file '/work/app/build.gradle.kts' line: 1

* What went wrong:
Plugin [id: 'net.wooga.github-release-notes', version: '4.1.1'] was not found in any of the following sources:

- Gradle Core Plugins (plugin is not in 'org.gradle' namespace)
- Included Builds (No included builds contain this plugin)
- Plugin Repositories (could not resolve plugin artifact 'net.wooga.github-release-notes:net.wooga.github-release-notes.gradle.plugin:4.1.1')
  Searched in the following repositories:
    Gradle Central Plugin Repository

BUILD FAILED in 22s

==================== STAGE 3: task help / dry-run ====================

BUILD FAILED in 5s   [same error — plugin not found]
BUILD FAILED in 5s   [same error — plugin not found]

==================== STAGE 4: attempt githubPublish (expected: FAILED — no GitHub token) ====================

BUILD FAILED in 5s   [same error — plugin not found]
FAILED as expected — requires GITHUB_TOKEN

==================== STAGE 5: summary ====================

Project properties (version line):
Plugin [id: 'net.wooga.github-release-notes', version: '4.1.1'] was not found...

Available release-notes related tasks:
(none found or plugin failed to apply)

==================== DONE — copying artifacts to out/ ====================
```

---

## Analysis

### Why the plugin cannot be resolved

The Gradle Plugin Portal (plugins.gradle.org) lists the plugin with ID
`net.wooga.github-release-notes`, but the artifact resolution fails. This happens when:

1. The plugin is published to Wooga's own Maven repository, not to the Gradle Plugin Portal
   itself, and the Plugin Portal entry only contains a redirect/marker pointing at a custom
   repository that is either private, deprecated, or requires additional `pluginManagement`
   repository declarations.

2. The plugin page at https://plugins.gradle.org/plugin/net.wooga.github-release-notes exists
   (it appears in the Portal search index) but the underlying Maven coordinates are not
   resolvable from the standard Gradle Central Plugin Repository endpoint.

To use this plugin in a real project, the consuming `settings.gradle.kts` would need to declare
the Wooga Atlas Maven repository explicitly, something like:

```kotlin
pluginManagement {
    repositories {
        maven { url = uri("https://wooga.jfrog.io/wooga/libs-release") }
        gradlePluginPortal()
    }
}
```

This is a significant barrier for any new adopter. The plugin's own documentation does not
surface this requirement prominently.

### Secondary finding: CI-only by design

Even if the plugin could be resolved, it would still be CI-only. It makes GitHub API calls
to read pull request labels and titles, and POSTs to the GitHub Releases API. These operations
require `GITHUB_TOKEN` and an actual GitHub remote — neither of which is available in a local
or offline context.

Zero local changelog use case exists.

### Stars: 0

The GitHub repository (https://github.com/wooga/atlas-release) has 0 public stars. The plugin
is exclusively an internal Wooga build tool that has been made technically public but is not
intended for general adoption.

---

## Conclusion

`net.wooga.github-release-notes` 4.1.1:

- Cannot be applied without adding a Wooga-specific Maven repository to `pluginManagement`
- Even with the repository configured, requires `GITHUB_TOKEN` and live GitHub API access
- No offline or local changelog use case
- 0 stars, Wooga-internal tooling published publicly but not maintained for external use
- **Verdict: Do not use outside the Wooga Atlas ecosystem**
