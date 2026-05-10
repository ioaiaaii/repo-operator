TRIVY_SHA := sha256:1c78ed1ef824ab8bb05b04359d186e4c1229d0b3e67005faacb54a7d71974f73
TRIVY_CMD := docker run --rm\
		-u $(shell id -u):$(shell id -g)\
		-v $(PWD)/${SRC}/:/opt/${SRC}\
		-w /opt/${SRC}\
		aquasec/trivy@${TRIVY_SHA}
TRIVY_ARGS ?= ""

## Trivy Security Scanner
trivy-scan:
	@echo "Security Scanning...\n"
	@$(TRIVY_CMD) ${TRIVY_ARGS}
