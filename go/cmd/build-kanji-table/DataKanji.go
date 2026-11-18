package main

// Ported from scripts/DataKanji.rb (reading only)
//
// The file format is a number of fields separated by ":" characters.
// The fields (in order) are:
//  - Heisig index
//  - unicode (0xNNNN)
//  - a sequence of unique keywords separated by spaces (each keyword uniquely identifies this kanji)
//  - a sequence of romanised onyomi separated by spaces
//  - a sequence of romanised kunyomi separated by spaces
//  - a sequence of romanised nanori separated by spaces
//  - a sequence of english meanings, each enclosed in {}
//  - grade in Japanese school when this kanji is learned
//  - JLPT grade (old style, 1-4)

import (
	"errors"
	"fmt"
	"os"
	"regexp"
	"strings"

	"japanese/rubycompat"
)

const (
	min_expected_fields = 8
	max_expected_fields = 9

	// I don't know what the range of Heisig frame numbers is on koohii.com.
	// 3030 is a valid frame, 3031 is not. The next frame # I've found that works
	// is 19970, but that's well beyond the Heisig range.
	// So I've picked a conservative upper limit. Anything above this is taken
	// to be a Unicode number.
	max_heisig_frame_num = 4000
)

var (
	meanings_split_re = regexp.MustCompile(`[ \t\r\n\f\v]*\}[ \t\r\n\f\v]*\{[ \t\r\n\f\v]*`)
	meanings_first_re = regexp.MustCompile(`^[ \t\r\n\f\v]*\{`)
	meanings_last_re  = regexp.MustCompile(`\}[ \t\r\n\f\v]*$`)
)

// DataKanji is a collection of kanji, in the order they were read.
type DataKanji struct {
	kanji []*Kanji
}

// replace_first is Ruby's String#sub(regexp, replacement) with a literal replacement.
func replace_first(re *regexp.Regexp, s string, replacement string) string {
	loc := re.FindStringIndex(s)
	if loc == nil {
		return s
	}
	return s[:loc[0]] + replacement + s[loc[1]:]
}

// parse_kanji_fields turns the ":"-separated fields of one line into a Kanji
// and its list of keywords. It mirrors the Ruby, in which running out of fields
// where a string is needed raises an exception (reported as a FATAL error).
func parse_kanji_fields(fields []string) (*Kanji, []string, error) {
	// Ruby's fields.shift(), which gives nil once the fields are used up.
	shift := func() (string, bool) {
		if len(fields) == 0 {
			return "", false
		}
		field := fields[0]
		fields = fields[1:]
		return field, true
	}

	field, _ := shift()
	heisig := rubycompat.ToI(field, 10) // Heisig frame number (or Unicode value ?)

	field, ok := shift()
	if !ok {
		return nil, nil, errors.New("no unicode field")
	}
	unicode := rubycompat.ToI(field, 16) // Kanji Unicode value, in hex

	var lists [4][]string // keywords, onyomi, kunyomi, nanori: split on space boundaries
	for i := range lists {
		field, ok = shift()
		if !ok {
			return nil, nil, errors.New("not enough fields")
		}
		lists[i] = rubycompat.SplitWhitespace(field)
	}
	keywords, onyomi, kunyomi, nanori := lists[0], lists[1], lists[2], lists[3]

	field, ok = shift()
	if !ok {
		return nil, nil, errors.New("no meanings field")
	}
	meanings := rubycompat.SplitRegexp(meanings_split_re, field)
	if len(meanings) == 0 {
		return nil, nil, errors.New("empty meanings field")
	}
	last := len(meanings) - 1
	meanings[0] = replace_first(meanings_first_re, meanings[0], "")      // Eliminate initial { on first meaning
	meanings[last] = replace_first(meanings_last_re, meanings[last], "") // Eliminate final } on last meaning

	grade := 0
	if field, ok = shift(); ok {
		grade = rubycompat.ToI(field, 10)
	}
	jlpt := 0
	if field, ok = shift(); ok {
		jlpt = rubycompat.ToI(field, 10)
	}

	k := &Kanji{
		english: meanings,
		heisig:  heisig,
		jlpt:    jlpt,
		jouyou:  grade,
		kunyomi: kunyomi,
		nanori:  nanori,
		onyomi:  onyomi,
		unicode: unicode,
	}
	return k, keywords, nil
}

// DataKanji_create_from_file reads a kanji data file (Ruby: DataKanji.create_from_file).
func DataKanji_create_from_file(filename string) (*DataKanji, error) {
	kanji_data := &DataKanji{}
	fatal_seen := false

	contents, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	line_num := 0
	last_heisig_frame_read := 0
	for _, line := range strings.SplitAfter(string(contents), "\n") {
		if line == "" {
			continue
		}
		line_num += 1
		line = rubycompat.Strip(rubycompat.Chomp(line))
		if line == "" {
			continue
		}

		// (The Ruby also has a test to skip commented out lines, but it can
		// never match a line that has been stripped, so it is not ported.)

		fields := rubycompat.SplitString(line, ":")
		if len(fields) < min_expected_fields || len(fields) > max_expected_fields {
			fmt.Fprintf(os.Stderr, "FATAL wrong number of fields (saw %d expected %d-%d for line #%d [%s] in %s]\n",
				len(fields), min_expected_fields, max_expected_fields, line_num, line, filename)
			fatal_seen = true
		}

		k, keywords, err := parse_kanji_fields(fields)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %s\n", err)
			fmt.Fprintf(os.Stderr, "FATAL error seen for line #%d [%s] in %s]\n", line_num, line, filename)
			fatal_seen = true
			continue
		}

		// Quick sanity checks.

		// Beyond the Heisig frame number (i.e. anything beyond max_heisig_frame_num)
		// heisig and unicode must match.
		if k.heisig > max_heisig_frame_num && k.heisig != k.unicode {
			return nil, fmt.Errorf("Heisig frame %d does not match Unicode %d on line %d", k.heisig, k.unicode, line_num)
		}

		// The heisig frame numbers should be monotonically increasing.
		// This isn't strictly necessary, but it helps keep the source file organised.
		// It also means there is no need to check for duplicate frame numbers as they cannot happen.
		if k.heisig <= last_heisig_frame_read {
			return nil, fmt.Errorf("Heisig frame %d is not greater than previous frame %d", k.heisig, last_heisig_frame_read)
		}
		last_heisig_frame_read = k.heisig

		// Keep the kanji in a slice, ordered as they come from the data file
		for _, word := range keywords {
			if err := k.add_reading(word); err != nil {
				return nil, err
			}
		}
		kanji_data.kanji = append(kanji_data.kanji, k)
	}

	if fatal_seen {
		return nil, errors.New("DataKanji: Processing failed with above errors")
	}

	return kanji_data, nil
}
