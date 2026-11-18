#!/bin/sh
# Checks that the Go kanji table has the same keys and code points as the generated scripts/FastKanji.rb.
#
# Run after regenerating both tables:
#   scripts/build-kanji-ruby.rb > scripts/FastKanji.rb
#   (cd go && go run ./cmd/build-kanji-table ../data/kanji.data > FastKanji.go.tmp && mv FastKanji.go.tmp FastKanji.go)

root=$(cd "$(dirname "$0")/.." && pwd)
grep -E '^ +:"' "$root/scripts/FastKanji.rb" \
    | sed -E 's/^ +:"(.*)" => \[[0-9]+, ([0-9]+),.*$/\1 \2/' | LC_ALL=C sort > /tmp/ruby-table.txt
grep -E '^	\{"' "$root/go/FastKanji.go" \
    | sed -E 's/^	\{"(.*)", ([0-9]+)\},$/\1 \2/' | LC_ALL=C sort > /tmp/go-table.txt
wc -l /tmp/ruby-table.txt /tmp/go-table.txt
if diff /tmp/ruby-table.txt /tmp/go-table.txt > /tmp/table.diff; then
    echo "kanji tables match"
else
    echo "kanji tables differ (see /tmp/table.diff)"; head -20 /tmp/table.diff; exit 1
fi
