# changelog-rs experiment image.
# The `changelog` crate (last released 2020-03-02) requires cargo install.
# We document the install process and what happens when you try to use it.
FROM rust:1.87-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git make ca-certificates curl tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review -------------------------------------------
# changelog crate: last release 2020-03-02 (version 0.3.4).
# This install may fail or produce warnings due to edition/dependency issues.
RUN cargo install --locked changelog --version 0.3.4 2>&1 || \
    cargo install changelog --version 0.3.4 2>&1 || \
    echo "WARNING: changelog install failed (expected for an archived 2020 crate)"
# -----------------------------------------------------------------------------

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
