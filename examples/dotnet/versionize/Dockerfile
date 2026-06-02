# versionize experiment image.
# Pinned base + pinned tool so `make run` is reproducible on any machine with Docker.
FROM mcr.microsoft.com/dotnet/sdk:8.0

# git is required: the experiment builds a real repo with commits/tags in /work.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install versionize as a global dotnet tool and add it to PATH.
RUN dotnet tool install -g versionize --version 2.5.0
ENV PATH="${PATH}:/root/.dotnet/tools"

WORKDIR /work

# Bake the app + scenario seeds into the image. /work is recreated as a fresh git
# repo by run_experiment.sh at runtime, so nothing here carries host git state.
COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

# out/ is the only mounted dir at runtime (see Makefile); artifacts are copied there.
RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
