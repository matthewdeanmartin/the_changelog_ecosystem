# release-please Makefile — same target names as every other tool dir.
# Set TOOL per directory; it namespaces the image so parallel builds never collide.
TOOL := release-please

IMAGE := cle-exp-$(TOOL)

.PHONY: help build run shell clean experiment

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

# ---- host side (needs only Docker) ------------------------------------------
build: ## Build the image for this tool
	docker build -t $(IMAGE) .

# NOTE: --network none is intentional. This is the LOCAL-ONLY subset experiment;
# running offline forces release-please's mandatory GitHub-API dependency to fail
# at a precise, reproducible point — that failure IS the headline finding. The
# local stages (repo setup, config, changelog inputs) all complete first.
run: build ## Run the full experiment OFFLINE and stream the transcript
	mkdir -p out
	docker run --rm --network none -v "$(CURDIR)/out:/work/out" $(IMAGE) ./run_experiment.sh

shell: build ## Interactive shell in the container for debugging (network enabled)
	docker run --rm -it -v "$(CURDIR)/out:/work/out" $(IMAGE) bash

clean: ## Remove the image and local out/
	-docker rmi $(IMAGE)
	-rm -rf out

# ---- in-container side (invoked by run_experiment.sh) -----------------------
experiment: ## (inside container) run the life cycle, write artifacts to out/
	./run_experiment.sh
