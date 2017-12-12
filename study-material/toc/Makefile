JHTML_SRCS += 500-essential-expressions-toc.jhtml
JHTML_SRCS += jpod-li-toc.jhtml
JHTML_SRCS += jpod-ui-toc.jhtml
JHTML_SRCS += jstep-toc.jhtml
JHTML_SRCS += kzm-n1g-toc.jhtml
JHTML_SRCS += kzm-n2g-toc.jhtml
JHTML_SRCS += kzm-n3g-toc.jhtml
JHTML_SRCS += mnn-int-toc.jhtml
JHTML_SRCS += mnn-toc.jhtml
JHTML_SRCS += nihongonomori-n2-niteiru-bunpou-toc.jhtml
JHTML_SRCS += nsm-n1g-toc.jhtml
JHTML_SRCS += nsm-n2g-toc.jhtml
JHTML_SRCS += nsm-n3g-toc.jhtml
JHTML_SRCS += udemy-n1-toc.jhtml
JHTML_SRCS += udemy-n2-toc.jhtml

TARGETS += $(foreach JH,$(JHTML_SRCS),$(OUTPUT)/$(subst .jhtml,.html,$(JH))) 

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
