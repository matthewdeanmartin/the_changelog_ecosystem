# logchange experiment image.
#
# logchange ships an official GraalVM-native binary inside an Alpine image
# (logchange/logchange). We start FROM it so the tool under test is the real
# published artifact, then add git (the experiment builds a repo in /work) and
# python3 (the tip-calculator fixture app runs and prints at each stage).
#
# Pin the tag so `make run` is reproducible on any machine.
FROM logchange/logchange:1.19.15

# git: the experiment builds a real repo with commits/tags in /work.
# python3: the tip-calculator app must run and print at each stage.
# bash/make: the driver script and Makefile contract.
RUN apk add --no-cache git python3 bash make ca-certificates

WORKDIR /work

# logchange is already on PATH at /usr/local/bin/logchange (native binary), so
# there is nothing else to install — that is the point of FROM-the-tool.

# Bake the app + scenario seeds into the image. /work is recreated as a fresh git
# repo by run_experiment.sh at runtime, so nothing here carries host git state.
COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

# out/ is the only mounted dir at runtime (see Makefile); artifacts copied there.
RUN mkdir -p /work/out

# The base image's CMD is logchange's own help; override so the container's
# default action is our experiment driver.
CMD ["./run_experiment.sh"]
