OTEL_CI_CONF := "build/ci/.otel-collector-config.yaml"

## Runs otel-collector
.PHONY: otel-ci
otel-ci:
	@echo "Starting OpenTelemetry Collector..."
	@docker run \
		-v $(PWD)/$(OTEL_CI_CONF):/etc/otelcol-contrib/config.yaml \
		-p 1888:1888  \
		-p 8888:8888 \
		-p 8889:8889 \
		-p 13133:13133 \
		-p 4317:4317 \
		-p 4318:4318 \
		otel/opentelemetry-collector-contrib
