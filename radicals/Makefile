TARGETS += $(OUTPUT)/radicals.gen.html

$(GENDIR)/radicals.gen.jhtml: $(SCRIPTDIR)/build-radicals-page.rb $(SCRIPTDIR)/RadicalSupport.rb
	@mkdir -p $(GENDIR)
	$(SCRIPTDIR)/build-radicals-page.rb > $@

$(OUTPUT)/radicals.gen.html: $(GENDIR)/radicals.gen.jhtml $(JAPANESE_TO_CODES)
	@mkdir -p $(OUTPUT)
	$(JAPANESE_TO_CODES) $< > $@

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
