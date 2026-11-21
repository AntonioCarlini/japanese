package main

// Unit tests for the conversion functions and a few helpers. These use no
// package-level state that other tests could disturb, apart from the radical
// table, which is built once on first use.

import (
	"bytes"
	"errors"
	"io"
	"os"
	"strings"
	"testing"
)

// refs builds the expected output for a list of code points.
func refs(codes ...int) string {
	var s strings.Builder
	for _, c := range codes {
		s.WriteString(jp_unicode(c))
	}
	return s.String()
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

func TestJpUnicode(t *testing.T) {
	tests := []struct {
		in   int
		want string
	}{
		{0x304b, "&#x304b;"},
		{0x3005, "&#x3005;"},
         	{0x3299, "&#x3299;"},
		{3299, "&#xce3;"}, // decimal 3299, as in the Ruby's :maruhi
		{0, "&#x0;"},
	}
	for _, tt := range tests {
		if got := jp_unicode(tt.in); got != tt.want {
			t.Errorf("jp_unicode(%d) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestConvertToHiragana(t *testing.T) {
	tests := []struct {
		in   string
		want string
	}{
		{"", ""},
		{"a", refs(0x3042)},
		{"ka", refs(0x304b)},
		{"KA", refs(0x304b)}, // case does not matter
		{"kana", refs(0x304b, 0x306a)},
		{"shi", refs(0x3057)},
		{"chi", refs(0x3061)},
		{"tsu", refs(0x3064)},
		{"sha", refs(0x3057, 0x3083)},
		{"kyou", refs(0x304d, 0x3087, 0x3046)},
		{"nya", refs(0x306b, 0x3083)},
		{"ja", refs(0x3058, 0x3083)},
		{"jya", refs(0x3058, 0x3083)},
		{"kippu", refs(0x304d, 0x3063, 0x3077)}, // doubled consonant: small tsu
		{"xtsu", refs(0x3063)},
		{"nn", refs(0x3093)},
		{"n", refs(0x3093)}, // a final n
		{"kan", refs(0x304b, 0x3093)},
		{"tenki", refs(0x3066, 0x3093, 0x304d)}, // n before a consonant
		{"kanji", refs(0x304b, 0x3093, 0x3058)},
		{"a1", refs(0x3042) + "1"}, // digits pass through
		{"ka.", refs(0x304b, 0x3002)},
		{"[ka]", refs(0x300c, 0x304b, 0x300d)},
		{"ka ka", refs(0x304b) + " " + refs(0x304b)},
	}
	for _, tt := range tests {
		got, err := convert_to_hiragana(tt.in)
		if err != nil {
			t.Errorf("convert_to_hiragana(%q): unexpected error %v", tt.in, err)
		} else if got != tt.want {
			t.Errorf("convert_to_hiragana(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestConvertToHiraganaErrors(t *testing.T) {
	tests := []struct {
		in       string
		fragment string
	}{
		{"k", "Stray trailing hiragana"},
		{"N", "Stray trailing hiragana"}, // only a lowercase final n is accepted
		{"bcdef", "HIRAGANA: BROKEN at 5"},
		{"shya", "no code point defined for [shi]"}, // crashes the Ruby too
	}
	for _, tt := range tests {
		_, err := convert_to_hiragana(tt.in)
		if err == nil {
			t.Errorf("convert_to_hiragana(%q): expected an error", tt.in)
		} else if !strings.Contains(err.Error(), tt.fragment) {
			t.Errorf("convert_to_hiragana(%q): error %q does not contain %q", tt.in, err, tt.fragment)
		}
	}
}

func TestConvertToKatakana(t *testing.T) {
	tests := []struct {
		in   string
		want string
	}{
		{"", ""},
		{"ka", refs(0x30ab)},
		{"kohi-", refs(0x30b3, 0x30d2, 0x30fc)}, // "-" is the long vowel mark
		{"sha", refs(0x30b7, 0x30e3)},
		{"shatsu", refs(0x30b7, 0x30e3, 0x30c4)},
		{"fi", refs(0x30d5, 0x30a3)},
		{"je", refs(0x30b8, 0x30a7)},
		{"ja", refs(0x30b8, 0x30e3)},
		{"jusu", refs(0x30b8, 0x30e5, 0x30b9)},
		{"kka", refs(0x30c3, 0x30ab)},
		{"kaN", refs(0x30ab, 0x30f3)}, // a final N in either case
		{"chokore-to", refs(0x30c1, 0x30e7, 0x30b3, 0x30ec, 0x30fc, 0x30c8)},
		{"fiirudo", refs(0x30d5, 0x30a3, 0x30a4, 0x30eb, 0x30c9)},
	}
	for _, tt := range tests {
		got, err := convert_to_katakana(tt.in)
		if err != nil {
			t.Errorf("convert_to_katakana(%q): unexpected error %v", tt.in, err)
		} else if got != tt.want {
			t.Errorf("convert_to_katakana(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestConvertToKatakanaErrors(t *testing.T) {
	tests := []struct {
		in       string
		fragment string
	}{
		{"k", "Stray trailing katakana"},
		{"bcdef", "KATAKANA: BROKEN at 5"},
	}
	for _, tt := range tests {
		_, err := convert_to_katakana(tt.in)
		if err == nil {
			t.Errorf("convert_to_katakana(%q): expected an error", tt.in)
		} else if !strings.Contains(err.Error(), tt.fragment) {
			t.Errorf("convert_to_katakana(%q): error %q does not contain %q", tt.in, err, tt.fragment)
		}
	}
}

// These words come from the table in convert_to_kanji itself, so the expected
// values do not depend on kanji.data.
func TestConvertToKanji(t *testing.T) {
	tests := []struct {
		in   string
		want string
	}{
		{"", ""},
		{"hon", refs(0x672c)},
		{"HON", refs(0x672c)},
		{"hon ichi", refs(0x672c) + " " + refs(0x4e00)},
		{"ichi^dan", refs(0x4e00, 0x6bb5)}, // "^" separates words and is then removed
		{"maruhi", "&#x3299;"},
	}
	for _, tt := range tests {
		got, err := convert_to_kanji(tt.in, false)
		if err != nil {
			t.Errorf("convert_to_kanji(%q): unexpected error %v", tt.in, err)
		} else if got != tt.want {
			t.Errorf("convert_to_kanji(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestConvertToKanjiUnknownWord(t *testing.T) {
	// Not strict: the word is marked in the output and reported on stderr.
	var got string
	var err error
	stderr := capture_stderr(t, func() {
		got, err = convert_to_kanji("zzzunknown", false)
	})
	if err != nil {
		t.Errorf("unexpected error %v", err)
	}
	if want := "&lt;UNKNOWN KANJI [zzzunknown]&gt;"; got != want {
		t.Errorf("got %q, want %q", got, want)
	}
	want_stderr := "FastKanji: UNKNOWN kanji for [zzzunknown]\n" +
		"UNKNOWN kanji [zzzunknown] specified as [zzzunknown]\n"
	if stderr != want_stderr {
		t.Errorf("stderr = %q, want %q", stderr, want_stderr)
	}

	// Strict: a ProcessingError.
	stderr = capture_stderr(t, func() {
		_, err = convert_to_kanji("zzzunknown", true)
	})
	var processing_error *ProcessingError
	if !errors.As(err, &processing_error) {
		t.Fatalf("err = %v, want a *ProcessingError", err)
	}
	if want := "UNKNOWN kanji [zzzunknown] specified as [zzzunknown]"; processing_error.message != want {
		t.Errorf("message = %q, want %q", processing_error.message, want)
	}
	if want := "FastKanji: UNKNOWN kanji for [zzzunknown]\n"; stderr != want {
		t.Errorf("stderr = %q, want %q (the strict error is reported by the caller)", stderr, want)
	}
}

func TestConvertToRadicalUnknownWord(t *testing.T) {
	var got string
	capture_stderr(t, func() { // building the radical table may report missing kanji
		got = convert_to_radical("no*such*radical")
	})
	if want := "&lt;UNKNOWN RADICAL [no*such*radical]&gt;"; got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestDisplayText(t *testing.T) {
	long30 := strings.Repeat("x", 30)
	long31 := strings.Repeat("x", 31)
	long40 := strings.Repeat("x", 40)
	tests := []struct {
		in   string
		want string
	}{
		{"", ""},
		{"abc", "abc"},
		{"a\nb", "a_b"},
		{long30, long30},                          // 30 characters: nothing added
		{long31, long31 + "..."},                  // more than 30: "..." added
		{long40, strings.Repeat("x", 31) + "..."}, // only the first 31 characters are shown
	}
	for _, tt := range tests {
		if got := display_text(tt.in); got != tt.want {
			t.Errorf("display_text(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}
