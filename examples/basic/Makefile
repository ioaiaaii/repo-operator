# Basic example. In a real repository, OPERATOR_PATH points at the submodule, e.g.
# build/repo-operator.

OPERATOR_PATH := ../..

include $(OPERATOR_PATH)/makefiles/all.mk

.DEFAULT_GOAL := help

# The one-line pattern for a bare `make help` in your own namespace.
help: op-help

##@ Demo

.PHONY: demo-image-build
demo-image-build: ## Build the demo image through the shared interface.
	@$(MAKE) --no-print-directory op-image-build IMAGE_NAME=demo-app

.PHONY: demo-scan
demo-scan: ## Scan the source tree.
	@$(MAKE) --no-print-directory op-scan TRIVY_ARGS="fs ."
