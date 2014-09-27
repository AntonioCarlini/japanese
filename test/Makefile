TEST_JHTML_SRCS += test-include.jhtml
TEST_JHTML_SRCS += test-kana.jhtml
TEST_JHTML_SRCS += test.jhtml

TEST_TARGETS += $(foreach JH,$(TEST_JHTML_SRCS),$(OUTPUT)/$(subst .jhtml,.html,$(JH))) 


TARGETS += $(TEST_TARGETS)

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
