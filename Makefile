JHTML_SRCS += adjectives.jhtml
JHTML_SRCS += confusible-kanji.jhtml
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
JHTML_SRCS += study-material.jhtml
JHTML_SRCS += verbs.jhtml

default: $(foreach JH,$(JHTML_SRCS),$(subst .jhtml,.html,$(JH)))

%.html: %.jhtml japanese-to-codes.rb
	./japanese-to-codes.rb $< $@
