TRIVY_SHA := sha256:1c78ed1ef824ab8bb05b04359d186e4c1229d0b3e67005faacb54a7d71974f73
TRIVY_CMD := docker run --rm\
		-u $(shell id -u):$(shell id -g)\
		-v $(PWD)/${SRC}/:/opt/${SRC}\
		-w /opt/${SRC}\
		aquasec/trivy@${TRIVY_SHA}
TRIVY_ARGS ?=

##@ Repo Operator: Security

# Pass --cache-dir inside the mounted workspace: the container user has no
# passwd entry, so trivy's default cache path is unwritable.
#   make trivy-scan TRIVY_ARGS="fs --cache-dir build/ci/.cache/trivy ."
.PHONY: trivy-scan
trivy-scan: ## Scan with Trivy. Pass the subcommand via TRIVY_ARGS.
	@echo "Security Scanning..."
	@$(TRIVY_CMD) ${TRIVY_ARGS}
