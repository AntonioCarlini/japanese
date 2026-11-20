package rubycompat_test

import (
	"errors"
	"regexp"
	"testing"

	"japanese/internal/rubycompat"
)

// equal_strings compares two slices, treating nil and empty as the same.
func equal_strings(a, b []string) bool {
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

func TestStrip(t *testing.T) {
	tests := []struct{ in, want string }{
		{"", ""},
		{"abc", "abc"},
		{"  abc  ", "abc"},
		{"\t\n abc \r\n", "abc"},
		{"a b", "a b"},
		{"abc\x00", "abc"},
	}
	for _, tt := range tests {
		if got := rubycompat.Strip(tt.in); got != tt.want {
			t.Errorf("Strip(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestChomp(t *testing.T) {
	tests := []struct{ in, want string }{
		{"", ""},
		{"a", "a"},
		{"a\n", "a"},
		{"a\r\n", "a"},
		{"a\r", "a"},
		{"a\n\n", "a\n"}, // only one line ending is removed
		{"a \n", "a "},
	}
	for _, tt := range tests {
		if got := rubycompat.Chomp(tt.in); got != tt.want {
			t.Errorf("Chomp(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestSplitString(t *testing.T) {
	tests := []struct {
		in, sep string
		want    []string
	}{
		{"", ":", nil},
		{"abc", ":", []string{"abc"}},
		{"a:b", ":", []string{"a", "b"}},
		{"a:b::", ":", []string{"a", "b"}}, // trailing empty fields are dropped
		{"a::b", ":", []string{"a", "", "b"}},
		{":a", ":", []string{"", "a"}}, // a leading empty field is kept
		{":::", ":", nil},
	}
	for _, tt := range tests {
		if got := rubycompat.SplitString(tt.in, tt.sep); !equal_strings(got, tt.want) {
			t.Errorf("SplitString(%q, %q) = %q, want %q", tt.in, tt.sep, got, tt.want)
		}
	}
}

func TestSplitWhitespace(t *testing.T) {
	tests := []struct {
		in   string
		want []string
	}{
		{"", nil},
		{"   ", nil},
		{"a", []string{"a"}},
		{"  a  b\tc\n", []string{"a", "b", "c"}},
	}
	for _, tt := range tests {
		if got := rubycompat.SplitWhitespace(tt.in); !equal_strings(got, tt.want) {
			t.Errorf("SplitWhitespace(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestSplitRegexp(t *testing.T) {
	re := regexp.MustCompile(`-+`)
	tests := []struct {
		in   string
		want []string
	}{
		{"", nil},
		{"abc", []string{"abc"}},
		{"a-b", []string{"a", "b"}},
		{"a--b-", []string{"a", "b"}}, // trailing empty field dropped
		{"--a", []string{"", "a"}},    // leading empty field kept
		{"-", nil},
	}
	for _, tt := range tests {
		if got := rubycompat.SplitRegexp(re, tt.in); !equal_strings(got, tt.want) {
			t.Errorf("SplitRegexp(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestToI(t *testing.T) {
	tests := []struct {
		in   string
		base int
		want int
	}{
		{"", 10, 0},
		{"42", 10, 42},
		{"  42abc", 10, 42},
		{"abc", 10, 0},
		{"-7", 10, -7},
		{"+5", 10, 5},
		{"5-", 10, 5},
		{"1_000", 10, 1000},
		{"1__0", 10, 1}, // a doubled underscore ends the number
		{"0x10", 10, 0}, // base 10 stops at the x
		{"ff", 16, 255},
		{"12", 16, 18},
		{"0x4e00", 16, 19968},
		{"0X1F", 16, 31},
		{"0x", 16, 0},
		{"-0x10", 16, -16},
		{" 0x4e00 ", 16, 19968}, // as in the kanji.data fields
		{"    1 ", 10, 1},
	}
	for _, tt := range tests {
		if got := rubycompat.ToI(tt.in, tt.base); got != tt.want {
			t.Errorf("ToI(%q, %d) = %d, want %d", tt.in, tt.base, got, tt.want)
		}
	}
}

func TestGsubFunc(t *testing.T) {
	re := regexp.MustCompile(`(\d)(x)`)

	got, err := rubycompat.GsubFunc(re, "1x2x3", func(m []string) (string, error) {
		return "[" + m[1] + m[2] + "|" + m[0] + "]", nil
	})
	if err != nil || got != "[1x|1x][2x|2x]3" {
		t.Errorf("got %q, %v", got, err)
	}

	// No match: the text is returned unchanged and fn is not called.
	got, err = rubycompat.GsubFunc(re, "abc", func(m []string) (string, error) {
		t.Error("fn should not be called")
		return "", nil
	})
	if err != nil || got != "abc" {
		t.Errorf("got %q, %v", got, err)
	}

	// The replacement is used literally ($1 and backslashes mean nothing).
	got, err = rubycompat.GsubFunc(regexp.MustCompile(`a`), "-a-", func(m []string) (string, error) {
		return `$1\0`, nil
	})
	if err != nil || got != `-$1\0-` {
		t.Errorf("got %q, %v", got, err)
	}

	// A group that did not take part in the match is an empty string.
	got, err = rubycompat.GsubFunc(regexp.MustCompile(`(a)|(b)`), "b", func(m []string) (string, error) {
		return "<" + m[1] + "|" + m[2] + ">", nil
	})
	if err != nil || got != "<|b>" {
		t.Errorf("got %q, %v", got, err)
	}

	// An error from fn stops the substitution and is returned.
	want_err := errors.New("boom")
	_, err = rubycompat.GsubFunc(re, "1x", func(m []string) (string, error) {
		return "", want_err
	})
	if !errors.Is(err, want_err) {
		t.Errorf("err = %v, want %v", err, want_err)
	}
}
