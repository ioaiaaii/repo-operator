# Build
GOPATH ?= $(shell go env GOPATH)
GOBIN ?= $(shell which go)
# Stripping applies everywhere. Version stamping needs a package to stamp
# into, so a consumer opts in by setting VERSION_PKG to its import path;
# `go build` ignores -X for a symbol that does not exist, so a wrong or unset
# path fails silently rather than loudly.
VERSION_PKG ?=
LD_FLAGS = -s -w
ifneq ($(strip $(VERSION_PKG)),)
LD_FLAGS += -X $(VERSION_PKG).BuildVersion=$(VERSION) -X $(VERSION_PKG).BuildHash=$(COMMIT) -X $(VERSION_PKG).BuildTime=$(TIMESTAMP)
endif
GOBUILD_OPTS = -ldflags="${LD_FLAGS}"
GO_VERSION :=$(shell $(UBUNTU_CMD) awk '/^go / {print $$2}' $(SRC)/go.mod )
#v2.10.1-alpine MULTI-PLATFORM
GOLANG_CI_SHA := sha256:33bc6b6156d4c7da87175f187090019769903d04dd408833b83083ed214b0ddf
#golang:1.26.0 MULTI-PLATFORM
GO_WORKSPACE_SHA := sha256:c83e68f3ebb6943a2904fa66348867d108119890a2c6a2e6f07b38d0eb6c25c5

GOCI_CMD := docker run --rm \
		-v $(PWD)/${SRC}:/app \
		-v $(PWD)/${BUILD_PATH}/ci/.cache/golangci-lint/v1.61.0:/root/.cache\
		-w /app \
		-e GOLANGCI_LINT_CACHE=$(PWD)/${BUILD_PATH}/ci/.cache \
		golangci/golangci-lint@${GOLANG_CI_SHA}

GO_WORKSPACE_CMD := docker run -i --rm \
		-u $(shell id -u):$(shell id -g)\
		-v $(PWD)/$(SRC):/go/$(MODULE)/$(SRC):ro \
		-w "/go/$(MODULE)/$(SRC)" \
		-e CGO_ENABLED=0 \
		golang@${GO_WORKSPACE_SHA}

##@ Repo Operator: Go

.PHONY: go-mod-update
go-mod-update: ## Update dependencies.
	@cd ${SRC} && ${GOBIN} get -u ./... && go vet ./...

.PHONY: go-mod-sync
go-mod-sync: ## Run go mod tidy, vendor and verify.
	@cd ${SRC} && ${GOBIN} mod tidy && go mod vendor && go mod verify && echo "at: `pwd`"

.PHONY: go-lint
go-lint: ## Run golangci-lint.
	@echo "Linting..."
	@$(GOCI_CMD) golangci-lint run --config ${BUILD_PATH}/ci/.golangci.yml --out-format=tab -v ./...

.PHONY: go-test
go-test: ## Run unit tests.
	@echo "Unit Testing..."
	@$(GO_WORKSPACE_CMD) go test ./...

.PHONY: go-build
go-build: ## Build a static linux/amd64 binary.
	cd ${SRC} && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -mod=readonly ${GOBUILD_OPTS} -o ../${BUILD_PATH}/${MODULE} ${CMD_PATH}
