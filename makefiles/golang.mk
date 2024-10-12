# Build
GOPATH ?= $(shell go env GOPATH)
GOBIN ?= $(shell which go)
TIMESTAMP := $(shell date '+%Y-%m-%d_%I:%M')
LD_FLAGS = "-s -w -X $(MODULE)/pkg/version.BuildVersion=$(VERSION) -X $(MODULE)/pkg/version.BuildHash=$(COMMIT) -X $(MODULE)/pkg/version.BuildTime=$(TIMESTAMP)"
GOBUILD_OPTS = -ldflags=${LD_FLAGS}
GO_VERSION :=$(shell $(UBUNTU_CMD) awk '/^go / {print $$2}' $(SRC)/go.mod )
GOLANG_CI_SHA := sha256:94388e00f07c64262b138a7508f857473e30fdf0f59d04b546a305fc12cb5961
GOCI_CMD := docker run --rm\
		-u $(id -u):$(id -g)\
		-v $(PWD)/${SRC}/:/opt/${SRC}\
		-w /opt/${SRC}\
		golangci/golangci-lint@${GOLANG_CI_SHA}

GO_WORKSPACE_CMD := docker run -i --rm\
		-u $(id -u):$(id -g)\
		-v $(PWD)/$(SRC):/go/$(MODULE)/$(SRC):ro\
		-w "/go/$(MODULE)/$(SRC)"\
		-e CGO_ENABLED=0\
		golang@${GO_WORKSPACE_SHA}

## Update depts
go-mod-update:
	@cd ${SRC} && ${GOBIN} get -u ./... && go vet ./...

## Runs go mod {tidy,vendor,verify}
go-mod-sync: 	
	@cd ${SRC} && ${GOBIN} mod tidy && go mod vendor && go mod verify && echo "at: `pwd`"

## Runs linter
go-lint:
	@echo "Linting...\n"
	@$(GOCI_CMD) golangci-lint run

## Runs tests
go-test:
	@echo "Unit Testing...\n"
	@$(GO_WORKSPACE_CMD) go test ./...

## Builds linux bin for amd64 arch
go-build-linux: 
	cd ${SRC} && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -mod=readonly ${GOBUILD_OPTS} -o ../${BUILD_PATH}/${MODULE} ${CMD_PATH}

## Builds darwin bin for amd64 arch
go-build-darwin:
	cd ${SRC} && CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -a -mod=readonly ${GOBUILD_OPTS} -o ../${BUILD_PATH}/${MODULE}-darwin ${CMD_PATH}

## Builds all bins
go-build-all: build-linux build-darwin
	sha256sum ${BUILD_PATH}/${MODULE} > ${BUILD_PATH}/${MODULE}.sha256
	sha256sum ${BUILD_PATH}/${MODULE}-darwin> ${BUILD_PATH}/${MODULE}-darwin.sha256
