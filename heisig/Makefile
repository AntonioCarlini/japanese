TARGETS += $(OUTPUT)/heisig.gen.html

$(GENDIR)/heisig.gen.jhtml : $(SCRIPTDIR)/build-heisig-page.rb
	@mkdir -p $(GENDIR)
	$(SCRIPTDIR)/build-heisig-page.rb > $@

$(OUTPUT)/heisig.gen.html : $(GENDIR)/heisig.gen.jhtml
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/japanese-to-codes.rb $< > $@

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
