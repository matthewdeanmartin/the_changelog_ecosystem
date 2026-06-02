FROM node:20-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# semantic-release and its changelog plugin
RUN npm install -g semantic-release@24.2.5 \
    @semantic-release/changelog@6.0.3 \
    @semantic-release/git@10.0.1 \
    @semantic-release/npm@12.0.1 \
    @semantic-release/exec@6.0.3

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
