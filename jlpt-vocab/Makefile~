CSS_SRCS += japanese.css

CSS_PARTIALS += $(wildcard $(CSSDIR)/_*.scss)

TARGETS += $(foreach CSS,$(CSS_SRCS),$(OUTPUT)/$(CSS))

PHONY: default

default: $(TARGETS)

$(OUTPUT)/%.css: %.scss $(CSS_PARTIALS)
	$(info OUTPUT=[$(OUTPUT)])
	@mkdir -p $(OUTPUT)
	sass --style compressed $<:$@

include $(MAKERULESDIR)/lib.make
