IMAGE_NAME ?= bash-template-bats

.DEFAULT_GOAL := help

.PHONY: help test-image test test-verbose test-shell clean-test-image

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

test-image: ## Build the Arch test image
	docker build -t $(IMAGE_NAME) .

test: test-image ## Run bats test suite
	docker run --rm -v "$(CURDIR):/work" -w /work $(IMAGE_NAME) bats tests

test-verbose: test-image ## Run bats with test names
	docker run --rm -v "$(CURDIR):/work" -w /work $(IMAGE_NAME) bats -t tests

test-shell: test-image ## Open an interactive container shell
	docker run --rm -it -v "$(CURDIR):/work" -w /work $(IMAGE_NAME) bash

clean-test-image: ## Remove the local test image
	docker rmi $(IMAGE_NAME)
