# release-please experiment image (LOCAL-ONLY SUBSET).
#
# release-please is fundamentally a GitHub-API tool: every subcommand requires
# --token and --repo-url and talks to api.github.com. There is NO fully offline
# mode. This experiment deliberately drives the *local-only subset* — repo +
# config setup and the `release-pr --local --dry-run` path — and CAPTURES THE
# EXACT POINT where the tool insists on the GitHub API, as the headline finding.
#
# We install at build time (network available), then `make run` executes the
# driver with `--network none` so the GitHub dependency surfaces as a hard,
# reproducible failure rather than a flaky live API call.
FROM node:20-slim

# git: release-please reads the local git history (conventional commits + tags).
# python3: the tip-calculator fixture app runs and prints at each stage.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# --- install the tool under review (PINNED) ----------------------------------
RUN npm install -g release-please@17.7.0
# -----------------------------------------------------------------------------

# Bake the app + scenario seeds into the image. /work is recreated as a fresh git
# repo by run_experiment.sh at runtime, so nothing here carries host git state.
COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

# out/ is the only mounted dir at runtime (see Makefile); artifacts copied there.
RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
