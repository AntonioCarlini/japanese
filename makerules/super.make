ifeq ($(origin MAKERULESDIR), undefined)
export ROOTDIR := $(CURDIR)
export MAKERULESDIR := $(CURDIR)/$(dir $(lastword $(MAKEFILE_LIST)))
endif

include $(MAKERULESDIR)/vars.make

COMPONENT_MAKEFILES = $(foreach component,$(COMPONENTS),$(patsubst %,%.make,$(component)))

SUBDIR_MAKEFILES = $(foreach subdir,$(SUBDIRS),$(patsubst %,%,$(subdir)))

$(COMPONENT_MAKEFILES):
	@$(MAKE) -f $@

$(SUBDIR_MAKEFILES):
	@$(MAKE) -C $@ || exit 1

# Build FastKanji.go (and the Go program, if it is in use) once, here, before any sub-make starts.
# Sub-makes run in parallel with -j and would otherwise all try to rebuild them at the same time.
$(COMPONENT_MAKEFILES) $(SUBDIR_MAKEFILES): $(GO_PREREQS)

# The sub-makes run $(PYTHON), so the venv must exist before any of them starts.
$(COMPONENT_MAKEFILES) $(SUBDIR_MAKEFILES): $(VENV_STAMP)

.PHONY: all_subdir_makefiles $(SUBDIR_MAKEFILES)

.PHONY: all_component_makefiles $(COMPONENT_MAKEFILES)

all_component_makefiles: $(COMPONENT_MAKEFILES)

all_subdir_makefiles: $(SUBDIR_MAKEFILES)

default: all_component_makefiles

default: all_subdir_makefiles

default: $(VENV_STAMP)

include $(MAKERULESDIR)/rules.make

.DEFAULT_GOAL := default
