# Go: containerized lint, test, and build.

##v entrypoint glob for op-go-build
CMD_PATH    ?= cmd/$(OP_MODULE)/*.go
##v Go import path to stamp Build* variables into (empty: no -X flags)
VERSION_PKG ?=

# Stripping applies everywhere. `go build` ignores -X for a symbol that does
# not exist, so a wrong or unset VERSION_PKG fails silently rather than loudly.
##v linker flags passed to go build and op-image-build
LD_FLAGS = -s -w
ifneq ($(strip $(VERSION_PKG)),)
LD_FLAGS += -X $(VERSION_PKG).BuildVersion=$(VERSION) -X $(VERSION_PKG).BuildHash=$(OP_COMMIT) -X $(VERSION_PKG).BuildTime=$(OP_TIMESTAMP)
endif

OP_GOBUILD_OPTS = -ldflags="$(LD_FLAGS)"

# Lazy: reading go.mod spawns a container, so only pay for it on use.
OP_GO_VERSION = $(shell $(OP_UBUNTU_CMD) awk '/^go / {print $$2}' $(SRC)/go.mod)

# golangci/golangci-lint:v2.12.2-alpine, 2026-08-10
OP_GOLANGCI_SHA := sha256:91b27804074a0bacea298707f016911e60cf0cdbc6c7bf5ccacb5f0606d18d60
# golang:1.26, 2026-08-10
OP_GO_SHA := sha256:2005724102f45917a63e9d092fc0e4ea56ea575048ce147caad5f5f61502c365

OP_GOCI_CMD := docker run --rm \
		-v $(PWD)/$(SRC):/app \
		-v $(PWD)/$(BUILD_PATH)/ci/.cache/golangci-lint/v1.61.0:/root/.cache \
		-w /app \
		-e GOLANGCI_LINT_CACHE=$(PWD)/$(BUILD_PATH)/ci/.cache \
		golangci/golangci-lint@$(OP_GOLANGCI_SHA)

OP_GO_CMD := docker run -i --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD)/$(SRC):/go/$(OP_MODULE)/$(SRC):ro \
		-w "/go/$(OP_MODULE)/$(SRC)" \
		-e CGO_ENABLED=0 \
		golang@$(OP_GO_SHA)

##@ Go

.PHONY: op-go-mod-update
##p SRC
op-go-mod-update: ## Update dependencies.
	@cd $(SRC) && go get -u ./... && go vet ./...

.PHONY: op-go-mod-sync
##p SRC
op-go-mod-sync: ## Run go mod tidy, vendor, and verify.
	@cd $(SRC) && go mod tidy && go mod vendor && go mod verify

.PHONY: op-go-lint
##p SRC BUILD_PATH
op-go-lint: ## Run golangci-lint.
	@echo "Linting..."
	@$(OP_GOCI_CMD) golangci-lint run --config $(BUILD_PATH)/ci/.golangci.yml --out-format=tab -v ./...

.PHONY: op-go-test
##p SRC
op-go-test: ## Run unit tests.
	@echo "Unit Testing..."
	@$(OP_GO_CMD) go test ./...

.PHONY: op-go-build
##p SRC CMD_PATH LD_FLAGS VERSION_PKG BUILD_PATH
op-go-build: ## Build a static linux/amd64 binary.
	cd $(SRC) && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -mod=readonly $(OP_GOBUILD_OPTS) -o ../$(BUILD_PATH)/$(OP_MODULE) $(CMD_PATH)
