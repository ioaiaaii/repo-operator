TRIVY_SHA := sha256:26245f364b6f5d223003dc344ec1eb5eb8439052bfecb31d79aeba0c74344b3a
TRIVY_CMD := docker run --rm\
		-u $(id -u):$(id -g)\
		-v $(PWD)/${SRC}/:/opt/${SRC}\
		-w /opt/${SRC}\
		aquasec/trivy@${TRIVY_SHA}
TRIVY_ARGS ?= ""

## Trivy Security Scanner
trivy-scan:
	@echo "Security Scanning...\n"
	@$(TRIVY_CMD) ${TRIVY_ARGS}
