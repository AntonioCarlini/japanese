JHTML_SRCS += adjectives.jhtml
JHTML_SRCS += confusible-kanji.jhtml
JHTML_SRCS += index.jhtml
JHTML_SRCS += kana.jhtml
JHTML_SRCS += kanji-with-a-single-reading.jhtml
JHTML_SRCS += verbs.jhtml

TARGETS += $(foreach JH,$(JHTML_SRCS),$(OUTPUT)/$(subst .jhtml,.html,$(JH))) 

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
