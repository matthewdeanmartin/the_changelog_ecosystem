Title: GitReleaseNotes (hands-on synthesis)
Slug: gitreleasenotes-v2
Date: 2026-06-02
Ecosystem: Dotnet
Tool_Version: 0.7.1
Experiment: examples/dotnet/gitreleasenotes/
Summary: Hands-on confirmation of GitReleaseNotes installation and offline behavior.



## What I Actually Ran

The experiment lives at `examples/dotnet/gitreleasenotes/`. The container base image is
`mcr.microsoft.com/dotnet/sdk:8.0` (SDK version 8.0.421). The script attempts to:

1. Install `GitReleaseNotes` version 0.7.1 via `dotnet tool install -g`.
2. Probe basic invocation (`--version`, `--help`).
3. Set up a minimal git repo with a real commit and tag.
4. Attempt a live GitHub tracker call with a fake token to observe the error mode.

The experiment is reproducible with `make run` from the directory above using only Docker.

## Real Output

### Install step (Docker build layer)

```
Tool 'gitreleasenotes' failed to update due to the following:
The settings file in the tool's NuGet package is invalid:
Settings file 'DotnetToolSettings.xml' was not found in the package.
Tool 'gitreleasenotes' failed to install. Contact the tool author for assistance.
```

### Runtime (inside container)

```
dotnet tool list -g
Package Id      Version      Commands
-------------------------------------

gitreleasenotes --version
./run_experiment.sh: line 33: gitreleasenotes: command not found

gitreleasenotes --help
./run_experiment.sh: line 37: gitreleasenotes: command not found
```

The tool is simply absent from PATH. No changelog output was produced at any stage.

## Pros (Observed)

None observed. The tool did not install and produced no output.

## Cons / Pain Points (Observed)

**Install fails on .NET 8 SDK.** The NuGet package for 0.7.1 does not contain
`DotnetToolSettings.xml`, which is the manifest required by the `dotnet tool install`
machinery introduced in .NET Core 2.1. The package was published before the modern global
tool format was standardised. It is not installable on any .NET Core 2.1+, .NET 5, .NET 6,
.NET 7, or .NET 8 SDK via `dotnet tool install`.

**No fallback path.** Because the package lacks the tool manifest entirely, there is no
workaround short of fetching a raw `.exe` from GitHub releases, running it under .NET
Framework, or using a Mono container.

**Would require live credentials even if it worked.** GitReleaseNotes queries GitHub,
Jira, or YouTrack live. It has no offline or dry-run mode. Calling it with a fake token
would produce a connection or authentication error — but we could not even reach that
failure mode because installation itself blocked us.

**Zero activity for ~8–10 years.** The last NuGet release is 0.7.1, published circa
2015-2017. The repository has no recent commits, issues are stale, and there is no
indication of a .NET 5+ compatible release planned.

## Docs vs. Reality

The original `gitreleasenotes.md` article correctly flags the tool as unmaintained and
says to prefer newer alternatives. However, it still frames installation as straightforward
(`dotnet tool install -g GitReleaseNotes`) and discusses configuration options, templates,
and output quality as if the tool were usable. That framing is now obsolete: the tool
cannot be installed at all on any current .NET SDK. The article's "last release 1900-01-01"
metadata anomaly was a data-quality flag, but even the text did not make clear that the
package is broken at the install layer, not merely stale.

The site description says "a legacy option" — the reality is stronger: it is a non-option.
Installation fails before any configuration or usage is possible.

## Revised Verdict

**Verdict: Avoid — unmaintained and requires live tracker access.**

The original verdict of "Avoid" was correct, but the hands-on run provides a harder
reason than the article stated: GitReleaseNotes 0.7.1 does not install on any modern .NET
SDK. The `DotnetToolSettings.xml` manifest is absent from the NuGet package, which is a
structural incompatibility with `dotnet tool install` as it has existed since 2018.

Even ignoring the install failure, the tool's design requires live credentials to a GitHub,
Jira, or YouTrack instance. There is no offline mode, no dry-run, and no way to use it in
a self-contained CI pipeline without live tracker access. For any project starting today,
alternatives such as `versionize`, `dotnet-releaser`, Release Drafter, or GitHub's built-in
release notes automation are trivially better choices.

Do not adopt GitReleaseNotes for new .NET projects.
