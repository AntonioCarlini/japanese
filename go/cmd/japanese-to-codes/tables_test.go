package main

// Sanity checks on the program's tables. These catch typos and data problems
// that would otherwise only show up as odd output.

import (
	"strings"
	"testing"
)

// known_missing_radical_keywords lists radical keywords that are known not to
// be in kanji.data. Anything listed here is not reported by
// TestRadicalKeywordsAreInKanjiData. Add to it only deliberately.
var known_missing_radical_keywords = map[string]bool{}

// kanji_table_lookup relies on a binary search, so the table must be sorted,
// and a duplicate key would be a bug in the generator.
func TestKanjiTableIsSortedAndUnique(t *testing.T) {
	if len(kanji_table) == 0 {
		t.Fatal("kanji_table is empty")
	}
	for i := 1; i < len(kanji_table); i++ {
		if kanji_table[i-1].key >= kanji_table[i].key {
			t.Fatalf("kanji_table is not strictly sorted at entries %d and %d: %q, %q",
				i-1, i, kanji_table[i-1].key, kanji_table[i].key)
		}
	}
}

func TestKanjiTableLookupFindsEveryEntry(t *testing.T) {
	for _, e := range kanji_table {
		code, found := kanji_table_lookup(e.key)
		if !found || code != e.unicode {
			t.Errorf("kanji_table_lookup(%q) = %d, %v; want %d, true", e.key, code, found, e.unicode)
		}
	}
	if _, found := kanji_table_lookup("zzzunknown"); found {
		t.Error("kanji_table_lookup found a keyword that should not exist")
	}
}

// Every radical that takes its code point from kanji.data needs its keyword to
// be there. Each missing one prints "FastKanji: UNKNOWN kanji for [...]" on
// stderr whenever @RD is used (and, as in the Ruby, gives <UNKNOWN RADICAL>).
func TestRadicalKeywordsAreInKanjiData(t *testing.T) {
	for _, e := range radical_entries {
		if e.keyword == "" || known_missing_radical_keywords[e.keyword] {
			continue
		}
		if _, found := kanji_table_lookup(e.keyword); !found {
			t.Errorf("radical %q: keyword %q is not in kanji.data", e.english, e.keyword)
		}
	}
}

func TestRadicalEntries(t *testing.T) {
	seen := map[string]bool{}
	for _, e := range radical_entries {
		if seen[e.english] {
			t.Errorf("radical %q appears more than once (the later one would silently win)", e.english)
		}
		seen[e.english] = true

		if e.keyword == "" && e.unicode <= 0 {
			t.Errorf("radical %q has neither a keyword nor a code point", e.english)
		}
		if e.keyword != "" && e.unicode != 0 {
			t.Errorf("radical %q has both a keyword and a code point", e.english)
		}
		if e.reading == "" {
			t.Errorf("radical %q has no reading", e.english)
		}
	}
}

// Every command must map to a handler that exists.
func TestCommandTable(t *testing.T) {
	for command, op := range command_to_op {
		if _, found := op_table[op]; !found {
			t.Errorf("command %q maps to %q, which is not in op_table", command, op)
		}
	}
}

// Every command handled by process_empty_code needs a case in
// process_empty_code_helper, or its output is an <UNKNOWN @code> marker.
func TestEmptyCodeHelperKnowsEveryCode(t *testing.T) {
	for command, op := range command_to_op {
		if op != "process_empty_code" {
			continue
		}
		got, err := process_empty_code_helper(command)
		if err != nil {
			t.Errorf("process_empty_code_helper(%q): %v", command, err)
		} else if strings.HasPrefix(got, "&lt;UNKNOWN @code") {
			t.Errorf("process_empty_code_helper(%q) has no case for this code", command)
		}
	}
}
