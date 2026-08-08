OTEL_COLLECTOR_SHA := sha256:c5918f78992ee73b0d6f0e599423ac5ec52dd5d9726733114d6eca53d5a32ed5
OTEL_CI_CONF := "build/ci/.otel-collector-config.yaml"

##@ Repo Operator: OpenTelemetry

.PHONY: otel-ci
otel-ci: ## Run an OpenTelemetry Collector locally.
	@echo "Starting OpenTelemetry Collector..."
	@docker run \
		-v $(PWD)/$(OTEL_CI_CONF):/etc/otelcol-contrib/config.yaml \
		-p 1888:1888  \
		-p 8888:8888 \
		-p 8889:8889 \
		-p 13133:13133 \
		-p 4317:4317 \
		-p 4318:4318 \
		otel/opentelemetry-collector-contrib@${OTEL_COLLECTOR_SHA}
