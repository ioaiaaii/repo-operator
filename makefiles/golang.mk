# Build
GOPATH ?= $(shell go env GOPATH)
GOBIN ?= $(shell which go)
TIMESTAMP := $(shell date '+%Y-%m-%d_%I:%M')
LD_FLAGS = "-s -w -X $(MODULE)/pkg/version.BuildVersion=$(VERSION) -X $(MODULE)/pkg/version.BuildHash=$(COMMIT) -X $(MODULE)/pkg/version.BuildTime=$(TIMESTAMP)"
GOBUILD_OPTS = -ldflags=${LD_FLAGS}
GO_VERSION :=$(shell $(UBUNTU_CMD) awk '/^go / {print $$2}' $(SRC)/go.mod )
GOLANG_CI_SHA := sha256:e47065d755ca0afeac9df866d1dabdc99f439653a43fe234e05f50d9c36b6b90
GO_WORKSPACE_SHA := sha256:ad5c126b5cf501a8caef751a243bb717ec204ab1aa56dc41dc11be089fafcb4f

GOCI_CMD := docker run --rm \
		-u $(shell id -u):$(shell id -g)\
		-v $(PWD)/${SRC}:/opt/${SRC} \
		-w /opt/${SRC} \
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
	@$(GOCI_CMD) golangci-lint run --config ${BUILD_PATH}/ci/.golangci.yml -v

## Runs tests
go-test:
	@echo "Unit Testing..."
	@$(GO_WORKSPACE_CMD) go test ./...

## Builds Linux binary for amd64 architecture (for Kubernetes deployment)
go-build: 
	cd ${SRC} && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -mod=readonly ${GOBUILD_OPTS} -o ../${BUILD_PATH}/${MODULE} ${CMD_PATH}
