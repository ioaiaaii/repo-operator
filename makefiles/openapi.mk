# OpenAPI: generate Markdown documentation from an OpenAPI spec.

##v path to the spec, required by op-openapi-docs
OPENAPI_FILE      ?=
##v output directory, required by op-openapi-docs
OPENAPI_DOCS_PATH ?=

# openapitools/openapi-generator-cli:latest, 2026-08-10
OP_OPENAPI_SHA := sha256:f7fda4a6f2b9677e73950f97b67db626c36444783f38c34065c2f872523ec0ab
OP_OPENAPI_CMD := docker run --rm \
		-v $(PWD):/local \
		-u $(shell id -u):$(shell id -g) \
		openapitools/openapi-generator-cli@$(OP_OPENAPI_SHA) generate \
		-i /local/$(OPENAPI_FILE) \
		-g markdown \
		-o /local/$(OPENAPI_DOCS_PATH)

##@ OpenAPI

.PHONY: op-openapi-docs
##p OPENAPI_FILE* OPENAPI_DOCS_PATH*
op-openapi-docs: ## Generate OpenAPI documentation as Markdown.
	$(call require,OPENAPI_FILE)
	$(call require,OPENAPI_DOCS_PATH)
	@$(OP_OPENAPI_CMD)
