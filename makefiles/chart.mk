# Chart: Helm chart linting, and the pinned helm container.

# alpine/helm:3.21.3 and chart-testing:latest, 2026-08-10
OP_HELM_SHA := sha256:35da09ba0716fc7c3cd63b6b31ee380a9c7662e95f29ab0e4ae962420afd315b
OP_CT_SHA   := sha256:f2fd21d30b64411105c7eafb1862783236a219d29f2292219a09fe94ca78ad2a

ifeq ($(strip $(KUBECONFIG)),)
OP_HELM_CMD := docker run --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD)/$(DEPLOY_PATH)/:/opt/$(DEPLOY_PATH):ro \
		-v ~/.kube:/root/.kube:ro \
		-w "/opt/$(DEPLOY_PATH)" \
		alpine/helm@$(OP_HELM_SHA)
else
OP_HELM_CMD := docker run --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD)/$(DEPLOY_PATH)/:/opt/$(DEPLOY_PATH):ro \
		-v $(PWD)/$(KUBECONFIG):/root/.kube:ro \
		-w "/opt/$(DEPLOY_PATH)" \
		alpine/helm@$(OP_HELM_SHA)
endif

OP_CT_CMD := docker run -it --network host \
		-u $(shell id -u):$(shell id -g) \
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
