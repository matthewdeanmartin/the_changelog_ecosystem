# git-cliff experiment image.
# Stage 1: compile the tip-calculator app (only needed once at build time).
# Stage 2: runtime image with git-cliff binary (pre-built) + compiled app.
# No Rust compiler needed at experiment run time.

# ---- build stage: compile the Rust app --------------------------------------
FROM rust:1.87-slim AS builder
WORKDIR /build
COPY app/ .
RUN cargo build --release 2>&1

# ---- runtime stage: debian + git-cliff binary + compiled app ----------------
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git make ca-certificates curl tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review (pre-built binary, no cargo needed) -------
ARG GIT_CLIFF_VERSION=2.13.1
RUN curl -fsSL \
    "https://github.com/orhun/git-cliff/releases/download/v${GIT_CLIFF_VERSION}/git-cliff-${GIT_CLIFF_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz --strip-components=1 -C /usr/local/bin \
      "git-cliff-${GIT_CLIFF_VERSION}/git-cliff"
# -----------------------------------------------------------------------------

# Copy the compiled app binary so run_experiment.sh can run it.
COPY --from=builder /build/target/release/tipcalc /work/tipcalc

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
