Title: Decision Chart
Date: 2026-06-02
Slug: decision-chart
sortorder: 4
Summary: A visual guide to choosing the right changelog and release management tool.

This diagram helps you navigate the ecosystem based on your workflow preferences and technical constraints.

<div class="mermaid">
graph TD
    Start[Choose a Changelog Strategy] --> Commits[Commit-based]
    Start --> Fragments[Fragment-based]

    Commits --> Conv{Conventional<br/>Commits?}
    Conv -->|Yes| ConvTools[Conv. Commit Tools]
    Conv -->|No| GenericCommits[Generic Commit Tools]
    
    Fragments --> FragEcosystem{Ecosystem?}
    FragEcosystem -->|Python| PyFrag[Towncrier, Scriv, Reno]
    FragEcosystem -->|Node| NodeFrag[Changesets]
    FragEcosystem -->|Go/Cross| GoFrag[Changie]

    ConvTools --> ConvEcosystem{Ecosystem?}
    ConvEcosystem -->|Rust/Cross| RustConv[git-cliff, release-plz]
    ConvEcosystem -->|Node| NodeConv[semantic-release, release-it]
    ConvEcosystem -->|Go| GoConv[goreleaser, git-chglog]
    ConvEcosystem -->|.NET| DotNetConv[versionize, dotnet-releaser]

    GenericCommits --> GenEcosystem{Ecosystem?}
    GenEcosystem -->|Node/Cross| NodeGen[auto-changelog]
    GenEcosystem -->|Ruby/Cross| RubyGen[github-changelog-generator]

    %% Styles
    classDef highlight fill:#f9f,stroke:#333,stroke-width:2px;
    class Start highlight;

</div>

## Key Decision Points

### 1. Commit-based vs. Fragment-based

* **Commit-based**: Tools like `git-cliff` or `semantic-release` generate the changelog directly from your git history.
  This is the most automated approach but requires disciplined commit messages.
* **Fragment-based**: Tools like `Towncrier` or `Changesets` require developers to create small files (fragments) for
  each change. These fragments are later merged into a single changelog. This prevents merge conflicts in monorepos and
  allows for more manual curation.

### 2. Conventional Commits

Many modern tools require or strongly recommend the [Conventional Commits](https://www.conventionalcommits.org/)
specification. If you are already using this format, tools like `git-cliff` provide excellent out-of-the-box results.

### 3. Orchestration vs. Generation

* **Generators**: Focus solely on creating the changelog file or release notes (e.g., `git-cliff`, `towncrier`).
* **Orchestrators**: Handle the entire release lifecycle: bumping versions, creating git tags, publishing to
  registries (npm, PyPI), and creating GitHub/GitLab releases (e.g., `semantic-release`, `release-it`, `goreleaser`).

<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
<script>mermaid.initialize({startOnLoad:true});</script>
