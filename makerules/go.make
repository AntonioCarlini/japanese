# FastKanji.go is generated from kanji.data, and is always kept up to date, whichever
# japanese-to-codes is in use, so that it is not forgotten at commit time.
# The Go program is only built for the pages if it is the one selected by JAPANESE_TO_CODES.

GO_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/*.go $(GODIR)/rubycompat/*.go)
KANJI_TABLE_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/build-kanji-table/*.go $(GODIR)/rubycompat/*.go)

$(GODIR)/FastKanji.go: $(DATADIR)/kanji.data $(KANJI_TABLE_SOURCES)
	cd $(GODIR) && go run ./build-kanji-table $(DATADIR)/kanji.data > FastKanji.go.tmp \
		|| { rm -f FastKanji.go.tmp; exit 1; }
	mv $(GODIR)/FastKanji.go.tmp $@

$(GO_JAPANESE_TO_CODES): $(GO_SOURCES) $(GODIR)/FastKanji.go
	cd $(GODIR) && go build -o japanese-to-codes .
	touch $@

# What the top-level make builds once, before it starts any sub-make (see super.make):
#  - FastKanji.go, always;
#  - the Go program, but only if JAPANESE_TO_CODES is set to it (this is empty in a Ruby build).
GO_PREREQS := $(GODIR)/FastKanji.go $(filter $(GO_JAPANESE_TO_CODES),$(JAPANESE_TO_CODES))

.PHONY: go-tools
go-tools: $(GO_JAPANESE_TO_CODES)
