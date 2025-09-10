default: $(OUTPUT)/onomatopoeia.gen.html

$(OUTPUT)/onomatopoeia.gen.html: $(SCRIPTDIR)/build-onomatopoeia-page.py $(DATADIR)/onomatopoeia.yaml
	@mkdir -p $(OUTPUT)
	python3 $(SCRIPTDIR)/build-onomatopoeia-page.py $(DATADIR)/onomatopoeia.yaml $@ || { rm $@; exit 1; }

include $(MAKERULESDIR)/lib.make
