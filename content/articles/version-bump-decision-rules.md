Title: Version Bump Decision Rules
Date: 2026-06-01
Slug: version-bump-decision-rules
Ecosystem: Cross
Tags: version-bump, semantic-versioning, release-automation, change-classification
Tool_Status: research
Summary: Stub article on rules tools use to choose the next version.

## Overview

"What should the next version be?" has many possible inputs, and tools differ mainly in which input they trust. Each source has a different reliability profile and a different failure mode.

| Bump source | How the bump is derived | Reliability | Failure mode |
|---|---|---|---|
| Conventional Commits | `feat` → minor, `fix` → patch, `!`/`BREAKING CHANGE:` → major; highest wins | High *if* commits are disciplined | A mislabeled commit silently picks the wrong bump |
| Changelog categories | KAC section of each entry maps to a bump (`Removed` → major, `Added` → minor, `Fixed` → patch) | High; entries are human-curated | Depends on correct section assignment |
| Fragment metadata | Each fragment declares its bump (Changie `kind` `auto:` field, Reno section) | Highest — bump is explicit per change | Contributor must pick the right kind |
| Pull request labels | A `semver-major`/`minor`/`patch` label on the PR | Medium; visible and reviewable | Forgotten or wrong label; squash loses per-commit signal |
| Branch names | `release/2.0`, `hotfix/*` patterns imply the bump | Low; convention only | Easy to misname; no enforcement |
| Manual release plan | A maintainer states the next version explicitly | Highest intent, lowest automation | Human error, but a human owns it |
| Package-manager constraints | Registry/ecosystem rules cap or shape the version (e.g. `0.x` semantics, pre-1.0 conventions, monorepo independent versioning) | Constraint, not a source | Tool computes a version the ecosystem rejects |

Two cross-cutting facts shape every tool's choice. First, **the highest bump wins**: across all changes in a release, the most significant one sets the version — one breaking change makes the whole release a major. Second, **inputs degrade under squash merges**: per-commit signals (Conventional Commits, per-commit trailers) are fragile when a forge squashes a PR, whereas per-PR signals (labels, fragment files, release plans) survive. Tools that key off commits push hard on commit discipline; tools that key off fragments or plans move the decision to a place that survives history rewriting.

The pre-1.0 case deserves its own note: while `0.y.z`, SemVer makes no compatibility promise, so most tools treat a breaking change as a *minor* bump (`0.4.0` → `0.5.0`) rather than rolling to `1.0.0`. Several generators require an explicit opt-in before they will ever produce a `1.0.0`, precisely because crossing to a stable major is a decision a human should make.

## Inputs

- Breaking-change markers.
- Feature and fix categories.
- Explicit fragment metadata.
- Pull request labels.
- Maintainer override.

## Recommendation

A conservative model automates the unambiguous cases and routes everything else to a human. The goal is to never *silently* ship a wrong version, even at the cost of occasionally asking for confirmation.

A decision order that holds humans accountable for the consequential calls:

1. **Compute a proposed bump from structured inputs.** Take the highest bump implied by Conventional Commits, declared changelog categories, or fragment metadata. Treat this as a proposal, not a decision.
2. **Honor explicit overrides.** A maintainer's manual release plan or an explicit `semver-*` label always wins over the computed proposal. The human stated intent; respect it.
3. **Stop at every breaking change.** Never let automation tag a new MAJOR (or cross `0.x` → `1.0.0`) without a human approving it. A breaking change is exactly the case where the cost of being wrong is highest, so it is exactly where a human belongs. release-please's "release PR" model is a good pattern here: the tool proposes the version and changelog in a PR, and merging the PR is the human approval step.
4. **Default down, not up, when ambiguous.** If the inputs disagree or are missing — no Conventional Commit type, an entry in a catch-all section, an unlabeled PR — propose the *smaller* bump and flag it for review rather than guessing larger. A version that is too low is a missing feature note; a version that is too high erodes the meaning of the number.
5. **Refuse to invent a version the ecosystem forbids.** Apply package-manager constraints (pre-1.0 semantics, monorepo independent versioning, registry rules) as a final filter and fail loudly if the computed version violates them, rather than coercing it.

The throughline: **machines classify, humans decide the consequential cases.** Automate patch and minor bumps that come from clean structured signals; require explicit human sign-off for major bumps, the first `1.0.0`, and any case where the inputs conflict. This keeps the speed benefit of automation for the common path while keeping a person in the loop exactly where mistakes are expensive.

## Related Articles

- [Semantic Versioning and Changelog Workflows]({filename}semantic-versioning-changelog-workflows.md)
- [Change Taxonomies Across Tools]({filename}change-taxonomies-across-tools.md)
- [Version Validation in Release Pipelines]({filename}version-validation-release-pipelines.md)
- [release-please]({filename}release-please.md)
- [semantic-release]({filename}semantic-release.md)
