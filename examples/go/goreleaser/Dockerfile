FROM golang:1.22-bullseye

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/goreleaser/goreleaser/releases/download/v2.16.0/goreleaser_Linux_x86_64.tar.gz \
    | tar -xz -C /usr/local/bin goreleaser \
    && chmod +x /usr/local/bin/goreleaser

WORKDIR /work

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
