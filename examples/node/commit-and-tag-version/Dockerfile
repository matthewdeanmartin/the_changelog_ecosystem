FROM node:20-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# commit-and-tag-version is the actively maintained fork of standard-version
RUN npm install -g commit-and-tag-version@12.5.0

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
