# Chart: Helm chart linting, and the pinned helm container.

# alpine/helm:3.21.3 and chart-testing:latest, 2026-08-10
OP_HELM_SHA := sha256:35da09ba0716fc7c3cd63b6b31ee380a9c7662e95f29ab0e4ae962420afd315b
OP_CT_SHA   := sha256:f2fd21d30b64411105c7eafb1862783236a219d29f2292219a09fe94ca78ad2a

ifeq ($(strip $(KUBECONFIG)),)
OP_HELM_CMD := docker run --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD)/$(DEPLOY_PATH)/:/opt/$(DEPLOY_PATH):ro \
		-v $(PWD)/dist/:/opt/dist \
		-e DOCKER_CONFIG=/opt/.docker \
		-v $(HOME)/.docker:/opt/.docker:ro \
		-v ~/.kube:/root/.kube:ro \
		-w "/opt/$(DEPLOY_PATH)" \
		alpine/helm@$(OP_HELM_SHA)
else
OP_HELM_CMD := docker run --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD)/$(DEPLOY_PATH)/:/opt/$(DEPLOY_PATH):ro \
		-v $(PWD)/dist/:/opt/dist \
		-e DOCKER_CONFIG=/opt/.docker \
		-v $(HOME)/.docker:/opt/.docker:ro \
		-v $(PWD)/$(KUBECONFIG):/root/.kube:ro \
		-w "/opt/$(DEPLOY_PATH)" \
		alpine/helm@$(OP_HELM_SHA)
endif

OP_CT_CMD := docker run --rm --network host \
		-u $(shell id -u):$(shell id -g) \
		-e KUBECONFIG=/opt/.kube/config \
		-v $(HOME)/.kube:/opt/.kube:ro \
		-v $(PWD)/$(BUILD_PATH)/:/opt/$(BUILD_PATH) \
		-v $(PWD)/$(DEPLOY_PATH)/:/opt/$(DEPLOY_PATH) \
		-v $(PWD)/.git/:/opt/.git:ro \
		-w "/opt" \
		quay.io/helmpack/chart-testing@$(OP_CT_SHA)

##@ Chart

.PHONY: op-chart-lint
##p BUILD_PATH DEPLOY_PATH
op-chart-lint: ## Lint charts with chart-testing.
	@echo "Chart testing..."
	$(OP_CT_CMD) ct lint --config $(BUILD_PATH)/ci/.chart-testing.yaml --all

##v chart directory for op-chart-package, relative to DEPLOY_PATH
CHART_DIR ?=
##v packaged chart filename in dist/ for op-chart-push
CHART_PACKAGE ?=
##v OCI repository for op-chart-push, e.g. oci://ghcr.io/owner/charts
CHART_OCI_REPO ?=

.PHONY: op-chart-package
##p CHART_DIR*
op-chart-package: ## Package a chart into dist/.
	$(call require,CHART_DIR)
	@mkdir -p dist
	@$(OP_HELM_CMD) package $(CHART_DIR) -d /opt/dist

.PHONY: op-chart-push
##p CHART_PACKAGE* CHART_OCI_REPO*
op-chart-push: ## Push a packaged chart to an OCI registry.
	$(call require,CHART_PACKAGE)
	$(call require,CHART_OCI_REPO)
	@$(OP_HELM_CMD) push /opt/dist/$(CHART_PACKAGE) $(CHART_OCI_REPO)

.PHONY: op-chart-test
##p BUILD_PATH DEPLOY_PATH
op-chart-test: ## Lint and install charts against the current cluster.
	@echo "Chart install testing..."
	$(OP_CT_CMD) ct lint-and-install --config $(BUILD_PATH)/ci/.chart-testing.yaml --all
