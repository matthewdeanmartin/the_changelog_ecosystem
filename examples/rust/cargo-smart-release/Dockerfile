# cargo-smart-release experiment image.
# No pre-built binary available — must use cargo install.
# This build takes ~5-10 minutes; the layer is cached on reruns.
FROM rust:1.89-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git make ca-certificates curl tar \
       pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review -------------------------------------------
# cargo-smart-release has no pre-built binary releases; cargo install is required.
# Pinned to the latest release version.
RUN cargo install --locked cargo-smart-release --version 0.21.11 2>&1
# -----------------------------------------------------------------------------

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
