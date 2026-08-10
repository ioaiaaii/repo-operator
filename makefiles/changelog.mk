# Changelog: conventional-commit linting and changelog generation.

##v directory with commitlint and git-chglog configs
CONVENTIONAL_CHANGELOG ?= build/changelog
##v release tag, required by op-changelog-release
TAG ?=

# git-chglog:latest and commitlint:latest, 2026-08-10
OP_CHGLOG_SHA     := sha256:c791b1e8264387690cce4ce32e18b4f59ca3ffd8d55cb4093dc6de74529493f4
OP_COMMITLINT_SHA := sha256:f4b38082bec66b4cd1b37a0357145dded515c4468e2b339ec9ba31f86461f6b9

##@ Changelog

.PHONY: op-changelog-lint
##p CONVENTIONAL_CHANGELOG DEFAULT_BRANCH
op-changelog-lint: ## Lint commit messages against the conventional-commit spec.
	@docker run --rm -v $$PWD:/app --workdir /app commitlint/commitlint@$(OP_COMMITLINT_SHA) --config $(CONVENTIONAL_CHANGELOG)/.commitlintrc.yml --from=origin/$(DEFAULT_BRANCH) --to HEAD --verbose

.PHONY: op-changelog
##p CONVENTIONAL_CHANGELOG
op-changelog: op-changelog-lint ## Generate CHANGELOG.md.
	@docker run --rm -v "$$PWD":/workdir quay.io/git-chglog/git-chglog@$(OP_CHGLOG_SHA) --config $(CONVENTIONAL_CHANGELOG)/config.yml -o CHANGELOG.md

.PHONY: op-changelog-release
##p TAG* CONVENTIONAL_CHANGELOG
op-changelog-release: ## Generate release notes for a tag.
	$(call require,TAG)
	@docker run --rm -v "$$PWD":/workdir quay.io/git-chglog/git-chglog@$(OP_CHGLOG_SHA) --config $(CONVENTIONAL_CHANGELOG)/release-config.yml $(TAG)
