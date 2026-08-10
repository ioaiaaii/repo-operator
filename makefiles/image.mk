# Image: build, lint, inspect, and run container images with buildx.

# hadolint/hadolint:latest and wagoodman/dive:latest, 2026-08-10
OP_HADOLINT_SHA := sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d
OP_DIVE_SHA := sha256:f1886e6c32c094fc41a623c1989f5cb3e48aa766da5f0be233f911fc1d85ce10

##v image to operate on, required by every op-image-* target
IMAGE_NAME ?=
##v registry and namespace, e.g. ghcr.io/owner, required to push
IMAGE_REPO ?=

# Deliberately not $(SRC): that is the Go source root, which coincides with the
# context only when a repo builds one image from it.
##v docker build context
IMAGE_CONTEXT ?= .

##v Dockerfile location
IMAGE_DOCKERFILE ?= $(BUILD_PATH)/package/$(IMAGE_NAME)/Dockerfile

##v image tag (default: VERSION reduced to a DNS-safe tag)
IMAGE_TAG ?= $(shell echo $(VERSION) | tr -c 'a-zA-Z0-9.\n' '-')

##v full image reference, registry-prefixed only when IMAGE_REPO is set
IMAGE_REF ?= $(if $(strip $(IMAGE_REPO)),$(IMAGE_REPO)/,)$(IMAGE_NAME):$(IMAGE_TAG)

# --- Build mode --------------------------------------------------------------
# local   host architecture, loaded into the daemon for `docker run`/`kind load`
# publish multi-arch, attested, pushed by digest
#
#   make op-image-build IMAGE_NAME=x                                 # local
#   make op-image-build IMAGE_NAME=x IMAGE_REPO=y IMAGE_MODE=publish # publish
#
# One knob rather than three, because the flags are not independent: --load
# rejects a multi-platform manifest, and attestations only exist in a registry.
# Provenance is disabled explicitly for local, not left unset, since buildx
# attaches it otherwise and turns a single-platform image into a manifest list.
#
# publish needs a docker-container builder with QEMU for the foreign
# architecture: `docker buildx create --use`, or docker/setup-buildx-action
# with docker/setup-qemu-action in CI.
##v local loads into the daemon, publish pushes multi-arch with attestations
IMAGE_MODE ?= local

ifeq ($(IMAGE_MODE),publish)
IMAGE_OUTPUT    ?= --push
IMAGE_PLATFORMS ?= linux/amd64,linux/arm64
IMAGE_ATTEST    ?= --attest type=provenance,mode=max --attest type=sbom
else
##v buildx output flag (publish: --push)
IMAGE_OUTPUT    ?= --load
##v target platforms (publish: linux/amd64,linux/arm64)
IMAGE_PLATFORMS ?=
##v attestation flags (publish: provenance and sbom)
IMAGE_ATTEST    ?= --provenance=false
endif

# Records the pushed digest, which is what promote-by-digest reads.
##v buildx metadata file, holds the pushed digest
IMAGE_METADATA ?= $(BUILD_PATH)/ci/$(IMAGE_NAME)-metadata.json

##v dive CI config for op-image-inspect
DIVE_CI_CONF ?= build/ci/.dive-ci.yaml

##@ Image

.PHONY: op-image-lint
##p IMAGE_NAME* IMAGE_DOCKERFILE
op-image-lint: ## Lint a Dockerfile with hadolint.
	$(call require,IMAGE_NAME)
	@echo "Dockerfile linting..."
	@docker run --rm -i -e HADOLINT_VERBOSE=1 -e HADOLINT_FORMAT=json hadolint/hadolint@$(OP_HADOLINT_SHA) < $(IMAGE_DOCKERFILE)

.PHONY: op-image-build
##p IMAGE_NAME* IMAGE_MODE IMAGE_REPO IMAGE_CONTEXT IMAGE_DOCKERFILE IMAGE_TAG LD_FLAGS
op-image-build: ## Build an image, or publish it with IMAGE_MODE=publish.
	$(call require,IMAGE_NAME)
	@echo "Building $(IMAGE_REF)..."
	@mkdir -p $(dir $(IMAGE_METADATA))
	@docker buildx build \
		$(if $(strip $(IMAGE_PLATFORMS)),--platform $(IMAGE_PLATFORMS)) \
		--tag $(IMAGE_REF) \
		--build-arg LD_FLAGS="$(LD_FLAGS)" \
		--build-arg REVISION="$(OP_COMMIT)" \
		$(IMAGE_ATTEST) \
		--metadata-file $(IMAGE_METADATA) \
		$(IMAGE_OUTPUT) \
		-f $(IMAGE_DOCKERFILE) $(IMAGE_CONTEXT)

.PHONY: op-image-digest
##p IMAGE_NAME* IMAGE_METADATA
op-image-digest: ## Print the digest of the last build.
	$(call require,IMAGE_NAME)
	@sed -n 's/.*"containerimage.digest": *"\([^"]*\)".*/\1/p' $(IMAGE_METADATA)

.PHONY: op-image-run
##p IMAGE_NAME* IMAGE_REPO IMAGE_TAG
op-image-run: ## Run the built image, detecting its exposed port.
	$(call require,IMAGE_NAME)
	{ \
		port=$$(docker inspect --format='{{range $$key, $$value := .Config.ExposedPorts }}{{$$key}}{{end}}' $(IMAGE_REF) | sed 's/\/.*//') ;\
		if [ -z "$$(docker network ls --filter name=^$(OP_MODULE)$$ --format '{{.Name}}')" ]; then \
			docker network create $(OP_MODULE); \
		fi ;\
		if [ "$$(docker ps -a --filter name=^$(IMAGE_NAME)$$ --format '{{.Names}}')" = "$(IMAGE_NAME)" ]; then \
			docker stop $(IMAGE_NAME) && docker rm $(IMAGE_NAME); \
		fi ;\
		docker run -d --name $(IMAGE_NAME) --network $(OP_MODULE) -p $${port}:$${port} $(IMAGE_REF); \
	}

.PHONY: op-image-inspect
##p IMAGE_NAME* DIVE_CI_CONF
op-image-inspect: ## Inspect image layers with dive.
	$(call require,IMAGE_NAME)
	@# The socket mount grants the dive container daemon-level access. Accepted:
	@# dive reads images from the local daemon and has no other way in.
	@docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD)/$(DIVE_CI_CONF):/opt/.dive-ci.yaml \
		wagoodman/dive@$(OP_DIVE_SHA) $(IMAGE_REF) --ci --ci-config /opt/.dive-ci.yaml
