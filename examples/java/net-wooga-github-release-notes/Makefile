TOOL := net-wooga-github-release-notes
IMAGE := cle-exp-$(TOOL)

.PHONY: help build run shell clean

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the image
	docker build -t $(IMAGE) .

run: build ## Run the full experiment
	mkdir -p out
	docker run --rm -v "$(CURDIR)/out:/work/out" $(IMAGE) ./run_experiment.sh

shell: build ## Interactive shell for debugging
	docker run --rm -it -v "$(CURDIR)/out:/work/out" $(IMAGE) bash

clean: ## Remove image and out/
	-docker rmi $(IMAGE)
	-rm -rf out
