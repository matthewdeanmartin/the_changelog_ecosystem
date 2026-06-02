TOOL := changelog-rs

IMAGE := cle-exp-$(TOOL)

.PHONY: help build run shell clean experiment

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the image for this tool
	docker build -t $(IMAGE) .

run: build ## Run the full experiment and stream the transcript
	mkdir -p out
	docker run --rm -v "$(CURDIR)/out:/work/out" $(IMAGE) ./run_experiment.sh

shell: build ## Interactive shell in the container for debugging
	docker run --rm -it -v "$(CURDIR)/out:/work/out" $(IMAGE) bash

clean: ## Remove the image and local out/
	-docker rmi $(IMAGE)
	-rm -rf out

experiment: ## (inside container) run the life cycle
	./run_experiment.sh
