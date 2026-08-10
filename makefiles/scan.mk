# Scan: generic vulnerability scanning interface, implemented with trivy.
#
# Pass --cache-dir inside the mounted workspace: the container user has no
# passwd entry, so trivy's default cache path is unwritable.
#   make op-scan TRIVY_ARGS="fs --cache-dir build/ci/.cache/trivy ."

##v full trivy subcommand, e.g. "fs ." or "image --input img.tar"
TRIVY_ARGS ?=

# aquasec/trivy:latest, 2026-08-10
OP_TRIVY_SHA := sha256:7cced7cae583819fc7806d4cbc0dbbc7cad18b99f7d3e235192e6da8c091045c
OP_TRIVY_CMD := docker run --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD)/$(SRC)/:/opt/$(SRC) \
		-w /opt/$(SRC) \
		aquasec/trivy@$(OP_TRIVY_SHA)

##@ Scan

.PHONY: op-scan
##p TRIVY_ARGS
op-scan: ## Scan with trivy. Pass the subcommand via TRIVY_ARGS.
	@echo "Security Scanning..."
	@$(OP_TRIVY_CMD) $(TRIVY_ARGS)
