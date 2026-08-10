# Core: shared variables, functions, and the help targets.
#
# Public parameters carry a ##v line and render via op-help-params.

##v path to this submodule from the repository root
OPERATOR_PATH  ?= .
##v release branch for tag detection and commit lint
DEFAULT_BRANCH ?= master
##v source root
SRC            ?= .
##v build tree holding package/ and ci/
BUILD_PATH     ?= build
##v deployment tree
DEPLOY_PATH    ?= deploy
##v kubeconfig mounted into the helm container (empty: ~/.kube)
KUBECONFIG     ?=

# Set by GitHub Actions. Declared so they are defined-but-empty elsewhere.
GITHUB_HEAD_REF ?=
GITHUB_REF_TYPE ?=
GITHUB_REF_NAME ?=

# Name the missing variable instead of expanding to nothing.
#   $(call require,IMAGE_NAME)
# Declare optionals as `FOO ?=`. `FOO ?= ""` assigns a literal two-character
# string that every conditional reads as non-empty, including this one.
require = $(if $(strip $($(1))),,$(error $(1) is required: make $@ $(1)=<value>))

# Lazy on purpose: five eager $(shell) calls here would tax every make
# invocation, help included, whether or not a target reads them.
OP_MODULE = $(shell basename `pwd`)
OP_COMMIT = $(shell git describe --always --dirty --abbrev=7 --match='' 2>/dev/null)
OP_TAG    = $(shell git for-each-ref --count=1 --format='%(refname:short)' 'refs/tags/v[0-9]*.[0-9]*.[0-9]*' --points-at $(DEFAULT_BRANCH) --merged 2>/dev/null)
OP_TIMESTAMP = $(shell date '+%Y-%m-%d_%I:%M')

# Branch resolution: PR head ref in CI, else the local branch.
ifneq ($(GITHUB_HEAD_REF),)
  OP_BRANCH = $(GITHUB_HEAD_REF)
else
  OP_BRANCH = $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
endif

ifeq ($(GITHUB_REF_TYPE), tag)
  OP_TAG = $(GITHUB_REF_NAME)
endif

# Explicit VERSION wins, a detached HEAD falls back to the tag, anything
# else is the branch name.
##v version override (empty: derived from tag or branch)
VERSION ?=
ifeq ($(strip $(VERSION)),)
  ifeq ($(OP_BRANCH), HEAD)
    VERSION = $(OP_TAG)
  else
    VERSION = $(OP_BRANCH)
  endif
endif

# Pinned utility container for the sync scripts (ubuntu:26.04, 2026-08-10).
OP_UBUNTU_SHA := sha256:678c6550cc43645e08669028bc177f50be4e7c5b8cca677067b1914d4afc7a03
OP_UBUNTU_CMD := docker run -i --rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD)/:/opt/:rw \
		-w "/opt" \
		ubuntu@$(OP_UBUNTU_SHA)

##@ Core

# One pass over every makefile piped in on stdin: sections (##@), targets
# with their descriptions (##) and params line (##p), and the ##v-annotated
# parameters collected for the summary at the end.
#
# Pattern sourced from:
# https://gist.github.com/prwhite/8168133?permalink_comment_id=2749866#gistcomment-2749866
# Every # inside the value is escaped as \# so make does not read a comment.
OP_HELP_CMD := awk '\
	function tail(s) { s = substr(s, 5); sub(/^ +/, "", s); return s } \
	BEGIN { \
		FS = ":.*\#\#"; \
		B = "\033[1m"; C = "\033[36m"; D = "\033[2m"; R = "\033[0m"; \
		printf "\nUsage:\n  make %s<target>%s %s[PARAM=value]%s   (* marks a required param)\n", C, R, C, R \
	} \
	/^\#\#v/ { vdesc = tail($$0); vwant = 1; next } \
	vwant && /^[A-Z_][A-Z0-9_]* *[:?]?=/ { \
		name = $$0; sub(/ *[:?]?=.*/, "", name); \
		def = $$0; sub(/^[A-Z_][A-Z0-9_]* *[:?]?= */, "", def); \
		if (def == "") def = "(empty)"; \
		if (index(def, "$$(shell") == 1 || length(def) > 44) def = "(derived)"; \
		plist[++np] = sprintf("  %s%-18s%s %s %s[default: %s]%s", C, name, R, vdesc, D, def, R); \
		vwant = 0; next \
	} \
	/^\#\#p/ { params = tail($$0); next } \
	/^\#\#@/ { printf "\n%s%s%s\n", B, tail($$0), R; params = "" } \
	/^[a-zA-Z_0-9-]+:.*?\#\#/ { \
		printf "  %s%-30s%s %s\n", C, $$1, R, $$2; \
		if (params != "") { printf "  %s%-30s params: %s%s\n", D, "", params, R; params = "" } \
	} \
	{ vwant = 0 } \
	END { \
		printf "\n%sParameters%s (override per invocation or in your Makefile)\n", B, R; \
		for (i = 1; i <= np; i++) print plist[i] \
	}'

# The pinned container keeps the render hermetic; the host fallback keeps
# help working wherever make does, docker or not.
.PHONY: op-help
op-help: ## Display every target and public parameter.
	@for file in $(MAKEFILE_LIST); do \
		cat $$file; \
	done | if docker info >/dev/null 2>&1 </dev/null; then \
		$(OP_UBUNTU_CMD) $(OP_HELP_CMD); \
	else \
		$(OP_HELP_CMD); \
	fi

.PHONY: op-env
op-env: ## Print the resolved tag, branch, and version.
	@echo "Tag: $(OP_TAG)"
	@echo "Branch: $(OP_BRANCH)"
	@echo "Version: $(VERSION)"
	@echo "Commit: $(OP_COMMIT)"
