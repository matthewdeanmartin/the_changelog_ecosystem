# release-plz experiment image.
# release-plz update/generate-completions requires cargo; use rust:1.87-slim.
FROM rust:1.87-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git make ca-certificates curl tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install release-plz (pre-built binary) -----------------------------------
ARG RELEASE_PLZ_VERSION=0.3.158
RUN curl -fsSL \
    "https://github.com/release-plz/release-plz/releases/download/release-plz-v${RELEASE_PLZ_VERSION}/release-plz-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/local/bin release-plz
# ------------------------------------------------------------------------------

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
