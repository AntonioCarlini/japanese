TARGETS += $(OUTPUT)/heisig.gen.html
TARGETS += $(OUTPUT)/koohii-stories.gen.html

$(GENDIR)/heisig.gen.jhtml: $(SCRIPTDIR)/build-heisig-page.rb $(DATADIR)/kanji.data
	@mkdir -p $(GENDIR)
	$(SCRIPTDIR)/build-heisig-page.rb $(DATADIR)/kanji.data > $@ || { rm $@; exit 1; }

$(OUTPUT)/heisig.gen.html: $(GENDIR)/heisig.gen.jhtml
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/japanese-to-codes.rb $< > $@ || { rm $@; exit 1; }

$(GENDIR)/koohii-stories.gen.jhtml: $(SCRIPTDIR)/koohii-stories.py $(EXTERNAL)/my_stories.csv
	@mkdir -p $(GENDIR)
	python3 $(SCRIPTDIR)/koohii-stories.py $(EXTERNAL)/my_stories.csv $@ || { rm $@; exit 1; }

$(OUTPUT)/koohii-stories.gen.html: $(GENDIR)/koohii-stories.gen.jhtml
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/japanese-to-codes.rb --strict-fail-on-error $< > $@ || { rm $@; exit 1; }

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
