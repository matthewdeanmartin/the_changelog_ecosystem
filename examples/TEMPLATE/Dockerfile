# TEMPLATE Dockerfile — copy and fill in the TOOL install step.
#
# Pin the base image. Keep the image small and self-contained: the whole point is
# that `make run` works on any machine with only Docker installed.
FROM python:3.12-slim

# git is required: the experiment builds a real repo with commits/tags in /work.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review -------------------------------------------
# Replace this line per tool, and PIN the version. Examples:
#   RUN pip install --no-cache-dir "towncrier==24.8.0"
#   RUN pip install --no-cache-dir "scriv==1.5.1"
#   RUN pip install --no-cache-dir "reno==4.1.0"
#   RUN pip install --no-cache-dir "keepachangelog==2.0.0"
RUN pip install --no-cache-dir "REPLACE_ME==0.0.0"
# -----------------------------------------------------------------------------

# Bake the app + scenario seeds into the image. /work is recreated as a fresh git
# repo by run_experiment.sh at runtime, so nothing here carries host git state.
COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

# out/ is the only mounted dir at runtime (see Makefile); artifacts are copied there.
RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
