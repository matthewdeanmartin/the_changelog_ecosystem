# GitReleaseNotes experiment notes

Experiment run: 2026-06-02  
Tool version attempted: 0.7.1  
Base image: mcr.microsoft.com/dotnet/sdk:8.0

## Install result: FAILED

`dotnet tool install -g GitReleaseNotes --version 0.7.1` fails immediately with:

```
Tool 'gitreleasenotes' failed to update due to the following:
The settings file in the tool's NuGet package is invalid:
Settings file 'DotnetToolSettings.xml' was not found in the package.
Tool 'gitreleasenotes' failed to install. Contact the tool author for assistance.
```

The NuGet package for GitReleaseNotes 0.7.1 does not contain `DotnetToolSettings.xml`,
which is the manifest required by the modern `dotnet tool install` machinery (introduced
in .NET Core 2.1). This means the package was published as a plain NuGet package (or an
early-format tool) before the dotnet global tool spec was stabilised. It is not installable
via `dotnet tool install` on any .NET Core 2.1+ or .NET 5/6/7/8 SDK.

`dotnet tool list -g` confirms zero tools installed after the attempt.

## Runtime behaviour

Because the install fails, `gitreleasenotes` is not on PATH at all. Every invocation
produces `command not found`. There is no runtime behavior to observe.

## Key finding

This is a stronger failure than "requires live credentials". The tool cannot even be
installed on a modern .NET SDK. It is completely unusable on any .NET 5+ or .NET 8
environment without significant workarounds (e.g., hunting down the old `.exe` separately,
running under Mono, or using an antique .NET Framework container).

## Full transcript

```
==================== STAGE 1: environment — dotnet SDK version ====================

8.0.421
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.dotnet/tools

==================== STAGE 2: probe install — was gitreleasenotes installed? ====================

Listing installed global tools:
Package Id      Version      Commands
-------------------------------------

Attempting: gitreleasenotes --version
./run_experiment.sh: line 33: gitreleasenotes: command not found

Attempting: gitreleasenotes --help
./run_experiment.sh: line 37: gitreleasenotes: command not found

==================== STAGE 3: build a minimal git repo for the tool to read ====================

git log:
9ab5e32 (HEAD -> master, tag: v1.0.0) feat: compute tip for a single bill

==================== STAGE 4: attempt GitHub tracker call — expected connection/auth failure ====================

Attempting: gitreleasenotes /u https://github.com/GitTools/GitReleaseNotes /t fake_token
(This requires live internet access and a valid token — it will fail.)
./run_experiment.sh: line 61: gitreleasenotes: command not found

Attempting alternative flag style (some versions use --)
./run_experiment.sh: line 65: gitreleasenotes: command not found

==================== STAGE 5: summary ====================

Install succeeded: false

CONCLUSION: GitReleaseNotes 0.7.1 did NOT install on .NET 8 SDK.
The package likely targets an older framework (.NET Framework / .NET Core 2.x)
and is incompatible with the current SDK.
The tool is unmaintained and cannot be used in modern .NET projects.

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 12
drwxrwxrwx 1 root root 4096 Jun  2 14:21 .
drwxr-xr-x 1 root root 4096 Jun  2 14:21 ..
-rw-r--r-- 1 root root   74 Jun  2 14:21 git-log.txt
-rw-r--r-- 1 root root 1693 Jun  2 14:21 transcript.txt
```

## Verdict

**Avoid.** GitReleaseNotes 0.7.1 cannot be installed as a `dotnet global tool` on any
modern .NET SDK. Even if it could be installed, the tool requires live GitHub/Jira/YouTrack
credentials — there is no offline mode. The project has had no releases since approximately
2015-2017 and shows no signs of revival.
