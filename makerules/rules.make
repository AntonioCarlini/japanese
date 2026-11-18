$(GENDIR)/%.jhtml.grmidx: %.jhtml $(FIND_GRAMMAR_ELEMENTS)
	@mkdir -p $(GENDIR)
	@$(FIND_GRAMMAR_ELEMENTS) --include=$(INCLUDEDIR) $< > $@ || { rm -f $@; exit 1; }

$(OUTPUT)/%.html: %.jhtml $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(JAPANESE_TO_CODES) $< > $@ --data=$(DATADIR) --include=$(INCLUDEDIR) --strict-fail-on-error || { rm $@; exit 1; }

$(VENV_STAMP): $(ROOTDIR)/requirements.txt
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(PIP) install --upgrade pip setuptools >/dev/null
	@$(PIP) install -r $(ROOTDIR)/requirements.txt
	@touch $(VENV_STAMP)
