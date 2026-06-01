Title: reno
Date: 2026-05-31
Slug: reno
Ecosystem: Python
Tags: news-fragments, python, python-cli-sphinx, release-notes, sphinx, git-tags, branch-aware, ci-cd
Tool_URL: https://pypi.org/project/reno/
Tool_Version: 4.1.0
Tool_Status: active
Summary: OpenStack release-notes manager that stores note files and associates them with releases based on git tags.



## Overview

`reno` is a release-notes system from the OpenStack world. It stores structured YAML notes in the repository, associates them with releases by scanning git history and tags, and renders reports that can be included in Sphinx documentation.

This is a more formal tool than Towncrier or Scriv. It is designed for large, branch-aware projects where release notes are part of the documentation site and where stable branches, backports, and release trains matter.

## Installation

```bash
pip install reno
# or with uv:
uv add reno
```

## What It Does

- Creates note files with unique names under `releasenotes/notes` using `reno new`.
- Uses YAML sections such as `features`, `issues`, `upgrade`, `deprecations`, `security`, `fixes`, and `other`.
- Scans git tags and branch history to decide which notes belong to which release.
- Generates release-note reports with `reno report`, suitable for direct inspection or Sphinx inclusion.
- Provides `reno lint` for CI checks and `reno semver-next` to infer a next semantic version from note categories.

## Configuration

Reno can run with defaults, but larger projects normally add `reno.yaml` in the repository root or `config.yaml` in the release notes directory. The configuration controls branch scanning, earliest versions, section names, note templates, and how stable branches are interpreted.

```yaml
---
branch: master
earliest_version: 1.0.0
collapse_pre_releases: true
stop_at_branch_base: true
sections:
  - [features, New Features]
  - [upgrade, Upgrade Notes]
  - [security, Security Issues]
  - [fixes, Bug Fixes]
template: |
  ---
  features:
    - |
      List new features here, or remove this section.
```

First-run setup is heavier than the other Python tools in this survey. The defaults are useful, but teams get the most value when they understand the branch and tag model, choose sections deliberately, and wire report generation into docs or CI.

## Output Quality

Reno produces structured release notes rather than a simple chronological changelog. A generated report can read like this:

```rst
1.4.0
=====

New Features
------------

* Added token-based authentication for the public API.

Upgrade Notes
-------------

* Operators must run the database migration before starting workers.

Bug Fixes
---------

* Fixed duplicate release-note entries when a stable branch was merged forward.
```

The output is excellent for documentation sites and operations-heavy releases. It can feel too formal for a small package changelog, especially if the project only needs a Markdown file.

## Ecosystem Fit

Reno is deeply Python-native in the OpenStack/Sphinx sense: it works well with `tox`, documentation builds, and repositories that already treat release notes as part of their docs. Its note files use YAML with reStructuredText content, which makes sense in Sphinx projects but may be less natural for Markdown-first teams.

The strongest fit is a large Python service, library family, or platform project with stable branches and support windows. For a small PyPI package, Scriv or Towncrier will usually be easier to adopt.

## Maintenance Status

- Latest version: **4.1.0**
- Last release: **2024-03-04**
- GitHub stars: **62**
- Appears actively maintained.
- Repository: <a href="https://docs.openstack.org/reno/latest/" target="_blank" rel="noopener noreferrer">https://docs.openstack.org/reno/latest/</a>

Reno remains documented and maintained in the OpenStack ecosystem, with current docs for note creation, report generation, linting, branch-aware scanning, and Sphinx integration.

## Verdict

**Verdict: Situational**

Reno is excellent when release notes are part of a serious documentation and branch-management process. It is probably too much machinery for ordinary Python packages, but for OpenStack-style projects, long-lived stable branches, or release notes that need to land in Sphinx, it solves a problem the lighter tools do not try to solve.
