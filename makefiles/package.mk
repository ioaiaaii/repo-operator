# DOCKER_TAG from version var, but DNS compliant
DOCKER_TAG :=$(shell echo $(VERSION) | $(UBUNTU_CMD) awk '{gsub("[^.0-9a-zA-Z]","-");print $$0}' )
DOCKER_IMAGE_REPO ?= ""
DOCKER_IMAGE ?= ""

## Runs hadolint on Dockerfile
.PHONY: docker-lint
docker-lint:
	@echo "Dockerfile linting..."
	@docker run --rm -i hadolint/hadolint < ${BUILD_PATH}/package/${DOCKER_IMAGE}/Dockerfile

## Builds image. Call it with VERSION arg to parse Image tag. 
## e.g. `make docker-image VERSION=feat/packaging_dockerfile`
docker-image:
	@echo "Bulding ${DOCKER_IMAGE} image with tag: ${DOCKER_TAG}..."
	@DOCKER_BUILDKIT=1 docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} --build-arg LD_FLAGS="${LD_FLAGS} -f ${BUILD_PATH}/package/${DOCKER_IMAGE}/Dockerfile ${SRC}

## Tags and Pushes image to a Registry. Currently to DockerHub
.PHONY: docker-push
docker-push:
	@echo "Warning!! You must authenticate with Dockerhub, and have repo access"
	@echo "Tagging ${DOCKER_IMAGE}:${DOCKER_TAG} to ${DOCKER_IMAGE_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}"
	@docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}
	@echo "Pushing ${DOCKER_IMAGE_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}"
	@docker push ${DOCKER_IMAGE_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}

## Detects the default exposed port from container's image, and run the container with the exposed port
docker-run:
	{ \
		port=$$(docker inspect --format='{{range $$key, $$value := .Config.ExposedPorts }}{{$$key}}{{end}}' ${DOCKER_IMAGE}:${DOCKER_TAG} | sed 's/\/.*//') ;\
		if [ -z "$$(docker network ls --filter name=^${MODULE}$$ --format '{{.Name}}')" ]; then \
			docker network create ${MODULE}; \
		fi ;\
		if [ "$$(docker ps -a --filter name=^${DOCKER_IMAGE}$$ --format '{{.Names}}')" = "${DOCKER_IMAGE}" ]; then \
			docker stop ${DOCKER_IMAGE} && docker rm ${DOCKER_IMAGE}; \
		fi ;\
		docker run -d --name $(DOCKER_IMAGE) --network ${MODULE} -p $${port}:$${port} $(DOCKER_IMAGE):$(DOCKER_TAG); \
	}

## Build Docker image with Kaniko and cache repo
## 	run it with DOCKER_IMAGE_REPO="<registry url>" DOCKER_IMAGE=<image>
##  it auto detects if running in GH with Identity Pool Service Account
.PHONY: kaniko-docker-image
kaniko-docker-image:
	@{ \
		if [ -n "$$GOOGLE_APPLICATION_CREDENTIALS" ]; then \
			CREDENTIALS_MOUNT="-e GOOGLE_APPLICATION_CREDENTIALS=/kaniko/config.json -v $$GOOGLE_APPLICATION_CREDENTIALS:/kaniko/config.json:ro"; \
		else \
			CREDENTIALS_MOUNT="-v $$HOME/.config/gcloud:/root/.config/gcloud:ro"; \
		fi; \
		echo "Building ${DOCKER_IMAGE} image with tag: ${DOCKER_TAG} using Kaniko... $$CREDENTIALS_MOUNT" ;\
		docker run --rm -v $(PWD):/workspace \
			$$CREDENTIALS_MOUNT \
			gcr.io/kaniko-project/executor:latest \
			--context=/workspace \
			--dockerfile=${BUILD_PATH}/package/${DOCKER_IMAGE}/Dockerfile \
			--destination=${DOCKER_IMAGE_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG} \
			--cache=true \
			--cache-repo=${DOCKER_IMAGE_REPO}/${DOCKER_IMAGE}-kaniko-cache \
			--cache-dir=/workspace/.kaniko-cache; \
			--build-arg LD_FLAGS="${LD_FLAGS}; \
	}
