export DATADIR = $(ROOTDIR)/data
export EXTERNAL = $(ROOTDIR)/external
export GENDIR = $(ROOTDIR)/generated
export INCLUDEDIR = $(ROOTDIR)/includes
export OUTPUT = $(ROOTDIR)/bin
export SCRIPTDIR = $(ROOTDIR)/scripts

VENV := $(ROOTDIR)/.venv
PYTHON := $(VENV)/bin/python3
PIP := $(VENV)/bin/pip
VENV_STAMP := $(VENV)/.ready

include $(MAKERULESDIR)/deps.make
