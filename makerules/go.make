# FastKanji.go is generated from kanji.data, and is always kept up to date, whichever
# japanese-to-codes is in use, so that it is not forgotten at commit time.
# The Go program is only built for the pages if it is the one selected by JAPANESE_TO_CODES.

GO_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/*.go $(GODIR)/internal/rubycompat/*.go)
KANJI_TABLE_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/cmd/build-kanji-table/*.go $(GODIR)/internal/rubycompat/*.go)

$(GODIR)/FastKanji.go: $(DATADIR)/kanji.data $(KANJI_TABLE_SOURCES)
	cd $(GODIR) && go run ./cmd/build-kanji-table $(DATADIR)/kanji.data > FastKanji.go.tmp \
		|| { rm -f FastKanji.go.tmp; exit 1; }
	mv $(GODIR)/FastKanji.go.tmp $@

$(GO_JAPANESE_TO_CODES): $(GO_SOURCES) $(GODIR)/FastKanji.go
	cd $(GODIR) && go build -o japanese-to-codes .
	touch $@

FIND_GRAMMAR_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/cmd/find-grammar-elements/*.go $(GODIR)/internal/rubycompat/*.go)

$(GO_FIND_GRAMMAR_ELEMENTS): $(FIND_GRAMMAR_SOURCES)
	cd $(GODIR) && go build -o find-grammar-elements ./cmd/find-grammar-elements
	touch $@

# What the top-level make builds once, before it starts any sub-make (see super.make):
#  - FastKanji.go, always;
#  - the Go program, but only if JAPANESE_TO_CODES is set to it (this is empty in a Ruby build).
GO_PREREQS := $(GODIR)/FastKanji.go $(filter $(GO_JAPANESE_TO_CODES),$(JAPANESE_TO_CODES))
GO_PREREQS += $(filter $(GO_FIND_GRAMMAR_ELEMENTS),$(FIND_GRAMMAR_ELEMENTS))

.PHONY: go-tools
go-tools: $(GO_JAPANESE_TO_CODES)
