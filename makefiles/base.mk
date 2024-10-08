# Repo/Branch/Release
MODULE := $(shell basename `pwd`)
COMMIT := $(shell git log --pretty=format:'%h' -n 1)
TAG := $(shell git for-each-ref --count=1 --format='%(refname:short)' 'refs/tags/v[0-9]*.[0-9]*.[0-9]*' --points-at master --merged)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
export

# Get latest merged tag in master, to allow release. Else, get the branch name as version and skip tags in there
VERSION ?= ""
ifeq ($(VERSION),"")
	ifeq ($(TAG),)
		VERSION    			= $(BRANCH)
	else
		VERSION				= $(TAG)
	endif
endif


# DOCKER_TAG from version var, but DNS compliant
DOCKER_TAG :=$(shell echo $(VERSION) | $(UBUNTU_CMD) awk '{gsub("[^.0-9a-zA-Z]","-");print $$0}' )
DOCKER_IMAGE_REPO ?= ""
KUBECONFIG ?= ""

# Build
TIMESTAMP := $(shell date '+%Y-%m-%d_%I:%M')


# Bins
GOLANG_CI_SHA := sha256:94388e00f07c64262b138a7508f857473e30fdf0f59d04b546a305fc12cb5961
CHART_TESTING_SHA := sha256:ef453de0be68d5ded26f3b3ea0c5431b396c8c48f89e2a07be7b19c4c9a68b31
HELM_SHA := sha256:6b85088a38ef34bbbdf3b91ab4e18038f35220f0f1bb1a97f94b7fde50ce66ee
GO_WORKSPACE_SHA := sha256:6b494c932ee8c209631e27521ddbe364da56e7f1275998fbb182447d20103e46
UBUNTU_SHA := sha256:f0a63f53b736b9211a5313a7219f6cc012b7cf4194c7ce2248fac8162b56dceb

GOCI_CMD := docker run --rm\
		-u $(id -u):$(id -g)\
		-v $(PWD)/${SRC}/:/opt/${SRC}\
		-w /opt/${SRC}\
		golangci/golangci-lint@${GOLANG_CI_SHA}

CT_CONTAINER_CMD := docker run -it --network host\
		-u $(id -u):$(id -g)\
		-v $(PWD)/${BUILD_PATH}/:/opt/${BUILD_PATH}\
		-v $(PWD)/${DEPLOY_PATH}/:/opt/${DEPLOY_PATH}\
		-v $(PWD)/.git/:/opt/.git:ro\
		-w "/opt"\
		quay.io/helmpack/chart-testing@${CHART_TESTING_SHA}

GO_WORKSPACE_CMD := docker run -i --rm\
		-u $(id -u):$(id -g)\
		-v $(PWD)/$(SRC):/go/$(MODULE)/$(SRC):ro\
		-w "/go/$(MODULE)/$(SRC)"\
		-e CGO_ENABLED=0\
		golang@${GO_WORKSPACE_SHA}


UBUNTU_CMD := docker run -i --rm\
		-u $(id -u):$(id -g)\
		-v $(PWD)/:/opt/:rw\
		-w "/opt"\
		ubuntu@${UBUNTU_SHA}

ifeq ($(KUBECONFIG),"")
	HELM_CONTAINER_CMD:=docker run --rm\
			-u $(id -u):$(id -g)\
			-v $(PWD)/${DEPLOY_PATH}/:/opt/${DEPLOY_PATH}:ro\
			-v ~/.kube:/root/.kube:ro\
			-w "/opt/${DEPLOY_PATH}"\
			alpine/helm@${HELM_SHA}
else
	HELM_CONTAINER_CMD:=docker run --rm\
			-u $(id -u):$(id -g)\
			-v $(PWD)/${DEPLOY_PATH}/:/opt/${DEPLOY_PATH}:ro\
			-v $(PWD)/${KUBECONFIG}:/root/.kube:ro\
			-w "/opt/${DEPLOY_PATH}"\
			alpine/helm@${HELM_SHA}
endif

HELP_CMD:=awk '{\
					if ($$0 ~ /^.PHONY: [a-zA-Z\-\_0-9]+$$/) {\
						command = substr($$0, index($$0, ":") + 2);\
						if (info) {\
							printf "\t\033[36m%-20s\033[0m %s\n",\
								command, info;\
							info = "";\
						}\
					} else if ($$0 ~ /^[a-zA-Z\-\_0-9.]+:/) {\
						command = substr($$0, 0, index($$0, ":"));\
						if (info) {\
							printf "\t\033[36m%-20s\033[0m %s\n",\
								command, info;\
							info = "";\
						}\
					} else if ($$0 ~ /^\#\#/) {\
						if (info) {\
							info = info"\n\t\t\t     "substr($$0, 3);\
						} else {\
							info = substr($$0, 3);\
						}\
					} else {\
						if (info) {\
							print "\n"info;\
						}\
						info = "";\
					}\
				}'				


## autogenerated help target
## add info to your command inserting before definition:
##   "## <text>"
.PHONY: help
help:
	@for file in $(MAKEFILE_LIST); do \
		cat $$file; \
	done | $(UBUNTU_CMD) $(HELP_CMD)

## Prints the current tag,branch and version
.PHONY: environment
environment:
	@echo "Tag: "${TAG}
	@echo "Branch: "${BRANCH} 
	@echo "Version: "${VERSION}
	@echo "Image Tag: "${DOCKER_TAG}
	@echo "Go path: "${GOPATH}
	@echo "Go bin: "${GOBIN}
	@echo "Go Version: "${GO_VERSION}


## Syncs gitignore configuration
.PHONY: gitignore
gitignore:
	@$(UBUNTU_CMD) ./scripts/gitignore_sync.sh
