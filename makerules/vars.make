export DATADIR = $(ROOTDIR)/data
export EXTERNAL = $(ROOTDIR)/external
export GENDIR = $(ROOTDIR)/generated
export INCLUDEDIR = $(ROOTDIR)/includes
export OUTPUT = $(ROOTDIR)/bin
export SCRIPTDIR = $(ROOTDIR)/scripts
export GODIR = $(ROOTDIR)/go

GO_JAPANESE_TO_CODES = $(GODIR)/japanese-to-codes

# Which program turns .jhtml into .html. Override on the command line to use something else, e.g.
#   make JAPANESE_TO_CODES=$PWD/scripts/japanese-to-codes.rb
JAPANESE_TO_CODES ?= $(GO_JAPANESE_TO_CODES)


GO_FIND_GRAMMAR_ELEMENTS = $(GODIR)/find-grammar-elements

# Which program lists the @GRMIDX entries of a .jhtml file. Override with e.g.
#   make FIND_GRAMMAR_ELEMENTS=$PWD/scripts/find-grammar-elements.rb
FIND_GRAMMAR_ELEMENTS ?= $(GO_FIND_GRAMMAR_ELEMENTS)


VENV := $(ROOTDIR)/.venv
PYTHON := $(VENV)/bin/python3
PIP := $(VENV)/bin/pip
VENV_STAMP := $(VENV)/.ready

include $(MAKERULESDIR)/deps.make
include $(MAKERULESDIR)/go.make
