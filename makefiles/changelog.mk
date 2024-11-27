# Path to your CI directory
CONVENTIONAL_CHANGELOG = build/changelog

## commit message linting with conventional-commit spec
.PHONY: conventional-commit-lint
conventional-commit-lint:
	@docker run --rm -v $$PWD:/app --workdir /app commitlint/commitlint:19.4.1 --config $(CONVENTIONAL_CHANGELOG)/.commitlintrc.yml --from=origin/master --to HEAD --verbose

## changelog generator CHANGELOG.md
.PHONY: conventional-changelog
conventional-changelog: conventional-commit-lint
	@docker run -it -v "$$PWD":/workdir quay.io/git-chglog/git-chglog --config $(CONVENTIONAL_CHANGELOG)/config.yml -o CHANGELOG.md $(git describe --tags $(git rev-list --tags --max-count=1))

## changelog generator for specific tag linked to github release notes
.PHONY: conventional-changelog-release
conventional-changelog-release:
	@docker run -v "$$PWD":/workdir quay.io/git-chglog/git-chglog --config $(CONVENTIONAL_CHANGELOG)/release-config.yml ${TAG}
