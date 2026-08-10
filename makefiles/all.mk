# Convenience: include every module. Consumers wanting a subset include
# core.mk plus the modules they use.

OP_MAKEFILES_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include $(OP_MAKEFILES_DIR)core.mk
include $(OP_MAKEFILES_DIR)go.mk
include $(OP_MAKEFILES_DIR)image.mk
include $(OP_MAKEFILES_DIR)scan.mk
include $(OP_MAKEFILES_DIR)chart.mk
include $(OP_MAKEFILES_DIR)changelog.mk
include $(OP_MAKEFILES_DIR)openapi.mk
include $(OP_MAKEFILES_DIR)otel.mk
include $(OP_MAKEFILES_DIR)gitignore.mk
include $(OP_MAKEFILES_DIR)precommit.mk
