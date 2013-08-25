OUTPUT = bin

JHTML_SRCS += adjectives.jhtml
JHTML_SRCS += confusible-kanji.jhtml
JHTML_SRCS += kanji-with-a-single-reading.jhtml
JHTML_SRCS += grammar.jhtml
JHTML_SRCS += grammar-adj-sa.jhtml
JHTML_SRCS += grammar-deshou-ka.jhtml
JHTML_SRCS += grammar-kadouka.jhtml
JHTML_SRCS += grammar-rashii.jhtml
JHTML_SRCS += grammar-te-miru.jhtml
JHTML_SRCS += grammar-verb-conjugations.jhtml
JHTML_SRCS += index.jhtml
JHTML_SRCS += jpod.jhtml
JHTML_SRCS += jpod-absolute-beginner.jhtml
JHTML_SRCS += jpod-advanced.jhtml
JHTML_SRCS += jpod-beginner.jhtml
JHTML_SRCS += jpod-intermediate.jhtml
JHTML_SRCS += jpod-lower-intermediate.jhtml
JHTML_SRCS += jpod-miscellaneous.jhtml
JHTML_SRCS += jpod-upper-intermediate.jhtml
JHTML_SRCS += kana.jhtml
JHTML_SRCS += mnn.jhtml
JHTML_SRCS += mnn-toc.jhtml
JHTML_SRCS += study-material.jhtml
JHTML_SRCS += verbs.jhtml

CSS_SRCS += japanese.css

TARGETS += $(foreach JH,$(JHTML_SRCS),$(OUTPUT)/$(subst .jhtml,.html,$(JH))) 
TARGETS += $(foreach CSS,$(CSS_SRCS),$(OUTPUT)/$(CSS))

default: $(TARGETS)

$(OUTPUT)/%.html: %.jhtml japanese-to-codes.rb
	@mkdir -p $(OUTPUT)
	./japanese-to-codes.rb $< $@

$(OUTPUT)/%.css: %.css
	@mkdir -p $(OUTPUT)
	cp $< $@
