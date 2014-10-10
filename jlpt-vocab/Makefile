TARGETS += $(OUTPUT)/N4-vocabulary-with-annotated-kanji.html

TARGETS += $(OUTPUT)/N1-cumulative-vocabulary-with-annotated-kanji.html
TARGETS += $(OUTPUT)/N2-cumulative-vocabulary-with-annotated-kanji.html
TARGETS += $(OUTPUT)/N3-cumulative-vocabulary-with-annotated-kanji.html

TARGETS += $(OUTPUT)/N1-level-vocabulary-with-annotated-kanji.html
TARGETS += $(OUTPUT)/N2-level-vocabulary-with-annotated-kanji.html
TARGETS += $(OUTPUT)/N3-level-vocabulary-with-annotated-kanji.html

VOCAB_L_SRCS += $(EXTERNAL)/VocabList.N1.mht
VOCAB_L_SRCS += $(EXTERNAL)/VocabList.N2.mht
VOCAB_L_SRCS += $(EXTERNAL)/VocabList.N3.mht

VOCAB_C_SRCS += $(EXTERNAL)/VocabList.C.N1toN5.mht
VOCAB_C_SRCS += $(EXTERNAL)/VocabList.C.N2toN5.mht
VOCAB_C_SRCS += $(EXTERNAL)/VocabList.C.N3toN5.mht

$(OUTPUT)/N1-cumulative-vocabulary-with-annotated-kanji.html: $(EXTERNAL)/VocabList.C.N1toN5.mht $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/build-kanji-vocab-list-by-jlpt.rb N1 $< $(DATADIR)/kanji.data > $@

$(OUTPUT)/N2-cumulative-vocabulary-with-annotated-kanji.html: $(EXTERNAL)/VocabList.C.N2toN5.mht $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/build-kanji-vocab-list-by-jlpt.rb N2 $< $(DATADIR)/kanji.data > $@

$(OUTPUT)/N3-cumulative-vocabulary-with-annotated-kanji.html: $(EXTERNAL)/VocabList.C.N3toN5.mht $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/build-kanji-vocab-list-by-jlpt.rb N3 $< $(DATADIR)/kanji.data > $@

$(OUTPUT)/N1-level-vocabulary-with-annotated-kanji.html: $(EXTERNAL)/VocabList.N1.mht $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/build-kanji-vocab-list-by-jlpt.rb N1 $< $(DATADIR)/kanji.data > $@

$(OUTPUT)/N2-level-vocabulary-with-annotated-kanji.html: $(EXTERNAL)/VocabList.N2.mht $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/build-kanji-vocab-list-by-jlpt.rb N2 $< $(DATADIR)/kanji.data > $@

$(OUTPUT)/N3-level-vocabulary-with-annotated-kanji.html: $(EXTERNAL)/VocabList.N3.mht $(GLOBAL_DEPENDENCIES)
	@mkdir -p $(OUTPUT)
	$(SCRIPTDIR)/build-kanji-vocab-list-by-jlpt.rb N3 $< $(DATADIR)/kanji.data > $@

$(OUTPUT)/N4-vocabulary-with-annotated-kanji.html: N4-vocabulary-with-annotated-kanji.html
	@mkdir -p $(OUTPUT)
	cp $< $@

default: $(TARGETS)

include $(MAKERULESDIR)/lib.make
