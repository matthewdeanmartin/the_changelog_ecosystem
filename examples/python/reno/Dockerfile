# reno experiment image.
FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review -------------------------------------------
RUN pip install --no-cache-dir "reno==4.1.0"
# -----------------------------------------------------------------------------

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
