CHART_TESTING_SHA := sha256:f2fd21d30b64411105c7eafb1862783236a219d29f2292219a09fe94ca78ad2a

CT_CONTAINER_CMD := docker run -it --network host\
		-u $(id -u):$(id -g)\
		-v $(PWD)/${BUILD_PATH}/:/opt/${BUILD_PATH}\
		-v $(PWD)/${DEPLOY_PATH}/:/opt/${DEPLOY_PATH}\
		-v $(PWD)/.git/:/opt/.git:ro\
		-w "/opt"\
		quay.io/helmpack/chart-testing@${CHART_TESTING_SHA}

## Runs ct linting
.PHONY: chart-testing
chart-testing:
	@echo "Chart testing..."
	$(CT_CONTAINER_CMD) ct lint --config ${BUILD_PATH}/ci/.chart-testing.yaml --all
