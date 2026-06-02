# cargo-dist experiment image.
# cargo-dist init and plan require cargo; use rust:1.87-slim.
FROM rust:1.87-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git make ca-certificates curl tar xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install cargo-dist (pre-built binary) ------------------------------------
# cargo-dist binary is named 'dist' inside the tarball.
ARG CARGO_DIST_VERSION=0.32.0
RUN curl -fsSL \
    "https://github.com/axodotdev/cargo-dist/releases/download/v${CARGO_DIST_VERSION}/cargo-dist-x86_64-unknown-linux-musl.tar.xz" \
    | tar -xJ --strip-components=1 -C /usr/local/bin \
      "cargo-dist-x86_64-unknown-linux-musl/dist" \
    && mv /usr/local/bin/dist /usr/local/bin/cargo-dist
# ------------------------------------------------------------------------------

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
