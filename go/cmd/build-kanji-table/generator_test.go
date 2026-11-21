package main

// Unit tests for the generator's parts. (main_test.go compares the whole
// generator with the Ruby one.)

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"japanese/internal/rubycompat"
)

func equal_slices(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// capture_stderr returns everything that f writes to os.Stderr.
func capture_stderr(t *testing.T, f func()) string {
	t.Helper()
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	saved := os.Stderr
	os.Stderr = w
	done := make(chan string)
	go func() {
		var buf bytes.Buffer
		io.Copy(&buf, r)
		done <- buf.String()
	}()
	f()
	os.Stderr = saved
	w.Close()
	out := <-done
	r.Close()
	return out
}

func fields_of(line string) []string {
	return rubycompat.SplitString(line, ":")
}

func TestParseKanjiFields(t *testing.T) {
	tests := []struct {
		name                                     string
		line                                     string
		heisig, unicode                          int
		keywords, onyomi, kunyomi, nanori, means []string
		jouyou, jlpt                             int
	}{
		{"typical",
			`    1 :  0x4e00 : hito- hito.tsu :  ICHI ITSU :  hito- hito.tsu :  kazu i :  {one} {one radical (no.1)} :  1 :  4`,
			1, 0x4e00,
			[]string{"hito-", "hito.tsu"}, []string{"ICHI", "ITSU"}, []string{"hito-", "hito.tsu"}, []string{"kazu", "i"},
			[]string{"one", "one radical (no.1)"}, 1, 4},
		{"empty keywords and nanori",
			`   11 :  0x53e3 :  :  KOU KU :  kuchi :   :  {mouth} :  1 :  4`,
			11, 0x53e3,
			nil, []string{"KOU", "KU"}, []string{"kuchi"}, nil,
			[]string{"mouth"}, 1, 4},
		{"a meaning with a space",
			`   14 :  0x7530 :  :  DEN :  ta :  inaka oka :  {rice field} {rice paddy} :  1 :  3`,
			14, 0x7530,
			nil, []string{"DEN"}, []string{"ta"}, []string{"inaka", "oka"},
			[]string{"rice field", "rice paddy"}, 1, 3},
		{"eight fields: no JLPT grade",
			`    9 :  0x4e5d :  :  KYUU :  kokono :  :  {nine} :  1`,
			9, 0x4e5d,
			nil, []string{"KYUU"}, []string{"kokono"}, nil,
			[]string{"nine"}, 1, 0},
		{"seven fields: no grades at all",
			`    9 :  0x4e5d :  :  KYUU :  kokono :  :  {nine}`,
			9, 0x4e5d,
			nil, []string{"KYUU"}, []string{"kokono"}, nil,
			[]string{"nine"}, 0, 0},
	}
	for _, tt := range tests {
		k, keywords, err := parse_kanji_fields(fields_of(tt.line))
		if err != nil {
			t.Errorf("%s: unexpected error %v", tt.name, err)
			continue
		}
		if k.heisig != tt.heisig || k.unicode != tt.unicode || k.jouyou != tt.jouyou || k.jlpt != tt.jlpt {
			t.Errorf("%s: heisig %d, unicode %#x, jouyou %d, jlpt %d; want %d, %#x, %d, %d",
				tt.name, k.heisig, k.unicode, k.jouyou, k.jlpt, tt.heisig, tt.unicode, tt.jouyou, tt.jlpt)
		}
		if !equal_slices(keywords, tt.keywords) {
			t.Errorf("%s: keywords %q, want %q", tt.name, keywords, tt.keywords)
		}
		if !equal_slices(k.onyomi, tt.onyomi) {
			t.Errorf("%s: onyomi %q, want %q", tt.name, k.onyomi, tt.onyomi)
		}
		if !equal_slices(k.kunyomi, tt.kunyomi) {
			t.Errorf("%s: kunyomi %q, want %q", tt.name, k.kunyomi, tt.kunyomi)
		}
		if !equal_slices(k.nanori, tt.nanori) {
			t.Errorf("%s: nanori %q, want %q", tt.name, k.nanori, tt.nanori)
		}
		if !equal_slices(k.english, tt.means) {
			t.Errorf("%s: english %q, want %q", tt.name, k.english, tt.means)
		}
	}
}

// Where the Ruby runs out of fields and crashes on a nil, the Go reports an error.
func TestParseKanjiFieldsErrors(t *testing.T) {
	tests := []struct {
		name   string
		fields []string
		want   string
	}{
		{"no unicode", []string{"1"}, "no unicode field"},
		{"no keywords", []string{"1", "0x4e00"}, "not enough fields"},
		{"no kunyomi", []string{"1", "0x4e00", "", "ICHI"}, "not enough fields"},
		{"no meanings", []string{"1", "0x4e00", "", "ICHI", "hito", ""}, "no meanings field"},
		{"empty meanings", []string{"1", "0x4e00", "", "ICHI", "hito", "", "", "1", "4"}, "empty meanings field"},
	}
	for _, tt := range tests {
		_, _, err := parse_kanji_fields(tt.fields)
		if err == nil {
			t.Errorf("%s: expected an error", tt.name)
		} else if err.Error() != tt.want {
			t.Errorf("%s: error %q, want %q", tt.name, err, tt.want)
		}
	}
}

func TestReplaceFirst(t *testing.T) {
	first := regexp.MustCompile(`^\s*\{`)
	last := regexp.MustCompile(`\}\s*$`)
	tests := []struct {
		re       *regexp.Regexp
		in, want string
	}{
		{first, "  {one", "one"},
		{first, "one", "one"},
		{first, "{{x", "{x"}, // only the first match is replaced
		{last, "one} ", "one"},
		{last, "one", "one"},
		{last, "a}b}", "a}b"},
	}
	for _, tt := range tests {
		if got := replace_first(tt.re, tt.in, ""); got != tt.want {
			t.Errorf("replace_first(%v, %q) = %q, want %q", tt.re, tt.in, got, tt.want)
		}
	}
}

func TestAddReading(t *testing.T) {
	k := &Kanji{heisig: 1, unicode: 0x4e00, onyomi: []string{"ICHI", "ITSU"}, kunyomi: []string{"hito"}}
	for _, reading := range []string{"ICHI", "hito"} {
		if err := k.add_reading(reading); err != nil {
			t.Errorf("add_reading(%q): unexpected error %v", reading, err)
		}
	}
	if want := []string{"ICHI", "hito"}; !equal_slices(k.idents, want) {
		t.Errorf("idents = %q, want %q", k.idents, want)
	}

	var err error
	stderr := capture_stderr(t, func() { err = k.add_reading("zzz") })
	if err == nil || err.Error() != "Claimed reading [zzz] for [1] [19968] is wrong" {
		t.Errorf("err = %v", err)
	}
	if want := "ONYOMI:  [ICHI ITSU]\nKUNYOMI: [hito]\n"; stderr != want {
		t.Errorf("stderr = %q, want %q", stderr, want)
	}
	if len(k.idents) != 2 {
		t.Errorf("a rejected reading was recorded: %q", k.idents)
	}
}

func new_kanji(heisig int, unicode int, english ...string) *Kanji {
	return &Kanji{heisig: heisig, unicode: unicode, english: english}
}

func TestBuildTable(t *testing.T) {
	tests := []struct {
		name     string
		kanji    []*Kanji
		want     []table_entry
		warnings string
	}{
		{"sorted by key",
			[]*Kanji{new_kanji(1, 100, "two"), new_kanji(2, 200, "one")},
			[]table_entry{{"one", 200}, {"two", 100}}, ""},
		{"spaces and case",
			[]*Kanji{new_kanji(1, 100, "Old Man", "elder")},
			[]table_entry{{"old*man", 100}}, ""},
		{"later meanings give no keys, and do not block other kanji",
			[]*Kanji{new_kanji(1, 100, "alpha", "beta"), new_kanji(2, 200, "beta")},
			[]table_entry{{"alpha", 100}, {"beta", 200}}, ""},
		{"duplicate first meaning",
			[]*Kanji{new_kanji(1, 100, "one"), new_kanji(2, 200, "one", "single")},
			[]table_entry{{"one", 100}},
			"WARNING: seen [one] again; ignoring this for [2], already stored for [1]\n" +
				"WARNING: 1 duplicates seen\n"},
		{"two duplicates, both against the first",
			[]*Kanji{new_kanji(1, 100, "one"), new_kanji(2, 200, "one"), new_kanji(3, 300, "one")},
			[]table_entry{{"one", 100}},
			"WARNING: seen [one] again; ignoring this for [2], already stored for [1]\n" +
				"WARNING: seen [one] again; ignoring this for [3], already stored for [1]\n" +
				"WARNING: 2 duplicates seen\n"},
		{"first meaning without letters collides with itself",
			[]*Kanji{new_kanji(1, 100, "one"), new_kanji(5, 500, "100", "hundred")},
			[]table_entry{{"one", 100}},
			"WARNING: seen [100] again; ignoring this for [5], already stored for [5]\n" +
				"WARNING: 1 duplicates seen\n"},
	}
	for _, tt := range tests {
		var warnings bytes.Buffer
		got := build_table(&DataKanji{kanji: tt.kanji}, &warnings)
		if len(got) != len(tt.want) {
			t.Errorf("%s: got %v, want %v", tt.name, got, tt.want)
		} else {
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("%s: entry %d is %v, want %v", tt.name, i, got[i], tt.want[i])
				}
			}
		}
		if warnings.String() != tt.warnings {
			t.Errorf("%s: warnings %q, want %q", tt.name, warnings.String(), tt.warnings)
		}
	}
}

func TestWriteTable(t *testing.T) {
	table := []table_entry{{"café", 20108}, {"one", 19968}, {`say "hi"`, 7}}
	var out bytes.Buffer
	write_table(&out, "kanji.data", table)

	want := "// Code generated by build-kanji-table from kanji.data; DO NOT EDIT.\n" +
		"\n" +
		"package main\n" +
		"\n" +
		"var kanji_table = []kanji_table_entry{\n" +
		"\t{\"café\", 20108},\n" +
		"\t{\"one\", 19968},\n" +
		"\t{\"say \\\"hi\\\"\", 7},\n" +
		"}\n"
	if out.String() != want {
		t.Errorf("output differs:\n%s\nwant:\n%s", out.String(), want)
	}

	// What is written can be read back (this uses the reader from main_test.go).
	parsed, err := parse_go_table(out.String())
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range table {
		if parsed[e.key] != e.unicode {
			t.Errorf("reading the table back: %q is %d, want %d", e.key, parsed[e.key], e.unicode)
		}
	}
}

func TestDataKanjiCreateFromFile(t *testing.T) {
	data, err := DataKanji_create_from_file(filepath.Join("testdata", "cases", "basic", "kanji.data"))
	if err != nil {
		t.Fatal(err)
	}
	if len(data.kanji) != 7 {
		t.Fatalf("read %d kanji, want 7", len(data.kanji))
	}
	first := data.kanji[0]
	if first.heisig != 1 || first.english[0] != "one" {
		t.Errorf("first kanji: heisig %d, english %q", first.heisig, first.english)
	}
	// The keywords field becomes the kanji's idents (via add_reading).
	if want := []string{"hito-", "hito.tsu"}; !equal_slices(first.idents, want) {
		t.Errorf("idents = %q, want %q", first.idents, want)
	}
	if last := data.kanji[6]; last.heisig != 29 || last.unicode != 0x80c3 {
		t.Errorf("last kanji: heisig %d, unicode %#x", last.heisig, last.unicode)
	}
}

func TestDataKanjiCreateFromFileErrors(t *testing.T) {
	tests := []struct {
		dir  string
		want string
	}{
		{"fail-not-increasing", "Heisig frame 1 is not greater than previous frame 2"},
		{"fail-frame-mismatch", "Heisig frame 20000 does not match Unicode 19968 on line 1"},
		{"fail-bad-reading", "Claimed reading [zzz] for [1] [19968] is wrong"},
		{"fail-wrong-field-count", "DataKanji: Processing failed with above errors"},
	}
	for _, tt := range tests {
		var err error
		stderr := capture_stderr(t, func() {
			_, err = DataKanji_create_from_file(filepath.Join("testdata", "cases", tt.dir, "kanji.data"))
		})
		if err == nil || err.Error() != tt.want {
			t.Errorf("%s: err = %v, want %q", tt.dir, err, tt.want)
		}
		if tt.dir == "fail-wrong-field-count" {
			if want := "FATAL wrong number of fields (saw 4 expected 8-9 for line #1"; !strings.Contains(stderr, want) {
				t.Errorf("%s: stderr %q does not contain %q", tt.dir, stderr, want)
			}
		}
	}
}
