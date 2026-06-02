FROM node:20-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# standard-version is unmaintained (last release 2022); pinned to final version.
RUN npm install -g standard-version@9.5.0

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
