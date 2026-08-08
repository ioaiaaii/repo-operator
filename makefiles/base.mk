# Define your default OPERATOR_PATH if not set
OPERATOR_PATH ?= .

# Default branch used for release/tag detection and commitlint base.
# Override to "main" (or any other ref) in the consumer Makefile when needed.
DEFAULT_BRANCH ?= master

# Set by GitHub Actions; declared so they are defined-but-empty elsewhere.
GITHUB_HEAD_REF ?=
GITHUB_REF_TYPE ?=
GITHUB_REF_NAME ?=

# Repo Structure and its friends
MODULE := $(shell basename `pwd`)
COMMIT := $(shell git describe --always --dirty --abbrev=7 --match='' 2>/dev/null)
TAG := $(shell git for-each-ref --count=1 --format='%(refname:short)' 'refs/tags/v[0-9]*.[0-9]*.[0-9]*' --points-at $(DEFAULT_BRANCH) --merged)

# Dynamically determine the branch name:
# - Use GITHUB_HEAD_REF if it is set (indicating a PR).
# - Use GITHUB_REF if it is set (indicating a regular branch push).
# - Default to the local git branch if running outside of CI/CD.
ifneq ($(GITHUB_HEAD_REF),)
  BRANCH := $(GITHUB_HEAD_REF)
else
  BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
endif

# when tag 
ifeq ($(GITHUB_REF_TYPE), tag)
  TAG := $(GITHUB_REF_NAME)
endif

SRC ?= .
CMD_PATH := cmd/${MODULE}/*.go
BUILD_PATH := build
DEPLOY_PATH := deploy

# Get latest merged tag in $(DEFAULT_BRANCH), to allow release. Else, get the branch name as version and skip tags in there.
VERSION ?=

ifeq ($(strip $(VERSION)),)
	ifeq ($(BRANCH), HEAD)    # If in detached HEAD, fallback to commit SHA
        VERSION = $(TAG)           # Use the tag as the version
    else                           # Otherwise, use the branch name
        VERSION = $(BRANCH)
    endif
endif


KUBECONFIG ?=

# Build
TIMESTAMP := $(shell date '+%Y-%m-%d_%I:%M')


# Bins
HELM_SHA := sha256:6b85088a38ef34bbbdf3b91ab4e18038f35220f0f1bb1a97f94b7fde50ce66ee

#https://hub.docker.com/layers/library/ubuntu/26.04/images/sha256-d31acef2a964b6df1f2b7e20a1525c4f2378024e087a4f8a8a9a4247e6a79573
UBUNTU_SHA := sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64

UBUNTU_CMD := docker run -i --rm\
		-u $(shell id -u):$(shell id -g)\
		-v $(PWD)/:/opt/:rw\
		-w "/opt"\
		ubuntu@${UBUNTU_SHA}

ifeq ($(strip $(KUBECONFIG)),)
	HELM_CONTAINER_CMD:=docker run --rm\
			-u $(shell id -u):$(shell id -g)\
			-v $(PWD)/${DEPLOY_PATH}/:/opt/${DEPLOY_PATH}:ro\
			-v ~/.kube:/root/.kube:ro\
			-w "/opt/${DEPLOY_PATH}"\
			alpine/helm@${HELM_SHA}
else
	HELM_CONTAINER_CMD:=docker run --rm\
			-u $(shell id -u):$(shell id -g)\
			-v $(PWD)/${DEPLOY_PATH}/:/opt/${DEPLOY_PATH}:ro\
			-v $(PWD)/${KUBECONFIG}:/root/.kube:ro\
			-w "/opt/${DEPLOY_PATH}"\
			alpine/helm@${HELM_SHA}
endif

include $(dir $(lastword $(MAKEFILE_LIST)))functions.mk

##@ Repo Operator

# Documented targets carry "## text" on the target line; sections are marked
# with "##@ Name". Runs on host awk, not in a container: help must work
# wherever make does.
#
# help lists the project's own targets. The shared ones are parameterised
# interfaces the project wraps, not things to call by hand, so they are left
# to help-all.
HELP_FILES = $(filter-out $(OPERATOR_PATH)/%,$(MAKEFILE_LIST))

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(HELP_FILES)

.PHONY: help-all
help-all: ## Display every target, including the shared interfaces.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.PHONY: environment
environment: ## Print the current tag, branch and version.
	@echo "Tag: "${TAG}
	@echo "Branch: "${BRANCH}
	@echo "Version: "${VERSION}
	@echo "Go path: "${GOPATH}
	@echo "Go bin: "${GOBIN}
	@echo "Go Version: "${GO_VERSION}

.PHONY: gitignore
gitignore: ## Sync the shared gitignore configuration.
	@$(UBUNTU_CMD) bash -c "OPERATOR_PATH=$(OPERATOR_PATH) $(OPERATOR_PATH)/scripts/gitignore_sync.sh"

.PHONY: pre-commit-hooks-list
pre-commit-hooks-list: ## List the available pre-commit hooks.
	@$(UBUNTU_CMD) bash -c "OPERATOR_PATH=$(OPERATOR_PATH) ls $(OPERATOR_PATH)/pre-commit-hooks/"

.PHONY: pre-commit-hooks
pre-commit-hooks: ## Sync the pre-commit-hooks configuration.
	@$(UBUNTU_CMD) bash -c "OPERATOR_PATH=$(OPERATOR_PATH) $(OPERATOR_PATH)/scripts/precommit_sync.sh"

.PHONY: pre-commit-install
pre-commit-install: pre-commit-hooks ## Sync hooks and install the git hook on the host.
	@command -v pre-commit >/dev/null 2>&1 || { echo >&2 "pre-commit not found on host. Install via: pip install pre-commit (or brew install pre-commit)"; exit 1; }
	@pre-commit install
