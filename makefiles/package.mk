HADOLINT_SHA := sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d
DIVE_SHA := sha256:f1886e6c32c094fc41a623c1989f5cb3e48aa766da5f0be233f911fc1d85ce10

# --- Inputs -----------------------------------------------------------------
# IMAGE_NAME is required by every target here. The rest have defaults that suit
# a single-image repository; a repo shipping several overrides them per image.

# Image name, and the directory holding its Dockerfile.
IMAGE_NAME ?=

# Registry and namespace, e.g. ghcr.io/owner. Required to push.
IMAGE_REPO ?=

# Docker build context. Deliberately not $(SRC): that is the Go source root,
# which coincides with the context only when a repo builds one image from it.
IMAGE_CONTEXT ?= .

IMAGE_DOCKERFILE ?= $(BUILD_PATH)/package/$(IMAGE_NAME)/Dockerfile

# Derived from VERSION, reduced to a DNS-safe tag.
IMAGE_TAG := $(shell echo $(VERSION) | $(UBUNTU_CMD) awk '{gsub("[^.0-9a-zA-Z]","-");print $$0}' )

# Fully qualified reference. Registry-prefixed only when IMAGE_REPO is set.
IMAGE_REF ?= $(if $(strip $(IMAGE_REPO)),$(IMAGE_REPO)/,)$(IMAGE_NAME):$(IMAGE_TAG)

# --- Build mode --------------------------------------------------------------
# local   host architecture, loaded into the daemon for `docker run`/`kind load`
# publish multi-arch, attested, pushed by digest
#
#   make image-build IMAGE_NAME=x                                 # local
#   make image-build IMAGE_NAME=x IMAGE_REPO=y IMAGE_MODE=publish # publish
#
# One knob rather than three, because the flags are not independent: --load
# rejects a multi-platform manifest, and attestations only exist in a registry.
# Provenance is disabled explicitly for local, not left unset, since buildx
# attaches it otherwise and turns a single-platform image into a manifest list.
#
# publish needs a docker-container builder with QEMU for the foreign
# architecture: `docker buildx create --use`, or docker/setup-buildx-action
# with docker/setup-qemu-action in CI.
IMAGE_MODE ?= local

ifeq ($(IMAGE_MODE),publish)
IMAGE_OUTPUT    ?= --push
IMAGE_PLATFORMS ?= linux/amd64,linux/arm64
IMAGE_ATTEST    ?= --attest type=provenance,mode=max --attest type=sbom
else
IMAGE_OUTPUT    ?= --load
IMAGE_PLATFORMS ?=
IMAGE_ATTEST    ?= --provenance=false
endif

# Records the pushed digest, which is what promote-by-digest reads.
IMAGE_METADATA ?= $(BUILD_PATH)/ci/$(IMAGE_NAME)-metadata.json

DIVE_CI_CONF := "build/ci/.dive-ci.yaml"

##@ Repo Operator: Package

.PHONY: image-lint
image-lint: ## Lint a Dockerfile with hadolint. Requires IMAGE_NAME.
	$(call require,IMAGE_NAME)
	@echo "Dockerfile linting..."
	@docker run --rm -i -e HADOLINT_VERBOSE=1 -e HADOLINT_FORMAT=json hadolint/hadolint@${HADOLINT_SHA} < $(IMAGE_DOCKERFILE)

# Multi-platform and attestations need a docker-container builder:
# `docker buildx create --use` locally, docker/setup-buildx-action in CI.
.PHONY: image-build
image-build: ## Build an image. Requires IMAGE_NAME; see IMAGE_OUTPUT to publish.
	$(call require,IMAGE_NAME)
	@echo "Building $(IMAGE_REF)..."
	@mkdir -p $(dir $(IMAGE_METADATA))
	@docker buildx build \
		$(if $(strip $(IMAGE_PLATFORMS)),--platform $(IMAGE_PLATFORMS)) \
		--tag $(IMAGE_REF) \
		--build-arg LD_FLAGS="$(LD_FLAGS)" \
		--build-arg REVISION="$(COMMIT)" \
		$(IMAGE_ATTEST) \
		--metadata-file $(IMAGE_METADATA) \
		$(IMAGE_OUTPUT) \
		-f $(IMAGE_DOCKERFILE) $(IMAGE_CONTEXT)

.PHONY: image-digest
image-digest: ## Print the digest of the last build. Requires IMAGE_NAME.
	$(call require,IMAGE_NAME)
	@jq -r '."containerimage.digest"' $(IMAGE_METADATA)

.PHONY: image-run
image-run: ## Run the built image, detecting its exposed port. Requires IMAGE_NAME.
	$(call require,IMAGE_NAME)
	{ \
		port=$$(docker inspect --format='{{range $$key, $$value := .Config.ExposedPorts }}{{$$key}}{{end}}' ${IMAGE_NAME}:${IMAGE_TAG} | sed 's/\/.*//') ;\
		if [ -z "$$(docker network ls --filter name=^${MODULE}$$ --format '{{.Name}}')" ]; then \
			docker network create ${MODULE}; \
		fi ;\
		if [ "$$(docker ps -a --filter name=^${IMAGE_NAME}$$ --format '{{.Names}}')" = "${IMAGE_NAME}" ]; then \
			docker stop ${IMAGE_NAME} && docker rm ${IMAGE_NAME}; \
		fi ;\
		docker run -d --name $(IMAGE_NAME) --network ${MODULE} -p $${port}:$${port} $(IMAGE_NAME):$(IMAGE_TAG); \
	}

.PHONY: image-inspect
image-inspect: ## Inspect image layers with dive. Requires IMAGE_NAME.
	$(call require,IMAGE_NAME)
	@docker run --rm\
		-v /var/run/docker.sock:/var/run/docker.sock  \
		-v $(PWD)/$(DIVE_CI_CONF):/opt/.dive-ci.yaml \
		wagoodman/dive@${DIVE_SHA} ${IMAGE_REPO}${IMAGE_NAME}:${IMAGE_TAG} --ci --ci-config /opt/.dive-ci.yaml
