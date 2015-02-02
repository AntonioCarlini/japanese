TARGETS += $(OUTPUT)/radicals.gen.html

$(GENDIR)/radicals.gen.jhtml: $(SCRIPTDIR)/build-radicals-page.rb $(SCRIPTDIR)/RadicalSupport.rb
	@mkdir -p $(GENDIR)
	$(SCRIPTDIR)/build-radicals-page.rb > $@

$(OUTPUT)/radicals.gen.html: $(GENDIR)/radicals.gen.jhtml
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/japanese-to-codes.rb $< > $@

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
