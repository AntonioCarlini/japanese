GO_SOURCES := $(GODIR)/go.mod $(wildcard $(GODIR)/*.go $(GODIR)/rubycompat/*.go)
KANJI_TABLE_SOURCES := $(wildcard $(GODIR)/build-kanji-table/*.go $(GODIR)/rubycompat/*.go)

# The kanji table is generated from kanji.data (replaces build-kanji-ruby.rb).
$(GODIR)/FastKanji.go: $(DATADIR)/kanji.data $(KANJI_TABLE_SOURCES)
	cd $(GODIR) && go run ./build-kanji-table $(DATADIR)/kanji.data > FastKanji.go.tmp \
		|| { rm -f FastKanji.go.tmp; exit 1; }
	mv $(GODIR)/FastKanji.go.tmp $@

$(JAPANESE_TO_CODES): $(GO_SOURCES) $(GODIR)/FastKanji.go
	cd $(GODIR) && go build -o japanese-to-codes .
