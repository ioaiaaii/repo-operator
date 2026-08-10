<p align="center">
  <img src="docs/logo.svg" width="120" alt="repo-operator">
</p>

# Repo Operator

`repo-operator` is a Make library for managing many repositories with one
toolkit. It provides reusable, Docker-based, hermetic Makefile targets
for common operations: building and scanning images, linting Go, chart
testing, changelogs, and repository hygiene. Consumers add it as a git
submodule and include the modules they need.

Documentation lives at
[ioaiaaii.github.io/project/cloud-repo-operator](https://ioaiaaii.github.io/project/cloud-repo-operator/).

## Motivation

Maintaining several repositories alone means every repo grows its own
Makefile, its own tool versions, and its own CI boilerplate, and they
drift apart. A trivy fix or a helm bump has to be repeated everywhere,
and the oldest repo silently runs last year's toolchain. repo-operator
centralizes that surface: fix once, bump the submodule everywhere, on
each consumer's schedule.

## Features

- **Hermetic targets**. Tools run in containers pinned by digest, so
  local runs and CI produce the same result. The host needs Docker, make,
  git, and Go for the `op-go-mod-*` and `op-go-build` targets.
- **Targets as functions**. Interface targets take parameters at
  invocation, like `make op-image-build IMAGE_NAME=my-app`, so one
  target serves every image and every repo without hardcoding.
- **Collision-free by construction**. All targets carry the `op-` prefix
  and all private variables the `OP_` prefix, so inclusion cannot clash
  with a consumer's or a scaffold's names.

## Usage

```make
OPERATOR_PATH := build/repo-operator

include $(OPERATOR_PATH)/makefiles/all.mk

help: op-help

my-image-build:
	@$(MAKE) op-image-build IMAGE_NAME=my-app
```

[examples/basic](./examples/basic/Makefile) is a working example. Pin
the submodule to a commit and bump it deliberately.

## Modules

| File | Targets | Provides |
|---|---|---|
| `core.mk` | `op-help`, `op-env` | shared variables, `require()`, help |
| `go.mk` | `op-go-*` | lint, test, mod hygiene, static build |
| `image.mk` | `op-image-*` | buildx build, hadolint, dive, digest |
| `scan.mk` | `op-scan` | trivy, subcommand via `TRIVY_ARGS` |
| `chart.mk` | `op-chart-lint` | chart-testing |
| `changelog.mk` | `op-changelog*` | commitlint, git-chglog |
| `openapi.mk` | `op-openapi-docs` | spec to Markdown |
| `otel.mk` | `op-otel-up` | local OpenTelemetry Collector |
| `gitignore.mk` | `op-gitignore-sync` | shared gitignore templates |
| `precommit.mk` | `op-precommit-*` | shared pre-commit hooks |

## Naming contract

- Targets are `op-<domain>-<verb>`, and the file name is the domain.
- Public parameters (`IMAGE_NAME`, `TRIVY_ARGS`, `OPERATOR_PATH`) are
  stable API. Private variables carry the `OP_` prefix and may change
  without notice.
- Every public parameter carries a `##v` annotation above its definition.
  `make op-help` renders them with descriptions and live defaults,
  so the parameter documentation cannot drift from the code.

## License

MIT. See [LICENSE](LICENSE).
