# FastKanji.go is generated from kanji.data, and is always kept up to date, whichever
# japanese-to-codes is in use, so that it is not forgotten at commit time.
# The Go program is only built for the pages if it is the one selected by JAPANESE_TO_CODES.

GO_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/cmd/japanese-to-codes/*.go $(GODIR)/internal/rubycompat/*.go)
FASTKANJI_GO := $(GODIR)/cmd/japanese-to-codes/FastKanji.go
KANJI_TABLE_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/cmd/build-kanji-table/*.go $(GODIR)/internal/rubycompat/*.go)

$(FASTKANJI_GO): $(DATADIR)/kanji.data $(KANJI_TABLE_SOURCES)
	cd $(GODIR) && go run ./cmd/build-kanji-table $(DATADIR)/kanji.data > $@.tmp \
		|| { rm -f $@.tmp; exit 1; }
	mv $@.tmp $@

$(GO_JAPANESE_TO_CODES): $(GO_SOURCES) $(FASTKANJI_GO)
	cd $(GODIR) && go build -o japanese-to-codes ./cmd/japanese-to-codes
	touch $@

FIND_GRAMMAR_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/cmd/find-grammar-elements/*.go $(GODIR)/internal/rubycompat/*.go)

$(GO_FIND_GRAMMAR_ELEMENTS): $(FIND_GRAMMAR_SOURCES)
	cd $(GODIR) && go build -o find-grammar-elements ./cmd/find-grammar-elements
	touch $@

# What the top-level make builds once, before it starts any sub-make (see super.make):
#  - FastKanji.go, always;
#  - the Go program, but only if JAPANESE_TO_CODES is set to it (this is empty in a Ruby build).
GO_PREREQS := $(FASTKANJI_GO) $(filter $(GO_JAPANESE_TO_CODES),$(JAPANESE_TO_CODES))
GO_PREREQS += $(filter $(GO_FIND_GRAMMAR_ELEMENTS),$(FIND_GRAMMAR_ELEMENTS))

.PHONY: go-tools
go-tools: $(GO_JAPANESE_TO_CODES)
