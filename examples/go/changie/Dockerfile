FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/miniscruff/changie/releases/download/v1.24.0/changie_1.24.0_linux_amd64.tar.gz \
    | tar -xz -C /usr/local/bin changie \
    && chmod +x /usr/local/bin/changie

WORKDIR /work

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
