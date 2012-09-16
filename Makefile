JHTML_SRCS += adjectives.jhtml
JHTML_SRCS += confusible-kanji.jhtml
JHTML_SRCS += index.jhtml
JHTML_SRCS += jpod.jhtml
JHTML_SRCS += kana.jhtml
JHTML_SRCS += mnn.jhtml
JHTML_SRCS += study-material.jhtml
JHTML_SRCS += verbs.jhtml

default: $(foreach JH,$(JHTML_SRCS),$(subst .jhtml,.html,$(JH)))

%.html: %.jhtml japanese-to-codes.rb
	./japanese-to-codes.rb $< $@
