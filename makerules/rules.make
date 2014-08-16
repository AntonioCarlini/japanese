$(OUTPUT)/%.html: %.jhtml $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/japanese-to-codes.rb $< > $@
