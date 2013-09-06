OUTPUT = bin

JHTML_SRCS += adjectives.jhtml
JHTML_SRCS += confusible-kanji.jhtml
JHTML_SRCS += grammar-adj-sa.jhtml
JHTML_SRCS += grammar-aida.jhtml
JHTML_SRCS += grammar-amari.jhtml
JHTML_SRCS += grammar-aru.jhtml
JHTML_SRCS += grammar-ato-de.jhtml
JHTML_SRCS += grammar-bakari.jhtml
JHTML_SRCS += grammar-dai.jhtml
JHTML_SRCS += grammar-dekakete-kuru.jhtml
JHTML_SRCS += grammar-dekiru.jhtml
JHTML_SRCS += grammar-demo.jhtml
JHTML_SRCS += grammar-deshou-ka.jhtml
JHTML_SRCS += grammar-dou.jhtml
JHTML_SRCS += grammar-giving-receiving.jhtml
JHTML_SRCS += grammar-goro.jhtml
JHTML_SRCS += grammar-hazu.jhtml
JHTML_SRCS += grammar-itte-kuru.jhtml
JHTML_SRCS += grammar-kadouka.jhtml
JHTML_SRCS += grammar-n-desu.jhtml
JHTML_SRCS += grammar-nagara.jhtml
JHTML_SRCS += grammar-particle-dake.jhtml
JHTML_SRCS += grammar-particle-e.jhtml
JHTML_SRCS += grammar-particle-mo.jhtml
JHTML_SRCS += grammar-particle-shika.jhtml
JHTML_SRCS += grammar-particle-wa.jhtml
JHTML_SRCS += grammar-phenomenon-senses-ga-suru.jhtml
JHTML_SRCS += grammar-plain-form-shi.jhtml
JHTML_SRCS += grammar-rashii.jhtml
JHTML_SRCS += grammar-sore-de.jhtml
JHTML_SRCS += grammar-sore-ni.jhtml
JHTML_SRCS += grammar-sou-desu-appearance.jhtml
JHTML_SRCS += grammar-sou-desu-hearsay.jhtml
JHTML_SRCS += grammar-tara-ii-desu-ka.jhtml
JHTML_SRCS += grammar-te-aru.jhtml
JHTML_SRCS += grammar-te-iru.jhtml
JHTML_SRCS += grammar-te-itadakemasenka.jhtml
JHTML_SRCS += grammar-te-kuru.jhtml
JHTML_SRCS += grammar-te-miru.jhtml
JHTML_SRCS += grammar-te-shimau.jhtml
JHTML_SRCS += grammar-tsukuru.jhtml
JHTML_SRCS += grammar-verb-conjugations.jhtml
JHTML_SRCS += grammar-verb-formation-passive.jhtml
JHTML_SRCS += grammar-verb-formation-potential.jhtml
JHTML_SRCS += grammar-verb-use-of-passive.jhtml
JHTML_SRCS += grammar-verb-use-of-potential.jhtml
JHTML_SRCS += grammar-you-desu.jhtml
JHTML_SRCS += grammar.jhtml
JHTML_SRCS += index.jhtml
JHTML_SRCS += jpod-absolute-beginner.jhtml
JHTML_SRCS += jpod-advanced.jhtml
JHTML_SRCS += jpod-beginner.jhtml
JHTML_SRCS += jpod-intermediate.jhtml
JHTML_SRCS += jpod-lower-intermediate.jhtml
JHTML_SRCS += jpod-miscellaneous.jhtml
JHTML_SRCS += jpod-upper-intermediate.jhtml
JHTML_SRCS += jpod.jhtml
JHTML_SRCS += kana.jhtml
JHTML_SRCS += kanji-with-a-single-reading.jhtml
JHTML_SRCS += mnn-toc.jhtml
JHTML_SRCS += mnn.jhtml
JHTML_SRCS += study-material.jhtml
JHTML_SRCS += verbs.jhtml

CSS_SRCS += japanese.css

TARGETS += $(foreach JH,$(JHTML_SRCS),$(OUTPUT)/$(subst .jhtml,.html,$(JH))) 
TARGETS += $(foreach CSS,$(CSS_SRCS),$(OUTPUT)/$(CSS))

DATA_FILES += kanji.data
DATA_FILES += references.data

SCRIPT_FILES += japanese-to-codes.rb 

GLOBAL_DEPENDENCIES += $(DATA_FILES)
GLOBAL_DEPENDENCIES += $(SCRIPT_FILES)

default: $(TARGETS)

$(OUTPUT)/%.html: %.jhtml $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	./japanese-to-codes.rb $< $@

$(OUTPUT)/%.css: %.css
	@mkdir -p $(OUTPUT)
	cp $< $@
