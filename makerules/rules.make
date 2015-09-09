$(GENDIR)/%.jhtml.grmidx: %.jhtml $(GLOBAL_DEPENDENCIES) $(SCRIPTDIR)/find-grammar-elements.rb
	@mkdir -p $(GENDIR)
	@$(SCRIPTDIR)/find-grammar-elements.rb --include=$(INCLUDEDIR) $< > $@

$(OUTPUT)/%.html: %.jhtml $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/japanese-to-codes.rb $< > $@ --data=$(DATADIR) --include=$(INCLUDEDIR) || rm $@
