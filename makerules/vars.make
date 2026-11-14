export DATADIR = $(ROOTDIR)/data
export EXTERNAL = $(ROOTDIR)/external
export GENDIR = $(ROOTDIR)/generated
export INCLUDEDIR = $(ROOTDIR)/includes
export OUTPUT = $(ROOTDIR)/bin
export SCRIPTDIR = $(ROOTDIR)/scripts
export GODIR = $(ROOTDIR)/go
export JAPANESE_TO_CODES = $(GODIR)/japanese-to-codes

VENV := $(ROOTDIR)/.venv
PYTHON := $(VENV)/bin/python3
PIP := $(VENV)/bin/pip
VENV_STAMP := $(VENV)/.ready

include $(MAKERULESDIR)/deps.make
