# GitReleaseManager experiment image.
# Pinned base + pinned tool so `make run` is reproducible on any machine with Docker.
FROM mcr.microsoft.com/dotnet/sdk:8.0

# git is required: the experiment builds a real repo with commits/tags in /work.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review -------------------------------------------
# NuGet package ID is 'gitreleasemanager.tool' (not 'GitReleaseManager').
# The installed binary is 'dotnet-gitreleasemanager'.
RUN dotnet tool install -g gitreleasemanager.tool --version 0.20.0
# Make the dotnet global tools available on PATH.
ENV PATH="${PATH}:/root/.dotnet/tools"
# -----------------------------------------------------------------------------

# Bake the app into the image. /work/app is used as the scenario repo.
COPY app/ ./app/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

# out/ is the only mounted dir at runtime (see Makefile); artifacts are copied there.
RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
