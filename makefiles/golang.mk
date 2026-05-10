# Build
GOPATH ?= $(shell go env GOPATH)
GOBIN ?= $(shell which go)
TIMESTAMP := $(shell date '+%Y-%m-%d_%I:%M')
LD_FLAGS = "-s -w -X $(MODULE)/pkg/version.BuildVersion=$(VERSION) -X $(MODULE)/pkg/version.BuildHash=$(COMMIT) -X $(MODULE)/pkg/version.BuildTime=$(TIMESTAMP)"
GOBUILD_OPTS = -ldflags=${LD_FLAGS}
GO_VERSION :=$(shell $(UBUNTU_CMD) awk '/^go / {print $$2}' $(SRC)/go.mod )
#v2.10.1-alpine MULTI-PLATFORM
GOLANG_CI_SHA := sha256:33bc6b6156d4c7da87175f187090019769903d04dd408833b83083ed214b0ddf
#golang:1.26.0 MULTI-PLATFORM
GO_WORKSPACE_SHA := sha256:sha256:c83e68f3ebb6943a2904fa66348867d108119890a2c6a2e6f07b38d0eb6c25c5

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

## Update dependencies
go-mod-update:
	@cd ${SRC} && ${GOBIN} get -u ./... && go vet ./...

## Runs go mod {tidy, vendor, verify}
go-mod-sync: 	
	@cd ${SRC} && ${GOBIN} mod tidy && go mod vendor && go mod verify && echo "at: `pwd`"

## Runs linter
go-lint:
	@echo "Linting..."
	@$(GOCI_CMD) golangci-lint run --config ${BUILD_PATH}/ci/.golangci.yml --out-format=tab -v ./...

## Runs tests
go-test:
	@echo "Unit Testing..."
	@$(GO_WORKSPACE_CMD) go test ./...

## Builds Linux binary for amd64 architecture (for Kubernetes deployment)
go-build: 
	cd ${SRC} && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -mod=readonly ${GOBUILD_OPTS} -o ../${BUILD_PATH}/${MODULE} ${CMD_PATH}
