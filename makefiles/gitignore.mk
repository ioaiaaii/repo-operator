# Gitignore: sync the shared gitignore templates into the consumer repo.

##@ Gitignore

.PHONY: op-gitignore-sync
##p OPERATOR_PATH
op-gitignore-sync: ## Append the shared gitignore templates to .gitignore.
	@$(OP_UBUNTU_CMD) bash -c "OPERATOR_PATH=$(OPERATOR_PATH) $(OPERATOR_PATH)/scripts/gitignore_sync.sh"
