# DOCKER_TAG from version var, but DNS compliant
DOCKER_TAG :=$(shell echo $(VERSION) | $(UBUNTU_CMD) awk '{gsub("[^.0-9a-zA-Z]","-");print $$0}' )
DOCKER_IMAGE_REPO ?= ""
DOCKER_IMAGE ?= ""

## Runs hadolint on Dockerfile
.PHONY: docker-lint
docker-lint $(DOCKER_IMAGE): 
	@echo "Dockerfile linting..."
	@docker run --rm -i hadolint/hadolint < ${BUILD_PATH}/package/${DOCKER_IMAGE}/Dockerfile

## Builds image. Call it with VERSION arg to parse Image tag. 
## e.g. `make docker-image VERSION=feat/packaging_dockerfile`
docker-image: $(DOCKER_IMAGE)
	@echo "Bulding ${DOCKER_IMAGE} image with tag: ${DOCKER_TAG}..."
	@DOCKER_BUILDKIT=1 docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG}  --build-arg LD_FLAGS=$(LD_FLAGS) -f ${BUILD_PATH}/package/${DOCKER_IMAGE}/Dockerfile ${SRC}

## Detects the default exposed port from container's image, and run the container with the exposed port
docker-run: $(DOCKER_IMAGE) $(DOCKER_ARGS)
	{ 	\
		port=$$(docker inspect --format='{{range $$key, $$value := .Config.ExposedPorts }}{{$$key}}{{end}}' ${DOCKER_IMAGE}:${VERSION} | sed 's/\/.*//') ;\
		docker network create ${MODULE};\
		docker run --name $(DOCKER_IMAGE) --network ${MODULE} -p $${port}:$${port} $(DOCKER_IMAGE):$(VERSION) ;\
	}
