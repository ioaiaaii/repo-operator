# Variables
OPENAPI_GENERATOR_REPO := openapitools/openapi-generator-cli
OPENAPI_GENERATOR_SHA := sha256:bb32f5f0c9f5bdbb7b00959e8009de0230aedc200662701f05fc244c36f967ba
OPENAPI_FILE ?= ""
OPENAPI_DOCS_PATH ?= ""

OPENAPI_GENERATOR_CMD := docker run --rm \
    -v ${PWD}:/local \
	-u $(id -u):$(id -g)\
	${OPENAPI_GENERATOR_REPO}@${OPENAPI_GENERATOR_SHA} generate \
    -i /local/${OPENAPI_FILE} \
    -g markdown \
    -o /local/${OPENAPI_DOCS_PATH}


## Generate OpenAPI documentation as Markdown
generate-docs:
	@$(OPENAPI_GENERATOR_CMD)
