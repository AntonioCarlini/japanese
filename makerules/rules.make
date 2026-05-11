$(GENDIR)/%.jhtml.grmidx: %.jhtml $(GLOBAL_DEPENDENCIES) $(SCRIPTDIR)/find-grammar-elements.rb
	@mkdir -p $(GENDIR)
	@$(SCRIPTDIR)/find-grammar-elements.rb --include=$(INCLUDEDIR) $< > $@

$(OUTPUT)/%.html: %.jhtml $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/japanese-to-codes.rb $< > $@ --data=$(DATADIR) --include=$(INCLUDEDIR) --strict-fail-on-error || { rm $@; exit 1; }

$(VENV_STAMP): $(ROOTDIR)/requirements.txt
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(PIP) install --upgrade pip setuptools >/dev/null
	@$(PIP) install -r $(ROOTDIR)/requirements.txt
	@touch $(VENV_STAMP)
