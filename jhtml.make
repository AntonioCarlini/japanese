JHTML_SRCS += adjectives.jhtml
JHTML_SRCS += confusible-kanji.jhtml
JHTML_SRCS += index.jhtml
JHTML_SRCS += kana.jhtml
JHTML_SRCS += kanji-with-a-single-reading.jhtml
JHTML_SRCS += verbs.jhtml

GRMIDX_SRCS += $(addprefix $(GENDIR)/,$(addsuffix .grmidx,$(JHTML_SRCS)))

TARGETS += $(foreach JH,$(JHTML_SRCS),$(OUTPUT)/$(subst .jhtml,.html,$(JH))) 
#TARGETS += $(OUTPUT)/grammar-index.html

default: $(TARGETS)

$(GENDIR)/%.jhtml.grmidx: %.jhtml $(GLOBAL_DEPENDENCIES) $(SCRIPTDIR)/find-grammar-elements.rb
	@mkdir -p $(GENDIR)
	@$(SCRIPTDIR)/find-grammar-elements.rb $< > $@

$(OUTPUT)/grammar-index.html: $(GRMIDX_SRCS) $(SCRIPTDIR)/build-grammar-index.rb
	@mkdir -p $(OUTPUT)
	@$(SCRIPTDIR)/build-grammar-index.rb $(GRMIDX_SRCS) > $@ && echo "Successfully built $@"

include $(MAKERULESDIR)/lib.make
