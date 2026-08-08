GIT_CHGLOG_SHA := sha256:c791b1e8264387690cce4ce32e18b4f59ca3ffd8d55cb4093dc6de74529493f4
# Path to your CI directory
CONVENTIONAL_CHANGELOG = build/changelog

# https://hub.docker.com/layers/commitlint/commitlint/21.0.0/images/sha256-ed61a4abb2b9a580d115a7e77c40b932566890bdc650a01b02261792dd6b1a54
COMMITLINT_SHA := sha256:f607550f066a09d5c3ef065495c7c7460535139977566ea3b1dac9f8c6afb430

##@ Repo Operator: Changelog

.PHONY: conventional-commit-lint
conventional-commit-lint: ## Lint commit messages against the conventional-commit spec.
	@docker run --rm -v $$PWD:/app --workdir /app commitlint/commitlint@${COMMITLINT_SHA} --config $(CONVENTIONAL_CHANGELOG)/.commitlintrc.yml --from=origin/$(DEFAULT_BRANCH) --to HEAD --verbose

.PHONY: conventional-changelog
conventional-changelog: conventional-commit-lint ## Generate CHANGELOG.md.
	@docker run -it -v "$$PWD":/workdir quay.io/git-chglog/git-chglog@${GIT_CHGLOG_SHA} --config $(CONVENTIONAL_CHANGELOG)/config.yml -o CHANGELOG.md $(git describe --tags $(git rev-list --tags --max-count=1))

.PHONY: conventional-changelog-release
conventional-changelog-release: ## Generate release notes for a tag. Requires TAG.
	$(call require,TAG)
	@docker run -v "$$PWD":/workdir quay.io/git-chglog/git-chglog@${GIT_CHGLOG_SHA} --config $(CONVENTIONAL_CHANGELOG)/release-config.yml ${TAG}
