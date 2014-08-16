JHTML_SRCS += kzm-n2g-toc.jhtml
JHTML_SRCS += kzm-n3g-toc.jhtml
JHTML_SRCS += mnn-int-toc.jhtml
JHTML_SRCS += mnn-toc.jhtml
JHTML_SRCS += nsm-n2g-toc.jhtml
JHTML_SRCS += nsm-n3g-toc.jhtml

TARGETS += $(foreach JH,$(JHTML_SRCS),$(OUTPUT)/$(subst .jhtml,.html,$(JH))) 

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
