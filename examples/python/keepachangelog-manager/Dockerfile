# keepachangelog-manager-fork experiment image.
# Using the FORK (matthewdeanmartin/keepachangelog-manager), not the archived original.
FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review -------------------------------------------
# The fork is published on PyPI as keepachangelog-manager-fork.
RUN pip install --no-cache-dir "keepachangelog-manager-fork==5.2.0"
# -----------------------------------------------------------------------------

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
