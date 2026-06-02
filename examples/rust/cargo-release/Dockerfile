# cargo-release experiment image.
# Uses rust:1.87-slim so cargo is available (cargo-release calls it for preflight).
# cargo-release and git-cliff are installed from pre-built binaries (no compile).
FROM rust:1.87-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git make ca-certificates curl tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review: cargo-release (pre-built binary) ---------
ARG CARGO_RELEASE_VERSION=1.1.2
RUN curl -fsSL \
    "https://github.com/crate-ci/cargo-release/releases/download/v${CARGO_RELEASE_VERSION}/cargo-release-v${CARGO_RELEASE_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/local/bin ./cargo-release
# Also install git-cliff so the pre-release hook works.
ARG GIT_CLIFF_VERSION=2.13.1
RUN curl -fsSL \
    "https://github.com/orhun/git-cliff/releases/download/v${GIT_CLIFF_VERSION}/git-cliff-${GIT_CLIFF_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz --strip-components=1 -C /usr/local/bin \
      "git-cliff-${GIT_CLIFF_VERSION}/git-cliff"
# -----------------------------------------------------------------------------

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
