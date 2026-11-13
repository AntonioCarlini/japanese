package main

// Ported from scripts/KanjiSupport.rb
//
// FastKanji.rb (and its class KD) is replaced by FastKanji.go, which is
// generated from data/kanji.data by build-kanji-table and holds a sorted
// table that is searched with a binary search. Nothing is parsed at startup.

import (
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"

	"japanese/rubycompat"
)

type kanji_table_entry struct {
	key     string
	unicode int
}

// kanji_table_lookup replaces KD.instance().kanji(keyword).unicode()
func kanji_table_lookup(keyword string) (int, bool) {
	i := sort.Search(len(kanji_table), func(i int) bool { return kanji_table[i].key >= keyword })
	if i < len(kanji_table) && kanji_table[i].key == keyword {
		return kanji_table[i].unicode, true
	}
	return 0, false
}

// find_kanji_unicode_from_keyword returns the code point for a keyword.
// Like the Ruby (via KD#kanji) it reports each failed lookup on stderr.
func find_kanji_unicode_from_keyword(keyword string) (int, bool) {
	code, found := kanji_table_lookup(keyword)
	if !found {
		fmt.Fprintf(os.Stderr, "FastKanji: UNKNOWN kanji for [%s]\n", keyword)
	}
	return code, found
}

// A kanji name can be any alphabetic character (upper or lowercase) or a digit or any of a set of
// permitted symbols: ' ’ ( ) / . [ ] * - ?
var kanji_word_re = regexp.MustCompile(`[-'’()/a-zA-Z0-9.\[\]*?]+`)

var local_kanji = map[string]int{
	"hon": 0x672c, "watashi": 0x79c1,
	"chiga": 0x9055, "i": 0x884c,
	"ku":       0x6765, // reconsider
	"rai":      0x6765, // also ku
	"kae":      0x5e30, // reconsider
	"samui":    0x5bd2,
	"arinashi": 0x6709, // possess
	"namae":    0x540d, "utsuru": 0x6620,
	"yonkaku": 0x753b, // check
	"ookii":   0x5927,
	"manabu":  0x5b66,
	"ichi":    0x4e00, "ni": 0x4e8c, "san": 0x4e09, "yon": 0x56db, "go": 0x4e94,
	"roku": 0x516d, "nana": 0x4e03, "hachi": 0x516b, "kyuu": 0x4e5d, "juu": 0x5341,
	"dan":    0x6bb5,
	"kai":    0x4f1a,
	"kou":    0x884c,
	"shoku":  0x98df,
	"mi":     0x898b,
	"noma":   0x3005, // repetition symbol
	"yuubin": 0x3012, // indicates Japanese post office on a map
	"jisuma": 0x3004, // shows that a product complies with a Japanese Industrial Standard
	// NOTE: decimal in the Ruby (probably meant to be 0x3299). Preserved, so this gives &#xce3;
	"maruhi": 3299, // "secret"
}

// +
// Given a string (text), which is assumed to be the name of a single kanji, this function
// looks up that name (e.g. "person") and replaces it with the corresponding kanji (in this case 人).
// -
func convert_to_kanji(text string, raise_exception_on_error bool) (string, error) {
	kanji := local_kanji

	// This will find a valid kanji name and replace it with the result of the block processing.
	converted, err := rubycompat.GsubFunc(kanji_word_re, text, func(m []string) (string, error) {
		word := m[0]
		result := ""
		code, found := kanji[strings.ToLower(word)]
		if !found {
			code, found = find_kanji_unicode_from_keyword(strings.ToLower(word))
		}
		if !found {
			result += "&lt;UNKNOWN KANJI [" + word + "]&gt;"
			error_message := fmt.Sprintf("UNKNOWN kanji [%s] specified as [%s]", word, text)
			if raise_exception_on_error {
				return "", &ProcessingError{message: error_message}
			}
			fmt.Fprintln(os.Stderr, error_message)
		} else {
			result += jp_unicode(code)
		}
		return result, nil
	})
	if err != nil {
		return "", err
	}
	return strings.ReplaceAll(converted, "^", ""), nil
}
