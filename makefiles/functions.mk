# Reusable make functions. Included by base.mk, so consumers get these
# without an extra include line.

# Name the missing variable instead of expanding to nothing.
#   $(call require,IMAGE_NAME)
# Declare optionals as `FOO ?=`; `FOO ?= ""` assigns a literal two-character
# string that every conditional reads as non-empty, including this one.
require = $(if $(strip $($(1))),,$(error $(1) is required: make $@ $(1)=<value>))
