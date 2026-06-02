# gitreleasenotes experiment image.
# GitReleaseNotes 0.7.1 is unmaintained (last release ~2015-2017).
# The install step may fail on .NET 8 SDK due to framework incompatibility.
# We use `|| true` so a failed install does NOT abort the image build —
# the experiment script documents whichever outcome occurs.
FROM mcr.microsoft.com/dotnet/sdk:8.0

# git is required: the experiment builds a real repo with commits/tags in /work.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Attempt to install GitReleaseNotes as a global dotnet tool.
# This MAY fail because the package targets older framework versions.
# `|| true` keeps the build alive so we can document the failure.
RUN dotnet tool install -g GitReleaseNotes --version 0.7.1 || true
ENV PATH="${PATH}:/root/.dotnet/tools"

WORKDIR /work

# Bake the app into the image. /work is used as the git repo root at runtime.
COPY app/ ./app/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

# out/ is the only mounted dir at runtime (see Makefile); artifacts are copied there.
RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
