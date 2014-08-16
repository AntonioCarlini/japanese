ifeq ($(origin MAKERULESDIR), undefined)
export ROOTDIR := $(CURDIR)
export MAKERULESDIR := $(CURDIR)/$(dir $(lastword $(MAKEFILE_LIST)))
endif

include $(MAKERULESDIR)/vars.make

COMPONENT_MAKEFILES = $(foreach component,$(COMPONENTS),$(patsubst %,%.make,$(component)))

SUBDIR_MAKEFILES = $(foreach subdir,$(SUBDIRS),$(patsubst %,%,$(subdir)))

$(COMPONENT_MAKEFILES):
	$(info executing [make -f $@])
	$(MAKE) -f $@

$(SUBDIR_MAKEFILES):
	$(info executing [make -C $@])
	$(MAKE) -C $@

.PHONY: all_subdir_makefiles $(SUBDIR_MAKEFILES)

.PHONY: all_component_makefiles $(COMPONENT_MAKEFILES)

all_component_makefiles: $(COMPONENT_MAKEFILES)

all_subdir_makefiles: $(SUBDIR_MAKEFILES)

default: all_component_makefiles

default: all_subdir_makefiles

.DEFAULT_GOAL := default
