# Precommit: sync the shared pre-commit hooks and install them.

##@ Precommit

.PHONY: op-precommit-list
##p OPERATOR_PATH
op-precommit-list: ## List the available pre-commit hooks.
	@ls $(OPERATOR_PATH)/configs/pre-commit-hooks/

.PHONY: op-precommit-sync
##p OPERATOR_PATH
op-precommit-sync: ## Sync the pre-commit-hooks configuration.
	@$(OP_UBUNTU_CMD) bash -c "OPERATOR_PATH=$(OPERATOR_PATH) $(OPERATOR_PATH)/scripts/precommit_sync.sh"

.PHONY: op-precommit-install
##p OPERATOR_PATH
op-precommit-install: op-precommit-sync ## Sync hooks and install the git hook on the host.
	@command -v pre-commit >/dev/null 2>&1 || { echo >&2 "pre-commit not found on host. Install via: pip install pre-commit (or brew install pre-commit)"; exit 1; }
	@pre-commit install
